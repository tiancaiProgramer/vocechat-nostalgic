import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocechat_client/core/network/sse_client.dart';
import 'package:vocechat_client/features/messages/domain/message_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => HttpOverrides.global = null);
  test(
      'licensed WebSocket gets Referer and Origin, including trailing slash base',
      () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    WebSocket? socket;
    server.listen((r) async {
      expect(r.uri.path, '/api/user/events_ws');
      expect(r.headers.value('referer'), 'http://127.0.0.1:${server.port}/');
      expect(r.headers.value('origin'), 'http://127.0.0.1:${server.port}');
      expect(r.headers.value('x-api-key'), 'fake-key');
      socket = await WebSocketTransformer.upgrade(r);
      socket!.listen((_) {});
      socket!.add('{"type":"users_state","users":[{"uid":42,"online":true}]}');
    });
    final c = VoceSseClient(
        baseUrl: 'http://127.0.0.1:${server.port}/',
        apiKey: 'fake-key',
        preferInlineParsing: () => true);
    final event = await c.events().first.timeout(const Duration(seconds: 5));
    expect((event as ChatEventUnknown).type, 'users_state');
    await socket?.close();
    await server.close(force: true);
  });

  for (final code in [404, 400, 405, 426]) {
    test(
        'WebSocket HTTP $code falls back to SSE and delivers ordered state changes',
        () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final paths = <String>[];
      server.listen((r) async {
        paths.add(r.uri.path);
        if (r.uri.path.endsWith('events_ws')) {
          r.response.statusCode = code;
          await r.response.close();
        } else {
          expect(
              r.headers.value('referer'), 'http://127.0.0.1:${server.port}/');
          expect(r.headers.value('accept'), 'text/event-stream');
          expect(r.headers.value('accept-encoding'), 'identity');
          expect(r.uri.queryParameters['after_mid'], '99');
          r.response.bufferOutput = false;
          r.response.headers.contentType = ContentType('text', 'event-stream');
          r.response.write(
              'event: users_state\ndata: {"users":[{"uid":42,"online":false}]}\n\n');
          await r.response.flush();
          r.response.write(
              'event: users_state_changed\ndata: {"uid":42,"online":true}\n\n');
          await r.response.flush();
        }
      });
      final c = VoceSseClient(
          baseUrl: 'http://127.0.0.1:${server.port}',
          apiKey: 'fake-key',
          initialAfterMid: 99,
          preferInlineParsing: () => true);
      final got =
          await c.events().take(2).toList().timeout(const Duration(seconds: 5));
      expect(paths, ['/api/user/events_ws', '/api/user/events']);
      expect(got.cast<ChatEventUnknown>().map((e) => e.type),
          ['users_state', 'users_state_changed']);
      expect(jsonDecode((got.last as ChatEventUnknown).raw)['online'], true);
      await server.close(force: true);
    });
  }

  test('disposing a silent session completes its stream and closes the socket',
      () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final connected = Completer<void>();
    final disconnected = Completer<void>();
    server.listen((request) async {
      final socket = await WebSocketTransformer.upgrade(request);
      socket.listen((_) {}, onDone: () => disconnected.complete());
      connected.complete();
    });
    addTearDown(() => server.close(force: true));
    final client = VoceSseClient(
        baseUrl: 'http://127.0.0.1:${server.port}', apiKey: 'fake-key');
    final finished = Completer<void>();
    client.events().listen((_) {}, onDone: () => finished.complete());
    await connected.future.timeout(const Duration(seconds: 3));
    client.dispose();
    await Future.wait([finished.future, disconnected.future])
        .timeout(const Duration(seconds: 3));
  });

  test('disposing while renewal is pending cannot open a stale connection',
      () async {
    final renewal = Completer<String?>();
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    var connections = 0;
    server.listen((request) async {
      connections++;
      await request.response.close();
    });
    addTearDown(() => server.close(force: true));
    final client = VoceSseClient(
        baseUrl: 'http://127.0.0.1:${server.port}',
        apiKey: 'fake-key',
        refreshToken: () => renewal.future);
    final finished = Completer<void>();
    client.events().listen((_) {}, onDone: () => finished.complete());
    client.dispose();
    renewal.complete('fake-refreshed-key');
    await finished.future.timeout(const Duration(seconds: 3));
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(connections, 0);
  });

  test(
      'connection status becomes connected only after a server event and changes on socket closure',
      () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final upgraded = Completer<WebSocket>();
    server.listen((request) async {
      final socket = await WebSocketTransformer.upgrade(request);
      socket.listen((_) {});
      upgraded.complete(socket);
    });
    final statuses = <SseStatus>[];
    final reconnected = Completer<void>();
    final first = Completer<void>();
    final client = VoceSseClient(
        baseUrl: 'http://127.0.0.1:${server.port}',
        apiKey: 'fake-key',
        onStatusChanged: (status) {
          statuses.add(status);
          if (status == SseStatus.reconnecting && !reconnected.isCompleted) {
            reconnected.complete();
          }
        });
    addTearDown(() async {
      client.dispose();
      await server.close(force: true);
    });
    client.events().listen((_) {
      if (!first.isCompleted) first.complete();
    });
    final socket = await upgraded.future.timeout(const Duration(seconds: 3));
    expect(statuses, isNot(contains(SseStatus.connected)));
    socket.add('{"type":"ready"}');
    await first.future.timeout(const Duration(seconds: 3));
    expect(statuses.last, SseStatus.connected);
    await socket.close();
    await reconnected.future.timeout(const Duration(seconds: 3));
    expect(statuses.last, SseStatus.reconnecting);
    client.dispose();
    expect(statuses.last, SseStatus.disconnected);
  });

  test('SSE decoder handles split UTF8, comments, CRLF and multiple data lines',
      () async {
    final bytes = utf8.encode(
        ': ping\r\nevent: users_state\r\ndata: {"users":\r\ndata: [{"uid":42,"online":true,"name":"测试"}]}\r\n\r\n');
    final chunks = Stream<List<int>>.fromIterable(bytes.map((b) => [b]));
    final records = await decodeVoceEventStream(chunks).toList();
    final data = jsonDecode(records.single);
    expect(data['type'], 'users_state');
    expect(data['users'][0]['name'], '测试');
  });
}
