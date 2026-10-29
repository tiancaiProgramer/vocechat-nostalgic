import 'package:vocechat_client/features/server/presentation/server_picker_screen.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vocechat_client/core/storage/server_store.dart';
import 'package:vocechat_client/core/storage/account_store.dart';
import 'package:vocechat_client/features/contacts/application/presence_provider.dart';
import 'package:vocechat_client/core/storage/secure_token_store.dart';
import 'package:vocechat_client/core/theme/app_theme.dart';
import 'package:vocechat_client/features/auth/application/auth_controller.dart';
import 'package:vocechat_client/features/auth/domain/auth_models.dart';
import 'package:vocechat_client/features/auth/presentation/login_screen.dart';
import 'package:vocechat_client/features/channels/application/conversation_providers.dart';
import 'package:vocechat_client/features/channels/presentation/chat_list_screen.dart';
import 'package:vocechat_client/features/contacts/application/user_directory_provider.dart';
import 'package:vocechat_client/features/messages/application/chat_controller.dart';
import 'package:vocechat_client/features/messages/application/read_index_provider.dart';
import 'package:vocechat_client/features/messages/domain/message_models.dart';
import 'package:vocechat_client/features/messages/presentation/chat_screen.dart';
import 'package:vocechat_client/features/settings/presentation/settings_screen.dart';
import 'package:vocechat_client/l10n/generated/app_localizations.dart';
import 'package:vocechat_client/legacy_ui/legacy_chrome.dart';

const group = MessageTarget.group(gid: 42);

class _Servers extends ServerStore {
  @override
  Future<ServerState> build() async =>
      const ServerState(currentServerId: 'preview', servers: [
        ServerConfig(
            id: 'preview', baseUrl: 'https://demo.example', name: 'KGN')
      ]);
}

class _Accounts extends AccountStore {
  @override
  Future<AccountState> build() async =>
      const AccountState(currentAccountId: 'preview::7', accounts: [
        AccountConfig(
            accountId: 'preview::7',
            serverId: 'preview',
            uid: 7,
            name: 'Alice'),
      ]);
}

class _Auth extends AuthController {
  @override
  Future<AuthState> build() async => const AuthState.authenticated(
      user: VoceUser(uid: 7, name: 'Alice', email: 'alice@example.test'));
}

class _Unauth extends AuthController {
  @override
  Future<AuthState> build() async => const AuthState.unauthenticated();
}

class _Users extends UserDirectory {
  @override
  Future<Map<int, UserSummary>> build() async => const {
        7: UserSummary(uid: 7, name: 'Alice'),
        8: UserSummary(uid: 8, name: 'Bob')
      };
}

class _Groups extends GroupDirectory {
  @override
  Future<Map<int, GroupSummary>> build() async => const {
        42: GroupSummary(
            gid: 42, name: 'Community', description: 'Welcome to our community')
      };
}

class _Conversations extends Conversations {
  @override
  Future<List<ConversationItem>> build() async => const [
        ConversationItem(
            key: GroupConversationKey(42),
            name: 'Community',
            isChannel: true,
            lastMid: 30,
            lastAt: 1000,
            lastPreview: 'Bob: Hello everyone'),
        ConversationItem(
            key: UserConversationKey(8),
            name: 'Bob',
            isChannel: false,
            lastMid: 20,
            lastAt: 1000,
            lastPreview: 'See you tomorrow'),
      ];
}

class _Read extends ReadIndex {
  @override
  Future<ReadIndexState> build() async => const ReadIndexState();
  @override
  void setGroup(int gid, int mid) {}
}

class _Chat extends ChatController {
  @override
  Future<List<ChatMessage>> build(MessageTarget target) async => [
        ChatMessage(
            mid: 30,
            fromUid: 8,
            createdAt: 1000,
            target: target,
            detail: const MessageDetail.normal(
                contentType: 'text/plain', content: 'Hello everyone 👋')),
        ChatMessage(
            mid: 20,
            fromUid: 7,
            createdAt: 500,
            target: target,
            detail: const MessageDetail.normal(
                contentType: 'text/plain', content: 'Welcome to VoceChat')),
      ];
  @override
  Future<void> loadMore() async {}
}

class _Tokens extends SecureTokenStore {
  _Tokens() : super(id: 'preview');
  @override
  Future<RememberedCredential?> readRememberedCredential() async => null;
}

void main() {
  late Directory temp;
  setUpAll(() async {
    temp = await Directory.systemTemp.createTemp('legacy-screen-preview-');
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (_) async => temp.path);
    final sdkFonts = Directory(
        '../toolchain/flutter-3.35.7/flutter/bin/cache/artifacts/material_fonts');
    for (final pair in {
      'MaterialIcons': 'MaterialIcons-Regular.otf',
      'Roboto': 'Roboto-Regular.ttf'
    }.entries) {
      final file = File('${sdkFonts.path}/${pair.value}');
      if (file.existsSync())
        await (FontLoader(pair.key)
              ..addFont(
                  Future.value(ByteData.sublistView(file.readAsBytesSync()))))
            .load();
    }
    for (final font in {
      'Inter': 'assets/fonts/Inter-Variable.ttf',
      // Flutter widget tests replace default fonts with Ahem. Use a real
      // font for those inherited button styles in review screenshots.
      'Ahem': 'assets/fonts/Inter-Variable.ttf',
      'AppIcons': 'assets/legacy/AppIcons.ttf'
    }.entries) {
      await (FontLoader(font.key)..addFont(rootBundle.load(font.value))).load();
    }
  });
  for (final width in [360.0, 800.0]) {
    for (final screen in [
      'chats',
      'chat',
      'dm',
      'settings',
      'drawer',
      'login',
      'servers'
    ]) {
      testWidgets(
          'legacy $screen at ${width.toInt()} keeps phone layout and fits',
          (tester) async {
        SharedPreferences.setMockInitialValues({});
        tester.view.physicalSize = Size(width, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final boundary = GlobalKey();
        Widget child = switch (screen) {
          'chats' => Scaffold(
              drawer: const LegacyServerDrawer(),
              body: const ChatListScreen(),
              bottomNavigationBar:
                  LegacyBottomBar(currentIndex: 0, onTap: (_) {})),
          'drawer' => const Scaffold(
              drawer: LegacyServerDrawer(), body: SizedBox.expand()),
          'chat' => const Scaffold(body: ChatScreen(id: 'g-42')),
          'dm' => const Scaffold(body: ChatScreen(id: 'u-8')),
          'settings' => const Scaffold(body: SettingsScreen()),
          'servers' => const ServerPickerScreen(),
          _ => const LoginScreen(),
        };
        final router =
            GoRouter(routes: [GoRoute(path: '/', builder: (_, __) => child)]);
        addTearDown(router.dispose);
        await tester.pumpWidget(ProviderScope(
            overrides: [
              serverStoreProvider.overrideWith(_Servers.new),
              accountStoreProvider.overrideWith(_Accounts.new),
              authControllerProvider
                  .overrideWith(screen == 'login' ? _Unauth.new : _Auth.new),
              userDirectoryProvider.overrideWith(_Users.new),
              groupDirectoryProvider.overrideWith(_Groups.new),
              conversationsProvider.overrideWith(_Conversations.new),
              readIndexProvider.overrideWith(_Read.new),
              chatControllerProvider(group).overrideWith(_Chat.new),
              chatControllerProvider(const MessageTarget.user(uid: 8))
                  .overrideWith(_Chat.new),
              secureTokenStoreProvider('preview')
                  .overrideWith((_) => _Tokens()),
            ],
            child: RepaintBoundary(
                key: boundary,
                child: MaterialApp.router(
                    debugShowCheckedModeBanner: false,
                    routerConfig: router,
                    theme: AppTheme.lightTheme,
                    locale: const Locale('en'),
                    localizationsDelegates: AppL10n.localizationsDelegates,
                    supportedLocales: AppL10n.supportedLocales))));
        await tester.pumpAndSettle();
        if (screen == 'drawer') {
          tester.state<ScaffoldState>(find.byType(Scaffold).first).openDrawer();
          await tester.pumpAndSettle();
          expect(find.byKey(const ValueKey('drawer-accounts-card')),
              findsOneWidget);
          expect(find.byKey(const ValueKey('drawer-servers-card')),
              findsOneWidget);
          expect(find.text('Add account'), findsNothing);
          expect(find.text('Select Server'), findsNothing);
          expect(find.byKey(const ValueKey('drawer-close')), findsNothing);
          expect(find.byKey(const ValueKey('drawer-add')), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
        if (screen == 'login') expect(find.byType(LoginScreen), findsOneWidget);
        if (screen == 'chats') {
          expect(find.byType(CupertinoTabBar), findsOneWidget);
          expect(find.text('KGN'), findsOneWidget);
          expect(find.text('demo.example'), findsNothing);
        }
        if (screen == 'chat') {
          expect(find.byTooltip('Emoji'), findsOneWidget);
          expect(find.byTooltip('More'), findsWidgets);
        }
        if (screen == 'settings') {
          expect(find.byType(LegacyTitleBar), findsOneWidget);
          for (final group in ['profile', 'options', 'session']) {
            expect(
                find.byKey(ValueKey('settings-$group-group')), findsOneWidget);
          }
          expect(find.text('Select Server'), findsNothing);
          expect(find.text('Storage & Data'), findsNothing);
          final rows = find.descendant(
              of: find.byKey(const ValueKey('settings-options-group')),
              matching: find.byType(ListTile));
          expect(rows, findsNWidgets(4));
          final sizes = rows
              .evaluate()
              .map((e) => tester.getSize(find.byWidget(e.widget)).height)
              .toSet();
          expect(sizes, {56.0});
        }
        if (const bool.fromEnvironment('CAPTURE_LEGACY')) {
          final render = boundary.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
          await tester.runAsync(() async {
            final image = await render.toImage(pixelRatio: 2);
            final bytes =
                await image.toByteData(format: ui.ImageByteFormat.png);
            final dir = Directory('../legacy-previews')
              ..createSync(recursive: true);
            File('${dir.path}/$screen-${width.toInt()}.png')
                .writeAsBytesSync(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
        if (screen == 'dm') {
          expect(find.text('Syncing status…'), findsOneWidget);
          final scope = ProviderScope.containerOf(
              tester.element(find.byType(ChatScreen)));
          scope.read(presenceProvider.notifier).applyChange(8, true);
          await tester.pump();
          expect(find.text('Online'), findsOneWidget);
          scope.read(presenceProvider.notifier).applyChange(8, false);
          await tester.pump();
          expect(find.text('Offline'), findsOneWidget);
        }
        if (screen == 'settings') {
          await tester.tap(find.byKey(const ValueKey('settings-profile')));
          await tester.pumpAndSettle();
          expect(find.text('My Account'), findsOneWidget);
          expect(find.text('Storage & Data'), findsOneWidget);
          await tester.tap(find.text('My Account'));
          await tester.pumpAndSettle();
          expect(find.text('Delete account'), findsOneWidget);
        }
        if (screen == 'drawer') {
          await tester.tap(find.byKey(const ValueKey('drawer-add')));
          await tester.pumpAndSettle();
          expect(find.text('Add account'), findsOneWidget);
          expect(find.text('Add server'), findsOneWidget);
          expect(find.text('File transfer'), findsOneWidget);
          await tester.tap(find.text('Add account'));
          await tester.pumpAndSettle();
          expect(find.byType(TextFormField), findsNWidgets(3));
          expect(tester.takeException(), isNull);
        }
      });
    }
  }
}
