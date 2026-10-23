import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ServerConnectionFailure {
  timeout,
  network,
  certificate,
  http,
  invalidResponse,
  cancelled
}

class ServerConnectionException implements Exception {
  const ServerConnectionException(this.failure, {this.status});
  final ServerConnectionFailure failure;
  final int? status;
}

final serverConnectionProvider =
    Provider<ServerConnection>((ref) => ServerConnection());

/// Public onboarding requests have a total deadline, no auth refresh/retries,
/// and always close their transport (including stalled DNS/TLS/body reads).
class ServerConnection {
  ServerConnection(
      {this.deadline = const Duration(seconds: 10),
      Dio Function(BaseOptions)? createDio})
      : _createDio = createDio ?? Dio.new;
  final Duration deadline;
  final Dio Function(BaseOptions) _createDio;
  final _prepared = <String, ({DateTime at, Map<String, dynamic> body})>{};

  static String normalize(String url) =>
      url.trim().replaceAll(RegExp(r'/+$'), '');

  Future<Map<String, dynamic>> probe(String url,
      {CancelToken? cancelToken}) async {
    final body = await _request(url, '/api/admin/system/organization',
        cancelToken: cancelToken);
    if (body is! Map ||
        !(body['name'] is String || body['server_id'] is String)) {
      throw const ServerConnectionException(
          ServerConnectionFailure.invalidResponse);
    }
    return Map<String, dynamic>.from(body);
  }

  /// Only a successful explicit selection seeds this one-use result. Ordinary
  /// identity checks remain fresh, so server replacements are still detected.
  void prepareLogin(String url, Map<String, dynamic> body) {
    _prepared.clear();
    _prepared[normalize(url)] = (at: DateTime.now(), body: Map.of(body));
  }

  Future<Map<String, dynamic>> organizationForAuth(String url) {
    final cached = _prepared.remove(normalize(url));
    if (cached != null &&
        DateTime.now().difference(cached.at) < const Duration(seconds: 30)) {
      return Future.value(cached.body);
    }
    return probe(url);
  }

  Future<bool> checkMagicToken(String url, String token,
          {CancelToken? cancelToken}) async =>
      await _request(url, '/api/user/check_magic_token',
          data: {'magic_token': token}, cancelToken: cancelToken) ==
      true;

  Future<Object?> _request(String url, String path,
      {Map<String, dynamic>? data, CancelToken? cancelToken}) async {
    final base = normalize(url);
    final uri = Uri.tryParse(base);
    if (uri == null ||
        !{'http', 'https'}.contains(uri.scheme) ||
        uri.host.isEmpty) {
      throw const ServerConnectionException(
          ServerConnectionFailure.invalidResponse);
    }
    final token = cancelToken ?? CancelToken();
    final dio = _createDio(BaseOptions(
      baseUrl: base,
      connectTimeout: deadline,
      sendTimeout: deadline,
      receiveTimeout: deadline,
      headers: {
        'Referer': '${uri.scheme}://${uri.authority}/',
        'Accept': 'application/json'
      },
    ));
    try {
      final response = await dio
          .request<Object?>(
        path,
        data: data,
        options: Options(method: data == null ? 'GET' : 'POST'),
        cancelToken: token,
      )
          .timeout(deadline, onTimeout: () {
        token.cancel('Connection deadline exceeded');
        throw const ServerConnectionException(ServerConnectionFailure.timeout);
      });
      return response.data;
    } on DioException catch (e) {
      throw ServerConnectionException(
          switch (e.type) {
            DioExceptionType.connectionTimeout ||
            DioExceptionType.receiveTimeout ||
            DioExceptionType.sendTimeout =>
              ServerConnectionFailure.timeout,
            DioExceptionType.badCertificate =>
              ServerConnectionFailure.certificate,
            DioExceptionType.badResponse => ServerConnectionFailure.http,
            DioExceptionType.cancel => ServerConnectionFailure.cancelled,
            _ => ServerConnectionFailure.network,
          },
          status: e.response?.statusCode);
    } finally {
      dio.close(force: true);
    }
  }
}
