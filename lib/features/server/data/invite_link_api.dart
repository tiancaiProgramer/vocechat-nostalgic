import 'package:dio/dio.dart';

import 'server_connection.dart';

/// Public invitation validation shares onboarding's cancellable total deadline.
class InviteLinkApi {
  InviteLinkApi(this.serverBaseUrl);
  final String serverBaseUrl;

  Future<bool> checkMagicToken(String magicToken, {CancelToken? cancelToken}) =>
      ServerConnection()
          .checkMagicToken(serverBaseUrl, magicToken, cancelToken: cancelToken);
}
