import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocechat_client/features/server/data/server_connection.dart';

class ProbeAdapter implements HttpClientAdapter {
  ProbeAdapter(this.respond);
  final Future<ResponseBody> Function(RequestOptions) respond;
  bool closed = false;
  RequestOptions? options;
  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) {
    this.options = options;
    return respond(options);
  }

  @override
  void close({bool force = false}) {
    closed = true;
  }
}

ResponseBody jsonReply(Object? body, {int status = 200}) =>
    ResponseBody.fromString(jsonEncode(body), status, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType]
    });

ServerConnection connectionWith(ProbeAdapter adapter,
        {Duration deadline = const Duration(seconds: 1)}) =>
    ServerConnection(
      deadline: deadline,
      createDio: (options) => Dio(options)..httpClientAdapter = adapter,
    );

void main() {
  test('total deadline cancels a transport that never returns and closes it',
      () async {
    final pending = Completer<ResponseBody>();
    final adapter = ProbeAdapter((_) => pending.future);
    final token = CancelToken();
    await expectLater(
        connectionWith(adapter, deadline: const Duration(milliseconds: 50))
            .probe('https://chat.test', cancelToken: token),
        throwsA(isA<ServerConnectionException>().having(
            (e) => e.failure, 'failure', ServerConnectionFailure.timeout)));
    expect(token.isCancelled, isTrue);
    expect(adapter.closed, isTrue);
    // Even a late response cannot turn a timeout into success.
    pending.complete(jsonReply({'name': 'Late'}));
  });

  test(
      'public probe includes Referer, validates organization and closes on success',
      () async {
    final adapter = ProbeAdapter(
        (_) async => jsonReply({'name': 'Demo', 'server_id': 'org'}));
    final result =
        await connectionWith(adapter).probe('https://chat.test/prefix/');
    expect(result['server_id'], 'org');
    expect(adapter.options!.uri.toString(),
        'https://chat.test/prefix/api/admin/system/organization');
    expect(adapter.options!.headers['Referer'], 'https://chat.test/');
    expect(adapter.options!.headers['X-API-Key'], isNull);
    expect(adapter.closed, isTrue);
  });

  test('HTML or unrelated JSON is not a successful server test', () async {
    for (final body in [
      '<html>proxy page</html>',
      {'ok': true}
    ]) {
      final adapter = ProbeAdapter((_) async => jsonReply(body));
      await expectLater(
          connectionWith(adapter).probe('https://chat.test'),
          throwsA(isA<ServerConnectionException>().having((e) => e.failure,
              'failure', ServerConnectionFailure.invalidResponse)));
      expect(adapter.closed, isTrue);
    }
  });

  test('HTTP and certificate failures retain their useful cause', () async {
    final http = ProbeAdapter((_) async => jsonReply({}, status: 503));
    await expectLater(
        connectionWith(http).probe('https://chat.test'),
        throwsA(isA<ServerConnectionException>()
            .having((e) => e.failure, 'failure', ServerConnectionFailure.http)
            .having((e) => e.status, 'status', 503)));
    final tls = ProbeAdapter((options) async => throw DioException(
        requestOptions: options, type: DioExceptionType.badCertificate));
    await expectLater(
        connectionWith(tls).probe('https://chat.test'),
        throwsA(isA<ServerConnectionException>().having(
            (e) => e.failure, 'failure', ServerConnectionFailure.certificate)));
  });

  test(
      'closing the screen cancels a pending request without waiting for deadline',
      () async {
    final adapter = ProbeAdapter((_) => Completer<ResponseBody>().future);
    final token = CancelToken();
    final future =
        connectionWith(adapter).probe('https://chat.test', cancelToken: token);
    final assertion = expectLater(
        future,
        throwsA(isA<ServerConnectionException>().having(
            (e) => e.failure, 'failure', ServerConnectionFailure.cancelled)));
    token.cancel('screen closed');
    await assertion;
    expect(adapter.closed, isTrue);
  });

  test(
      'successful picker probe is consumed once; future identity checks stay fresh',
      () async {
    var calls = 0;
    final adapter = ProbeAdapter((_) async {
      calls++;
      return jsonReply({'server_id': 'new'});
    });
    final connection = connectionWith(adapter);
    connection.prepareLogin('https://chat.test/', {'server_id': 'selected'});
    expect(
        (await connection
            .organizationForAuth('https://chat.test'))['server_id'],
        'selected');
    expect(calls, 0);
    expect(
        (await connection
            .organizationForAuth('https://chat.test'))['server_id'],
        'new');
    expect(calls, 1);
  });

  test('invitation validation uses same deadline and Referer', () async {
    final pending = ProbeAdapter((_) => Completer<ResponseBody>().future);
    await expectLater(
        connectionWith(pending, deadline: const Duration(milliseconds: 50))
            .checkMagicToken('https://chat.test', 'example-token'),
        throwsA(isA<ServerConnectionException>().having(
            (e) => e.failure, 'failure', ServerConnectionFailure.timeout)));
    expect(pending.closed, isTrue);
    expect(pending.options!.headers['Referer'], 'https://chat.test/');
  });
}
