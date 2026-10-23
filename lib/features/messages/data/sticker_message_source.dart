import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../domain/message_models.dart';
import 'custom_sticker_store.dart';

/// Uses only the resource path, never an arbitrary URL from message content.
String? stickerPathForMessage(ChatMessage message) {
  if (message.mid <= 0 || message.displayContentType != 'vocechat/file') {
    return null;
  }
  final (properties, expires) = switch (message.detail) {
    NormalMessageDetail(:final properties, :final expiresIn) => (
        properties,
        expiresIn
      ),
    ReplyMessageDetail(:final properties, :final expiresIn) => (
        properties,
        expiresIn
      ),
    _ => (null, null),
  };
  if (expires != null) return null;
  final type = properties?['content_type']?.toString().toLowerCase();
  if (!const {'image/png', 'image/jpeg', 'image/gif', 'image/webp'}
      .contains(type)) {
    return null;
  }
  var path = message.displayContent.trim();
  if (path.startsWith('{')) {
    try {
      path = (jsonDecode(path) as Map<String, dynamic>)['path'] as String;
    } catch (_) {
      return null;
    }
  }
  return path.isEmpty || path.startsWith('local:') ? null : path;
}

/// Fixed-account credentials are supplied by the caller. No redirects may carry
/// an API key outside the selected server, and streaming bounds memory use.
Future<Uint8List> downloadStickerOriginal({
  required Dio dio,
  required String baseUrl,
  required String accessToken,
  required String resourcePath,
}) async {
  final base = baseUrl.replaceFirst(RegExp(r'/+$'), '');
  final uri = Uri.parse('$base/api/resource/file')
      .replace(queryParameters: {'file_path': resourcePath});
  final response = await dio.get<ResponseBody>(uri.toString(),
      options: Options(
          responseType: ResponseType.stream,
          followRedirects: false,
          receiveTimeout: const Duration(seconds: 30),
          headers: {'X-API-Key': accessToken, 'Referer': '${uri.origin}/'}));
  final body = response.data;
  if (body == null) throw const StickerException(StickerFailure.download);
  final length =
      int.tryParse(response.headers.value(Headers.contentLengthHeader) ?? '');
  final stream = body.stream;
  if (length != null && length > maxStickerBytes) {
    await stream.listen((_) {}).cancel();
    throw const StickerException(StickerFailure.tooLarge);
  }
  final bytes = BytesBuilder(copy: false);
  await for (final chunk in stream) {
    if (bytes.length + chunk.length > maxStickerBytes) {
      throw const StickerException(StickerFailure.tooLarge);
    }
    bytes.add(chunk);
  }
  return bytes.takeBytes();
}
