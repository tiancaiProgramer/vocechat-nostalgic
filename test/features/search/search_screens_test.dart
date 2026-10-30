import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vocechat_client/core/storage/account_store.dart';
import 'package:vocechat_client/core/storage/server_store.dart';
import 'package:vocechat_client/features/auth/application/auth_controller.dart';
import 'package:vocechat_client/features/auth/domain/auth_models.dart';
import 'package:vocechat_client/features/channels/application/conversation_providers.dart';
import 'package:vocechat_client/features/contacts/application/contacts_provider.dart';
import 'package:vocechat_client/features/contacts/application/user_directory_provider.dart';
import 'package:vocechat_client/features/messages/domain/message_models.dart';
import 'package:vocechat_client/features/search/data/contact_search_api.dart';
import 'package:vocechat_client/features/search/data/message_search_session.dart';
import 'package:vocechat_client/features/search/presentation/contact_search_screen.dart';
import 'package:vocechat_client/features/search/presentation/message_search_screen.dart';
import 'package:vocechat_client/features/search/data/message_search_filter.dart';
import 'package:vocechat_client/legacy_ui/legacy_chrome.dart';
import 'package:vocechat_client/l10n/generated/app_localizations.dart';

class _Accounts extends AccountStore {
  @override
  Future<AccountState> build() async =>
      const AccountState(currentAccountId: 'server::1');
  void switchAccount() =>
      state = const AsyncData(AccountState(currentAccountId: 'server::2'));
}

class _Servers extends ServerStore {
  @override
  Future<ServerState> build() async => const ServerState();
}

class _Users extends UserDirectory {
  @override
  Future<Map<int, UserSummary>> build() async =>
      const {8: UserSummary(uid: 8, name: 'Alice')};
}

class _Auth extends AuthController {
  @override
  Future<AuthState> build() async =>
      const AuthState.authenticated(user: VoceUser(uid: 1, name: 'Me'));
}

class _Conversations extends Conversations {
  @override
  Future<List<ConversationItem>> build() async => const [
        ConversationItem(
            key: UserConversationKey(8),
            name: 'Alice',
            isChannel: false,
            lastAt: 1)
      ];
}

class _People extends ContactSearchApi {
  _People(this.find) : super(Dio());
  final Future<ContactInfo?> Function(String, CancelToken) find;
  @override
  Future<ContactInfo?> search(String query, CancelToken cancelToken) =>
      find(query, cancelToken);
}

Future<({GoRouter router, ProviderContainer container})> _mount(
    WidgetTester tester,
    {ContactSearchApi? people}) async {
  final router = GoRouter(initialLocation: '/home', routes: [
    GoRoute(
      path: '/home',
      builder: (_, __) => const Scaffold(body: LegacyServerHeader()),
      routes: [
        GoRoute(
            path: 'people', builder: (_, __) => const ContactSearchScreen()),
        GoRoute(
            path: 'search', builder: (_, __) => const MessageSearchScreen()),
        GoRoute(
            path: 'chat/:id',
            builder: (_, s) => Scaffold(
                body: Text(
                    'message ${s.pathParameters['id']} ${s.uri.queryParameters['mid']}'))),
      ],
    )
  ]);
  addTearDown(router.dispose);
  final container = ProviderContainer(overrides: [
    accountStoreProvider.overrideWith(_Accounts.new),
    serverStoreProvider.overrideWith(_Servers.new),
    userDirectoryProvider.overrideWith(_Users.new),
    authControllerProvider.overrideWith(_Auth.new),
    conversationsProvider.overrideWith(_Conversations.new),
    contactsProvider.overrideWith(_Contacts.new),
    contactSearchApiProvider
        .overrideWithValue(people ?? _People((q, t) async => null)),
    messageSearchFactoryProvider.overrideWithValue(
        (query, conversations, token) => MessageSearchSession(
              query: query,
              conversations: conversations,
              cancelToken: token,
              readCache: (_) async => [],
              loadHistory:
                  (target, {beforeMid, required limit, cancelToken}) async => [
                ChatMessage(
                    mid: 42,
                    fromUid: 8,
                    createdAt: 1000,
                    target: target,
                    detail: const MessageDetail.normal(
                        contentType: 'text/plain',
                        content: 'needle in message body'))
              ],
            )),
  ]);
  addTearDown(container.dispose);
  await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
          routerConfig: router,
          locale: const Locale('en'),
          localizationsDelegates: AppL10n.localizationsDelegates,
          supportedLocales: AppL10n.supportedLocales)));
  await tester.pumpAndSettle();
  return (router: router, container: container);
}

Future<void> _choose(WidgetTester tester, String item) async {
  await tester.tap(find.byType(PopupMenuButton<String>));
  await tester.pumpAndSettle();
  await tester.tap(find.text(item));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
      'contacts menu opens a separate usable page and finds name/email/ID',
      (tester) async {
    final app = await _mount(tester);
    await _choose(tester, 'Contacts');
    expect(find.byType(ContactSearchScreen), findsOneWidget);
    expect(find.text('Find people'), findsOneWidget);
    for (final query in [' alice ', 'EXAMPLE.test', '#8']) {
      await tester.enterText(find.byType(CupertinoSearchTextField), query);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(find.text('Alice'), findsOneWidget);
    }
    app.router.pop();
    await tester.pumpAndSettle();
    expect(find.byType(CupertinoSearchTextField), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'global search finds message body rather than chat title and opens exact message',
      (tester) async {
    final app = await _mount(tester);
    await _choose(tester, 'Search');
    expect(find.byType(MessageSearchScreen), findsOneWidget);
    expect(find.text('Search chat history'), findsOneWidget);
    await tester.enterText(find.byType(CupertinoSearchTextField), 'needle');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text('needle in message body'), findsOneWidget);
    await tester.tap(find.text('needle in message body'));
    await tester.pumpAndSettle();
    expect(find.text('message u-8 42'), findsOneWidget);
    app.router.pop();
    await tester.pumpAndSettle();
    expect(find.text('needle in message body'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'filter sheet can browse media without a keyword and reset to text search',
      (tester) async {
    await _mount(tester);
    await _choose(tester, 'Search');
    await tester.tap(find.byKey(const ValueKey('search-filters')));
    await tester.pumpAndSettle();
    expect(find.text('Conversation'), findsOneWidget);
    expect(find.text('Sender'), findsOneWidget);
    expect(find.text('Date range · Any date'), findsOneWidget);
    await tester.tap(find.byType(DropdownButtonFormField<SearchMessageKind>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Images').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text('Images'), findsOneWidget);
    expect(find.text('needle in message body'), findsNothing);
    expect(find.byTooltip('Reset filters'), findsOneWidget);
    await tester.tap(find.byTooltip('Reset filters'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Reset filters'), findsNothing);
    await tester.enterText(find.byType(CupertinoSearchTextField), 'needle');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text('needle in message body'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('clearing the query ignores a late server user lookup',
      (tester) async {
    final response = Completer<ContactInfo?>();
    await _mount(tester, people: _People((q, t) => response.future));
    await _choose(tester, 'Contacts');
    await tester.enterText(find.byType(CupertinoSearchTextField), 'late');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.enterText(find.byType(CupertinoSearchTextField), '');
    response.complete(const ContactInfo(uid: 9, name: 'Late result'));
    await tester.pumpAndSettle();
    expect(find.text('Late result'), findsNothing);
  });

  testWidgets('account switch dismisses search and cancels old lookups',
      (tester) async {
    CancelToken? token;
    final pending = Completer<ContactInfo?>();
    final app = await _mount(tester, people: _People((q, t) {
      token = t;
      return pending.future;
    }));
    await _choose(tester, 'Contacts');
    await tester.enterText(find.byType(CupertinoSearchTextField), 'private');
    await tester.pump(const Duration(milliseconds: 400));
    (app.container.read(accountStoreProvider.notifier) as _Accounts)
        .switchAccount();
    await tester.pumpAndSettle();
    expect(token!.isCancelled, isTrue);
    expect(app.router.routeInformationProvider.value.uri.path, '/home');
    pending.complete(const ContactInfo(uid: 9, name: 'Old account result'));
    await tester.pumpAndSettle();
    expect(find.text('Old account result'), findsNothing);
  });
}

class _Contacts extends Contacts {
  @override
  Future<List<ContactInfo>> build() async => const [
        ContactInfo(uid: 8, name: 'Alice', email: 'alice@example.test'),
      ];
}
