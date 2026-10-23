import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocechat_client/core/storage/account_store.dart';
import 'package:vocechat_client/core/storage/server_store.dart';
import 'package:vocechat_client/core/storage/secure_token_store.dart';
import 'package:vocechat_client/features/messages/application/custom_stickers_provider.dart';
import 'package:vocechat_client/features/messages/data/custom_sticker_store.dart';
import 'package:vocechat_client/features/messages/data/sticker_sync.dart';

class Accounts extends AccountStore {
  @override
  Future<AccountState> build() async =>
      const AccountState(currentAccountId: 'server::7', accounts: [
        AccountConfig(
            accountId: 'server::7', serverId: 'server', uid: 7, name: 'Test')
      ]);
}

class Servers extends ServerStore {
  Servers(this.url);
  final String url;
  @override
  Future<ServerState> build() async => ServerState(
      currentServerId: 'server',
      servers: [ServerConfig(id: 'server', name: 'Test', baseUrl: url)]);
}

class Tokens extends SecureTokenStore {
  Tokens() : super(id: 'server::7');
  @override
  Future<TokenData?> readTokens() async => TokenData(
      accessToken: 'local-test-token',
      refreshToken: 'local-test-refresh',
      expiresAt: DateTime.now().add(const Duration(hours: 1)));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
      'imports during an in-flight upload automatically sync in the next batch',
      () async {
    final oldOverrides = HttpOverrides.current;
    HttpOverrides.global = null;
    final root =
        await Directory.systemTemp.createTemp('stickers-provider-sync-');
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final firstPut = Completer<void>();
    final release = Completer<void>();
    final remote = <String, CustomSticker>{};
    final failures = <Object>[];
    server.listen((request) async {
      try {
        expect(request.headers.value('x-api-key'), 'local-test-token');
        request.response.headers.contentType = ContentType.json;
        if (request.method == 'PUT') {
          if (!firstPut.isCompleted) {
            firstPut.complete();
            await release.future;
          }
          final bytes = await request.fold<BytesBuilder>(
              BytesBuilder(), (b, c) => b..add(c));
          final item = await inspectSticker(bytes.takeBytes());
          remote[item.id] = item;
          request.response.write('{}');
        } else {
          expect(request.uri.path, '/stickers/v1/stickers');
          request.response.write(jsonEncode({
            'service': 'vocechat-stickers',
            'version': 1,
            'uid': 7,
            'items': remote.values.map((e) => e.toJson()).toList()
          }));
        }
        await request.response.close();
      } catch (e) {
        failures.add(e);
        request.response.statusCode = 500;
        await request.response.close();
      }
    });
    final container = ProviderContainer(overrides: [
      accountStoreProvider.overrideWith(Accounts.new),
      serverStoreProvider
          .overrideWith(() => Servers('http://127.0.0.1:${server.port}')),
      secureTokenStoreProvider('server::7').overrideWith((ref) => Tokens()),
      stickerDocumentsProvider.overrideWith((ref) async => root),
    ]);
    final accountSub = container.listen(accountStoreProvider, (_, __) {});
    final serverSub = container.listen(serverStoreProvider, (_, __) {});
    addTearDown(() async {
      if (!release.isCompleted) release.complete();
      container.dispose();
      accountSub.close();
      serverSub.close();
      await server.close(force: true);
      await root.delete(recursive: true);
      HttpOverrides.global = oldOverrides;
    });
    await container.read(accountStoreProvider.future);
    await container.read(serverStoreProvider.future);
    await container.read(customStickersProvider('server::7').future);
    final controller =
        container.read(customStickersProvider('server::7').notifier);
    final a = File('test/fixtures/stickers/red.png').readAsBytesSync();
    final b = File('test/fixtures/stickers/animated.gif').readAsBytesSync();
    await controller.add(a);
    final running = controller.sync();
    await firstPut.future.timeout(const Duration(seconds: 3));
    await controller.add(b);
    // Let the import's debounce fire while the first HTTP upload is held.
    await Future<void>.delayed(const Duration(milliseconds: 650));
    release.complete();
    await running;
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (DateTime.now().isBefore(deadline) &&
        (remote.length != 2 ||
            container.read(stickerSyncStatusProvider('server::7')) !=
                StickerSyncStatus.synced)) {
      await Future<void>.delayed(const Duration(milliseconds: 30));
    }
    expect(failures, isEmpty);
    expect(remote, hasLength(2));
    expect(container.read(stickerSyncStatusProvider('server::7')),
        StickerSyncStatus.synced);
    final store =
        await container.read(customStickerStoreProvider('server::7').future);
    expect(await store.pending(), isEmpty);
    expect(await store.list(), hasLength(2));
  });
}
