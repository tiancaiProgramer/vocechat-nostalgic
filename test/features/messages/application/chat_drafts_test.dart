import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vocechat_client/features/messages/application/chat_drafts_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
      'drafts persist across containers and are isolated by account/server/target',
      () async {
    final first = ProviderContainer();
    final writer = first.read(chatDraftsProvider('server::7').notifier);
    await writer.setDraft('u-8', '未发送\nDraft', [8, 8]);
    await writer.setDraft('g-42', 'group draft', []);
    await writer.flush();
    first.dispose();
    final second = ProviderContainer();
    addTearDown(second.dispose);
    final saved = await second.read(chatDraftsProvider('server::7').future);
    expect(saved['u-8']!.text, '未发送\nDraft');
    expect(saved['u-8']!.mentions, [8]);
    expect(saved['g-42']!.text, 'group draft');
    expect(await second.read(chatDraftsProvider('server::8').future), isEmpty);
    expect(await second.read(chatDraftsProvider('another::7').future), isEmpty);
  });

  test('rapid edits and a clear cannot be overwritten by earlier disk writes',
      () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final drafts = container.read(chatDraftsProvider('server::7').notifier);
    await Future.wait([
      drafts.setDraft('u-8', 'a', []),
      drafts.setDraft('u-8', 'ab', []),
      drafts.setDraft('u-8', '', []),
      drafts.setDraft('g-42', 'other', []),
    ]);
    await drafts.flush();
    final another = ProviderContainer();
    addTearDown(another.dispose);
    final restored = await another.read(chatDraftsProvider('server::7').future);
    expect(restored.containsKey('u-8'), isFalse);
    expect(restored['g-42']!.text, 'other');
  });

  test(
      'invalid stored drafts remain intact rather than being overwritten on disposal',
      () async {
    final key = 'voce_drafts_${sha256.convert(utf8.encode('server::7'))}';
    SharedPreferences.setMockInitialValues({key: 'broken'});
    final container = ProviderContainer();
    await expectLater(container.read(chatDraftsProvider('server::7').future),
        throwsFormatException);
    await expectLater(
        container
            .read(chatDraftsProvider('server::7').notifier)
            .setDraft('u-8', 'replacement', []),
        throwsFormatException);
    container.dispose();
    expect((await SharedPreferences.getInstance()).getString(key), 'broken');
  });
}
