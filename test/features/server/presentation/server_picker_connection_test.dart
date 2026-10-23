import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vocechat_client/core/storage/account_store.dart';
import 'package:vocechat_client/core/storage/server_store.dart';
import 'package:vocechat_client/features/auth/application/auth_controller.dart';
import 'package:vocechat_client/features/server/data/server_connection.dart';
import 'package:vocechat_client/features/server/presentation/server_picker_screen.dart';
import 'package:vocechat_client/l10n/generated/app_localizations.dart';
import 'package:vocechat_client/shared/widgets/primary_button.dart';

import '../data/server_connection_test.dart' show ProbeAdapter, jsonReply;

const savedServer = ServerConfig(
    id: 'saved', baseUrl: 'https://chat.test', name: 'Saved server');
const timeoutText =
    'Connection timed out. Check the server address and network, then retry.';

class _Auth extends AuthController {
  @override
  Future<AuthState> build() async => const AuthState.unauthenticated();
}

class _HungAuth extends AuthController {
  @override
  Future<AuthState> build() => Completer<AuthState>().future;
}

class _FailingStore extends ServerStore {
  @override
  Future<ServerState> build() async =>
      const ServerState(servers: [savedServer], currentServerId: 'saved');
  @override
  Future<void> selectServer(String id) async =>
      throw StateError('storage failed');
}

class _KeepAuth extends ConsumerWidget {
  const _KeepAuth(this.child);
  final Widget child;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(authControllerProvider);
    return child;
  }
}

Future<ProviderContainer> mount(
    WidgetTester tester, ServerConnection connection,
    {bool saved = false,
    bool hungAuth = false,
    bool failStore = false,
    bool openAdd = false,
    ServerStore Function()? serverFactory}) async {
  SharedPreferences.setMockInitialValues({
    'voce_servers': saved ? [jsonEncode(savedServer.toJson())] : <String>[],
    if (saved) 'voce_current_server': 'saved',
    'voce_current_account': 'keep-existing-account',
  });
  tester.view.physicalSize = const Size(430, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final router = GoRouter(routes: [
    GoRoute(
        path: '/', builder: (_, __) => ServerPickerScreen(openAdd: openAdd)),
    GoRoute(
        path: '/login',
        builder: (_, __) => const Scaffold(body: Text('Sign-in page'))),
    GoRoute(
        path: '/register',
        builder: (_, __) => const Scaffold(body: Text('Registration page'))),
  ]);
  addTearDown(router.dispose);
  final container = ProviderContainer(overrides: [
    serverConnectionProvider.overrideWithValue(connection),
    authControllerProvider.overrideWith(hungAuth ? _HungAuth.new : _Auth.new),
    if (serverFactory != null)
      serverStoreProvider.overrideWith(serverFactory)
    else if (failStore)
      serverStoreProvider.overrideWith(_FailingStore.new),
  ]);
  addTearDown(container.dispose);
  await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: _KeepAuth(MaterialApp.router(
        routerConfig: router,
        locale: const Locale('en'),
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
      ))));
  await tester.pumpAndSettle();
  return container;
}

ServerConnection withReplies(
        Future<ResponseBody> Function(RequestOptions) respond,
        List<ProbeAdapter> adapters) =>
    ServerConnection(
      createDio: (options) {
        final adapter = ProbeAdapter(respond);
        adapters.add(adapter);
        return Dio(options)..httpClientAdapter = adapter;
      },
    );

Future<void> openAdd(WidgetTester tester, {bool saved = false}) async {
  await tester.tap(find.text(saved ? 'Add server' : 'Add your first server'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextFormField), 'https://chat.test');
  tester.testTextInput.hide();
  await tester.pumpAndSettle();
}

Future<void> advanceTimeout(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 11));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
      'add entry opens server form directly and cancel preserves selection',
      (tester) async {
    final connection = withReplies(
        (_) async => jsonReply({'name': 'Server'}), <ProbeAdapter>[]);
    final c = await mount(tester, connection, saved: true, openAdd: true);
    c.listen(accountStoreProvider, (_, __) {}, fireImmediately: true);
    await c.read(accountStoreProvider.future);
    expect(find.byType(TextFormField), findsOneWidget);
    expect(c.read(accountStoreProvider).valueOrNull?.currentAccountId,
        'keep-existing-account');
    Navigator.of(tester.element(find.byType(TextFormField))).pop();
    await tester.pumpAndSettle();
    expect(c.read(accountStoreProvider).valueOrNull?.currentAccountId,
        'keep-existing-account');
    expect(c.read(serverStoreProvider).requireValue.currentServerId, 'saved');
  });

  testWidgets(
      'test timeout is visible inside sheet; retry succeeds and restores buttons',
      (tester) async {
    final adapters = <ProbeAdapter>[];
    var attempts = 0;
    final pending = Completer<ResponseBody>();
    final connection = withReplies(
        (_) => ++attempts == 1
            ? pending.future
            : Future.value(jsonReply({'name': 'Demo'})),
        adapters);
    await mount(tester, connection);
    await openAdd(tester);
    await tester.tap(find.text('Test connection'));
    await tester.pump();
    expect(
        tester.widget<PrimaryButton>(find.byType(PrimaryButton).last).onPressed,
        isNull);
    await advanceTimeout(tester);
    expect(find.text(timeoutText), findsOneWidget);
    expect(adapters.first.closed, isTrue);
    expect(
        tester.widget<PrimaryButton>(find.byType(PrimaryButton).last).onPressed,
        isNotNull);
    await tester.tap(find.text('Test connection'));
    await tester.pumpAndSettle();
    expect(find.text('Connection successful'), findsOneWidget);
    expect(find.text(timeoutText), findsNothing);
    await tester.enterText(find.byType(TextFormField), 'https://other.test');
    await tester.pump();
    expect(find.text('Connection successful'), findsNothing);
    pending.complete(jsonReply({'name': 'Late'}));
    await tester.pump();
    expect(find.text('Connection successful'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'failed save never persists/selects server or clears current account; retry navigates after closing sheet',
      (tester) async {
    final adapters = <ProbeAdapter>[];
    final pending = Completer<ResponseBody>();
    var calls = 0;
    final connection = withReplies(
        (_) => ++calls == 1
            ? pending.future
            : Future.value(jsonReply({'name': 'Demo'})),
        adapters);
    final container = await mount(tester, connection);
    await openAdd(tester);
    await tester.tap(find.text('Save & Continue'));
    await tester.pump();
    await advanceTimeout(tester);
    expect(find.text(timeoutText), findsOneWidget);
    expect((await container.read(serverStoreProvider.future)).servers, isEmpty);
    expect(
        (await SharedPreferences.getInstance())
            .getString('voce_current_account'),
        'keep-existing-account');
    pending.complete(jsonReply({'name': 'Late'}));
    await tester.pumpAndSettle();
    expect((await container.read(serverStoreProvider.future)).servers, isEmpty);
    await tester.tap(find.text('Save & Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Sign-in page'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
    expect((await container.read(serverStoreProvider.future)).servers,
        hasLength(1));
    expect(calls, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Continue reports HTTP failure, resets spinner, and can retry saved server',
      (tester) async {
    final adapters = <ProbeAdapter>[];
    var attempts = 0;
    await mount(
        tester,
        withReplies(
            (_) async => ++attempts == 1
                ? jsonReply({}, status: 503)
                : jsonReply({'name': 'Demo'}),
            adapters),
        saved: true);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Server returned HTTP 503. Check the server address.'),
        findsOneWidget);
    expect(tester.widget<PrimaryButton>(find.byType(PrimaryButton)).isLoading,
        isFalse);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Sign-in page'), findsOneWidget);
    expect(attempts, 2);
  });

  testWidgets('Continue failure remains visible without overflow in landscape',
      (tester) async {
    final adapters = <ProbeAdapter>[];
    await mount(
        tester, withReplies((_) async => jsonReply({}, status: 503), adapters),
        saved: true);
    tester.view.physicalSize = const Size(900, 360);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Server returned HTTP 503. Check the server address.'),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('storage failure restores Continue and reports failure inline',
      (tester) async {
    final adapters = <ProbeAdapter>[];
    await mount(
        tester, withReplies((_) async => jsonReply({'name': 'Demo'}), adapters),
        saved: true, failStore: true);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Could not save server settings. Please retry.'),
        findsOneWidget);
    expect(tester.widget<PrimaryButton>(find.byType(PrimaryButton)).isLoading,
        isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a hung auth bootstrap has a deadline and restores Continue',
      (tester) async {
    final adapters = <ProbeAdapter>[];
    await mount(
        tester, withReplies((_) async => jsonReply({'name': 'Demo'}), adapters),
        saved: true, hungAuth: true);
    await tester.tap(find.text('Continue'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await advanceTimeout(tester);
    expect(find.text('Preparing sign-in timed out. Please retry.'),
        findsOneWidget);
    expect(tester.widget<PrimaryButton>(find.byType(PrimaryButton)).isLoading,
        isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'closing test sheet cancels transport and leaves no late feedback',
      (tester) async {
    final adapters = <ProbeAdapter>[];
    await mount(
        tester, withReplies((_) => Completer<ResponseBody>().future, adapters));
    await openAdd(tester);
    await tester.tap(find.text('Test connection'));
    await tester.pump();
    Navigator.of(tester.element(find.byType(TextFormField))).pop();
    await tester.pumpAndSettle();
    expect(adapters.single.closed, isTrue);
    await tester.pump(const Duration(seconds: 11));
    expect(find.text(timeoutText), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('incomplete URL fails validation before making any request',
      (tester) async {
    final adapters = <ProbeAdapter>[];
    await mount(tester,
        withReplies((_) async => jsonReply({'name': 'Demo'}), adapters));
    await openAdd(tester);
    await tester.enterText(find.byType(TextFormField), 'https://');
    await tester.tap(find.text('Save & Continue'));
    await tester.pumpAndSettle();
    expect(
        find.text(
            'Enter a complete server address, such as https://chat.example.com.'),
        findsOneWidget);
    expect(adapters, isEmpty);
  });
}
