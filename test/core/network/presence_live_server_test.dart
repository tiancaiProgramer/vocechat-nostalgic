import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocechat_client/core/network/sse_client.dart';
import 'package:vocechat_client/core/storage/account_store.dart';
import 'package:vocechat_client/features/contacts/application/presence_provider.dart';
import 'package:vocechat_client/features/messages/application/message_dispatcher.dart';
import 'package:vocechat_client/features/messages/domain/message_models.dart';

const fixturePath = String.fromEnvironment('LOCAL_PRESENCE_FIXTURE');

class _Accounts extends AccountStore {
  @override
  Future<AccountState> build() async =>
      const AccountState(currentAccountId: 'isolated::1');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => HttpOverrides.global = null);
  for (final httpFallback in [false, true]) {
    test(
        'real server ${httpFallback ? 'HTTP fallback' : 'WebSocket'} snapshot, online and offline reach app presence',
        () async {
      final fixture = jsonDecode(File(fixturePath).readAsStringSync());
      final origin = fixture['origin'] as String;
      final a = fixture['a'];
      final b = fixture['b'];
      final peerUid = b['user']['uid'] as int;
      HttpServer? proxy;
      final proxyHttp = HttpClient();
      if (httpFallback) {
        proxy = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
        proxy.listen((request) async {
          if (request.uri.path.endsWith('events_ws')) {
            request.response.statusCode = 404;
            await request.response.close();
          } else {
            final upstream =
                await proxyHttp.getUrl(Uri.parse('$origin${request.uri}'));
            request.headers.forEach((key, values) {
              if (!const {'host', 'connection'}.contains(key))
                upstream.headers.set(key, values);
            });
            final response = await upstream.close();
            request.response.bufferOutput = false;
            request.response.headers.contentType =
                ContentType('text', 'event-stream');
            await response.pipe(request.response);
          }
        });
      }
      final client = VoceSseClient(
        baseUrl: proxy == null ? origin : 'http://127.0.0.1:${proxy.port}',
        apiKey: a['token'],
        preferInlineParsing: () => true,
      );
      final c = ProviderContainer(overrides: [
        accountStoreProvider.overrideWith(_Accounts.new),
        sseEventsProvider.overrideWith((ref) => client.events().where((e) =>
            e is ChatEventUnknown &&
            const {'users_state', 'users_state_changed'}.contains(e.type))),
      ]);
      final peerHttp = HttpClient();
      StreamSubscription<List<int>>? peerSub;
      addTearDown(() async {
        c.dispose();
        await peerSub?.cancel();
        peerHttp.close(force: true);
        proxyHttp.close(force: true);
        await proxy?.close(force: true);
      });
      c.listen(accountStoreProvider, (_, __) {}, fireImmediately: true);
      await c.read(accountStoreProvider.future);
      c.read(messageDispatcherProvider);
      Future<void> until(bool value) async {
        final done = Completer<void>();
        final s = c.listen(presenceProvider, (_, next) {
          if (next[peerUid] == value && !done.isCompleted) done.complete();
        }, fireImmediately: true);
        try {
          await done.future.timeout(const Duration(seconds: 15));
        } finally {
          s.close();
        }
      }

      await until(false);
      final request = await peerHttp.getUrl(Uri.parse(
          '$origin/api/user/events?api-key=${Uri.encodeComponent(b['token'])}'));
      request.headers.set('Referer', '$origin/');
      final response = await request.close();
      expect(response.statusCode, 200);
      peerSub = response.listen((_) {});
      await until(true);
      await peerSub.cancel();
      peerSub = null;
      peerHttp.close(force: true);
      await until(false);
    }, skip: fixturePath.isEmpty);
  }
}
