import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocechat_client/core/network/sse_client.dart';
import 'package:vocechat_client/features/messages/domain/message_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('a fast online delta cannot overtake a slow offline snapshot', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final connected = Completer<WebSocket>();
    server.listen((request) async {
      final ws = await WebSocketTransformer.upgrade(request);
      ws.listen((_) {});
      connected.complete(ws);
    });
    final snapshotStarted = Completer<void>();
    final releaseSnapshot = Completer<void>();
    final received = <ChatEventUnknown>[];
    final done = Completer<void>();
    final client = VoceSseClient(
      baseUrl: 'http://127.0.0.1:${server.port}',
      apiKey: 'test-key',
      parseFrame: (type, raw) async {
        if (type == 'users_state') {
          snapshotStarted.complete();
          await releaseSnapshot.future;
        }
        return parseSseEvent(type, raw);
      },
    );
    final sub = client.events().listen((event) {
      received.add(event as ChatEventUnknown);
      if (received.length == 2) done.complete();
    });
    final ws = await connected.future.timeout(const Duration(seconds: 3));
    addTearDown(() async {
      await sub.cancel();
      await ws.close();
      await server.close(force: true);
    });
    ws.add(jsonEncode({
      'type': 'users_state',
      'users': [
        {'uid': 42, 'online': false}
      ]
    }));
    ws.add(
        jsonEncode({'type': 'users_state_changed', 'uid': 42, 'online': true}));
    await snapshotStarted.future.timeout(const Duration(seconds: 3));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(received, isEmpty);
    releaseSnapshot.complete();
    await done.future.timeout(const Duration(seconds: 3));
    expect(received.map((e) => e.type), ['users_state', 'users_state_changed']);
    final state = <int, bool>{};
    for (final event in received) {
      final data = jsonDecode(event.raw) as Map<String, dynamic>;
      if (event.type == 'users_state') {
        for (final user in data['users']) {
          state[user['uid'] as int] = user['online'] as bool;
        }
      } else {
        state[data['uid'] as int] = data['online'] as bool;
      }
    }
    expect(state[42], true);
  });
}
