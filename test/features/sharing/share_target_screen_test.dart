import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vocechat_client/core/storage/account_store.dart';
import 'package:vocechat_client/features/channels/application/conversation_providers.dart';
import 'package:vocechat_client/features/sharing/application/incoming_share_provider.dart';
import 'package:vocechat_client/features/sharing/presentation/share_target_screen.dart';
import 'package:vocechat_client/l10n/generated/app_localizations.dart';

class _Accounts extends AccountStore {
  @override
  Future<AccountState> build() async =>
      const AccountState(currentAccountId: 'server::1');
  void change() =>
      state = const AsyncData(AccountState(currentAccountId: 'server::2'));
}

class _Conversations extends Conversations {
  @override
  Future<List<ConversationItem>> build() async => const [
        ConversationItem(
          key: UserConversationKey(8),
          name: 'Alice',
          isChannel: false,
          lastAt: 1,
        ),
      ];
}

Map<String, dynamic> packet({
  int size = 80 * 1024 * 1024,
  bool prepared = false,
}) =>
    {
      'id': 'share-test',
      'text': '',
      'prepared': prepared,
      'files': [
        {
          'name': 'large.bin',
          'size': size,
          'path': prepared ? '/cache/large.bin' : '',
        },
      ],
    };
void main() {
  const channel = MethodChannel('vocechat/incoming_share');
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });
  Future<({GoRouter router, ProviderContainer container})> mount(
    WidgetTester tester,
    Future<Object?> Function(MethodCall) handler,
  ) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, handler);
    final container = ProviderContainer(
      overrides: [
        accountStoreProvider.overrideWith(_Accounts.new),
        conversationsProvider.overrideWith(_Conversations.new),
      ],
    );
    await container.read(accountStoreProvider.future);
    container.read(incomingSharesProvider);
    await container.read(incomingSharesProvider.notifier).refresh();
    final router = GoRouter(
      initialLocation: '/home/share',
      routes: [
        GoRoute(
          path: '/home',
          builder: (_, __) => const Scaffold(body: Text('Home')),
          routes: [
            GoRoute(
              path: 'share',
              builder: (_, __) => const ShareTargetScreen(),
            ),
            GoRoute(
              path: 'chat/:id',
              builder: (_, __) => const Scaffold(body: Text('Chat draft')),
            ),
          ],
        ),
        GoRoute(
          path: '/file-transfer',
          builder: (_, state) {
            final share = state.extra as IncomingTransferSelection;
            return Scaffold(
              body: Text(
                'Transfer ${share.payload.files.single.size} ${share.payload.files.single.path}',
              ),
            );
          },
        ),
      ],
    );
    addTearDown(router.dispose);
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
          locale: const Locale('zh'),
          localizationsDelegates: AppL10n.localizationsDelegates,
          supportedLocales: AppL10n.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();
    return (router: router, container: container);
  }

  testWidgets(
    'large external file chooses transfer without chat import or early cleanup',
    (tester) async {
      final calls = <MethodCall>[];
      final app = await mount(tester, (call) async {
        calls.add(call);
        if (call.method == 'pending') return [packet()];
        if (call.method == 'prepare') return packet(prepared: true);
        return null;
      });
      expect(find.text('文件传输'), findsOneWidget);
      expect(
        tester.widget<ListTile>(find.widgetWithText(ListTile, 'Alice')).enabled,
        isTrue,
      );
      await tester.tap(find.text('文件传输'));
      await tester.pumpAndSettle();
      expect(find.text('Transfer 83886080 /cache/large.bin'), findsOneWidget);
      expect(calls.where((c) => c.method == 'prepare').single.arguments, {
        'id': 'share-test',
        'mode': 'transfer',
      });
      expect(calls.where((c) => c.method == 'ack'), isEmpty);
      expect(app.container.read(pendingIncomingShareProvider), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );
  testWidgets(
    '80 MB external file can also be selected for a chat draft',
    (tester) async {
      final calls = <MethodCall>[];
      final app = await mount(tester, (call) async {
        calls.add(call);
        if (call.method == 'pending') return [packet()];
        if (call.method == 'prepare') return packet(prepared: true);
        return null;
      });
      await tester.tap(find.text('Alice'));
      await tester.pumpAndSettle();
      expect(find.text('Chat draft'), findsOneWidget);
      expect(calls.where((c) => c.method == 'prepare').single.arguments, {
        'id': 'share-test',
        'mode': 'chat',
      });
      expect(
        app.container.read(selectedIncomingShareProvider)!.payload.prepared,
        isTrue,
      );
      expect(calls.where((c) => c.method == 'ack'), isEmpty);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );
  testWidgets(
    'cancel during preparation cannot navigate when the late import finishes',
    (tester) async {
      final result = Completer<Object?>();
      final calls = <MethodCall>[];
      final app = await mount(tester, (call) async {
        calls.add(call);
        if (call.method == 'pending') return [packet()];
        if (call.method == 'prepare') return result.future;
        return null;
      });
      await tester.tap(find.text('文件传输'));
      await tester.pump();
      await tester.tap(find.byTooltip('取消'));
      await tester.pumpAndSettle();
      result.complete(packet(prepared: true));
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsOneWidget);
      expect(calls.where((c) => c.method == 'ack'), isNotEmpty);
      expect(app.container.read(selectedIncomingShareProvider), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );
  testWidgets(
    'account change during import never forwards the old selection',
    (tester) async {
      final result = Completer<Object?>();
      final calls = <MethodCall>[];
      final app = await mount(tester, (call) async {
        calls.add(call);
        if (call.method == 'pending') return [packet()];
        if (call.method == 'prepare') return result.future;
        return null;
      });
      await tester.tap(find.text('文件传输'));
      await tester.pump();
      (app.container.read(accountStoreProvider.notifier) as _Accounts).change();
      result.complete(packet(prepared: true));
      await tester.pumpAndSettle();
      expect(find.textContaining('Transfer 83886080'), findsNothing);
      expect(calls.where((c) => c.method == 'ack'), isNotEmpty);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );
}
