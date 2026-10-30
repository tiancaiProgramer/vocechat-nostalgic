import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vocechat_client/core/network/sse_client.dart';
import 'package:vocechat_client/core/storage/account_store.dart';
import 'package:vocechat_client/core/storage/server_store.dart';
import 'package:vocechat_client/core/theme/app_text_scale.dart';
import 'package:vocechat_client/core/theme/app_theme.dart';
import 'package:vocechat_client/core/theme/font_size_provider.dart';
import 'package:vocechat_client/features/contacts/application/user_directory_provider.dart';
import 'package:vocechat_client/features/messages/application/chat_layout_provider.dart';
import 'package:vocechat_client/features/messages/domain/message_models.dart';
import 'package:vocechat_client/features/messages/presentation/chat_screen.dart';
import 'package:vocechat_client/features/messages/presentation/mention_text.dart';
import 'package:vocechat_client/l10n/generated/app_localizations.dart';

class _Accounts extends AccountStore {
  @override
  Future<AccountState> build() async => const AccountState();
}
class _Servers extends ServerStore {
  @override
  Future<ServerState> build() async => const ServerState();
}
class _Font extends FontSizeNotifier {
  @override
  int build() => fontSizeScales.length - 1;
}
class _Layout extends ChatLayout {
  @override
  ChatLayoutMode build() => ChatLayoutMode.selfRight;
}

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('names remain distinct and long messages fit at 130% in $brightness', (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      AppTheme.applyBrightness(brightness);
      addTearDown(() => AppTheme.applyBrightness(Brightness.light));
      await tester.runAsync(() async {
        final loader = FontLoader('Inter')..addFont(rootBundle.load('assets/fonts/Inter-Variable.ttf'));
        await loader.load();
      });
      final container = ProviderContainer(overrides: [
        accountStoreProvider.overrideWith(_Accounts.new),
        serverStoreProvider.overrideWith(_Servers.new),
        fontSizeProvider.overrideWith(_Font.new),
        chatLayoutProvider.overrideWith(_Layout.new),
        sseEventsProvider.overrideWith((ref) => const Stream<ChatEvent>.empty()),
      ]);
      addTearDown(container.dispose);
      final capture = GlobalKey();
      await tester.pumpWidget(UncontrolledProviderScope(container: container, child: MaterialApp(
        theme: brightness == Brightness.dark ? AppTheme.darkTheme : AppTheme.lightTheme,
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        locale: const Locale('en'),
        builder: (_, child) => AppTextScale(child: child!),
        home: RepaintBoundary(key: capture, child: Scaffold(body: SafeArea(child: Column(children: [
          const Padding(padding: EdgeInsets.all(16), child: Text('Chat preview · 130%')),
          for (final uid in [8,7]) MessageRow(
            message: ChatMessage(mid: uid, fromUid: uid, createdAt: 1000, target: const MessageTarget.group(gid: 42), detail: MessageDetail.normal(contentType: 'text/plain', content: uid == 8 ? 'A longer message wraps clearly at the largest text size.' : 'Names and messages have different colors.')),
            currentUid: 7,
            userDir: const {7: UserSummary(uid: 7,name: 'You'),8:UserSummary(uid:8,name:'Alex')},
            avatarUrlBuilder: (_,__) => null,
            target: const MessageTarget.group(gid:42),
          ),
        ])))),
      )));
      await tester.pump();
      final name = tester.widget<Text>(find.text('Alex'));
      final body = tester.widget<MentionText>(find.byType(MentionText).first);
      expect(name.style!.color, isNot(body.style.color));
      expect(name.style!.color!.computeLuminance(), isNot(body.style.color!.computeLuminance()));
      expect(tester.takeException(), isNull);
      final destination = Platform.environment['VOCECHAT_PREVIEW_DIR'];
      if (destination != null) {
        await tester.runAsync(() async {
          final boundary = capture.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final image = await boundary.toImage(pixelRatio: 2);
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          await Directory(destination).create(recursive: true);
          await File('$destination/chat-${brightness.name}.png').writeAsBytes(data!.buffer.asUint8List());
          image.dispose();
        });
      }
    });
  }
}
