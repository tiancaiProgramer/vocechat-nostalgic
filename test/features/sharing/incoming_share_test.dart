import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocechat_client/core/storage/account_store.dart';
import 'package:vocechat_client/features/sharing/application/incoming_share_provider.dart';

class Accounts extends AccountStore {
  @override
  Future<AccountState> build() async =>
      const AccountState(currentAccountId: 'server::7');
  void switchAccount() =>
      state = const AsyncData(AccountState(currentAccountId: 'server::8'));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('vocechat/incoming_share');
  test('share payload accepts text and mixed files while enforcing bounds', () {
    final share = IncomingShare.fromMap({
      'id': 'test-share',
      'text': 'https://example.test',
      'files': [
        {
          'path': '/cache/photo.gif',
          'name': 'photo.gif',
          'mime': 'image/gif',
          'size': 100
        },
        {
          'path': '/cache/video.mp4',
          'name': 'video.mp4',
          'mime': 'video/mp4',
          'size': 200
        },
      ]
    });
    expect(share.hasContent, isTrue);
    expect(share.files, hasLength(2));
    expect(
        () =>
            IncomingShare.fromMap({'id': '../escape', 'text': '', 'files': []}),
        throwsFormatException);
    expect(
        () => IncomingShare.fromMap({
              'id': 'test',
              'text': '',
              'files': [
                {
                  'path': '/cache/large',
                  'name': 'large',
                  'size': 33 * 1024 * 1024
                }
              ]
            }),
        throwsFormatException);
  });

  test(
      'refresh, hold and acknowledge do not redisplay an already selected share',
      () async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      if (call.method == 'pending') {
        return [
          {'id': 'test-share', 'text': 'text', 'files': []}
        ];
      }
      return null;
    });
    addTearDown(() => TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null));
    final container = ProviderContainer(
        overrides: [accountStoreProvider.overrideWith(Accounts.new)]);
    addTearDown(container.dispose);
    final inbox = container.read(incomingSharesProvider.notifier);
    await inbox.refresh();
    expect(container.read(pendingIncomingShareProvider)!.text, 'text');
    inbox.hold('test-share');
    await inbox.refresh();
    expect(container.read(pendingIncomingShareProvider), isNull);
    await inbox.ack('test-share');
    expect(calls.where((c) => c.method == 'ack').single.arguments,
        {'id': 'test-share'});
  });

  test(
      'switching accounts cancels a selected share instead of applying it to the new account',
      () async {
    final acked = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'ack') {
        acked.add((call.arguments as Map)['id'] as String);
      }
      return call.method == 'pending' ? [] : null;
    });
    addTearDown(() => TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null));
    final container = ProviderContainer(
        overrides: [accountStoreProvider.overrideWith(Accounts.new)]);
    addTearDown(container.dispose);
    container.read(incomingSharesProvider);
    await container.read(accountStoreProvider.future);
    container.read(selectedIncomingShareProvider.notifier).state =
        const IncomingShareSelection('server::7', 'u-8',
            IncomingShare(id: 'old', text: 'private draft', files: []));
    (container.read(accountStoreProvider.notifier) as Accounts).switchAccount();
    await Future<void>.delayed(Duration.zero);
    expect(container.read(selectedIncomingShareProvider), isNull);
    expect(acked, ['old']);
  });
}
