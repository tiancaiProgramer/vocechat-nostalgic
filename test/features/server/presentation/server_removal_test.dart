import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocechat_client/core/storage/account_store.dart';
import 'package:vocechat_client/core/storage/server_store.dart';
import 'package:vocechat_client/features/server/data/server_connection.dart';

import 'server_picker_connection_test.dart' show mount, savedServer;

const otherServer = ServerConfig(
    id: 'other', name: 'Other server', baseUrl: 'https://other.test');
const savedAccount = AccountConfig(
    accountId: 'saved::7', serverId: 'saved', uid: 7, name: 'Saved account');
const otherAccount = AccountConfig(
    accountId: 'other::8', serverId: 'other', uid: 8, name: 'Other account');

class _Offline extends ServerConnection {
  String? lastUrl;
  @override
  Future<Map<String, dynamic>> probe(String url,
      {CancelToken? cancelToken}) async {
    lastUrl = url;
    throw const ServerConnectionException(ServerConnectionFailure.network);
  }
}

class _Pending extends ServerConnection {
  final pending = Completer<Map<String, dynamic>>();
  @override
  Future<Map<String, dynamic>> probe(String url, {CancelToken? cancelToken}) =>
      pending.future;
}

class _CannotRemove extends ServerStore {
  @override
  Future<ServerState> build() async =>
      const ServerState(servers: [savedServer], currentServerId: 'saved');
  @override
  Future<void> removeServer(String id) async =>
      throw StateError('storage failed');
}

Future<void> seedAccounts(ProviderContainer container) async {
  final accounts = container.read(accountStoreProvider.notifier);
  await accounts.future;
  await accounts.upsertAccount(savedAccount);
  await accounts.upsertAccount(otherAccount);
  await accounts.selectAccount(savedAccount.accountId);
}

Future<void> askToRemove(WidgetTester tester, String id) async {
  await tester.tap(find.byKey(ValueKey('remove-server-$id')));
  await tester.pumpAndSettle();
  expect(find.byType(AlertDialog), findsOneWidget);
}

Future<void> confirm(WidgetTester tester) async {
  await tester.tap(find.descendant(
      of: find.byType(AlertDialog), matching: find.text('Remove')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('cancel leaves server selection and saved account untouched',
      (tester) async {
    final offline = _Offline();
    final container = await mount(tester, offline, saved: true);
    await seedAccounts(container);
    await askToRemove(tester, 'saved');
    expect(find.textContaining('https://chat.test'), findsWidgets);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect((await container.read(serverStoreProvider.future)).servers,
        [savedServer]);
    expect((await container.read(accountStoreProvider.future)).currentAccountId,
        savedAccount.accountId);
    expect(offline.lastUrl, isNull);
  });

  testWidgets(
      'removing last/current server persists empty list and keeps saved accounts',
      (tester) async {
    final offline = _Offline();
    final container = await mount(tester, offline, saved: true);
    await seedAccounts(container);
    await askToRemove(tester, 'saved');
    await confirm(tester);
    expect(find.text('Add your first server'), findsOneWidget);
    expect(find.text('Continue'), findsNothing);
    final servers = await container.read(serverStoreProvider.future);
    expect(servers.servers, isEmpty);
    expect(servers.currentServerId, isNull);
    final accounts = await container.read(accountStoreProvider.future);
    expect(accounts.currentAccountId, isNull);
    expect(accounts.accounts, [savedAccount, otherAccount]);
    // The native preferences backing a fresh scope also contain the removal.
    await tester.runAsync(() async {
      final fresh = ProviderContainer();
      try {
        expect((await fresh.read(serverStoreProvider.future)).servers, isEmpty);
        expect((await fresh.read(accountStoreProvider.future)).accounts,
            [savedAccount, otherAccount]);
      } finally {
        fresh.dispose();
      }
    });
    expect(offline.lastUrl, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('removing another server preserves current server and account',
      (tester) async {
    final offline = _Offline();
    final container = await mount(tester, offline, saved: true);
    await container.read(serverStoreProvider.notifier).addServer(otherServer);
    await seedAccounts(container);
    await tester.pumpAndSettle();
    await askToRemove(tester, 'other');
    await confirm(tester);
    final servers = await container.read(serverStoreProvider.future);
    expect(servers.servers, [savedServer]);
    expect(servers.currentServerId, 'saved');
    expect((await container.read(accountStoreProvider.future)).currentAccountId,
        savedAccount.accountId);
    expect(offline.lastUrl, isNull);
  });

  testWidgets('removing the highlighted row clears stale local selection',
      (tester) async {
    final offline = _Offline();
    final container = await mount(tester, offline, saved: true);
    await container.read(serverStoreProvider.notifier).addServer(otherServer);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Other server'));
    await askToRemove(tester, 'other');
    await confirm(tester);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(offline.lastUrl, savedServer.baseUrl);
    expect(tester.takeException(), isNull);
  });

  testWidgets('failed removal restores active account and enables retry',
      (tester) async {
    final offline = _Offline();
    final container = await mount(tester, offline,
        saved: true, serverFactory: _CannotRemove.new);
    await seedAccounts(container);
    await askToRemove(tester, 'saved');
    await confirm(tester);
    expect(find.text('Could not remove the server. Please retry.'),
        findsOneWidget);
    expect((await container.read(serverStoreProvider.future)).servers,
        [savedServer]);
    expect((await container.read(accountStoreProvider.future)).currentAccountId,
        savedAccount.accountId);
    expect(
        tester
            .widget<IconButton>(
                find.byKey(const ValueKey('remove-server-saved')))
            .onPressed,
        isNotNull);
    expect(offline.lastUrl, isNull);
  });

  testWidgets('cannot remove a server while its connection check is running',
      (tester) async {
    final connection = _Pending();
    await mount(tester, connection, saved: true);
    await tester.tap(find.text('Continue'));
    await tester.pump();
    expect(
        tester
            .widget<IconButton>(
                find.byKey(const ValueKey('remove-server-saved')))
            .onPressed,
        isNull);
    connection.pending.completeError(
        const ServerConnectionException(ServerConnectionFailure.network));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<IconButton>(
                find.byKey(const ValueKey('remove-server-saved')))
            .onPressed,
        isNotNull);
  });
}
