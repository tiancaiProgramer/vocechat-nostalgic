import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:mime/mime.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/network/dio_client.dart';
import '../domain/message_models.dart';
import 'attachment_preparer.dart';
import 'motion_photo_io.dart';

part 'message_api.g.dart';

/// Result of [MessageApi.uploadBytesAndSend]: the server message id plus the
/// stored file path, so the caller can upgrade its optimistic row to the
/// real `{"path": ...}` content without waiting for the SSE echo.
class SendFileResult {
  const SendFileResult({required this.mid, required this.path});

  final int mid;
  final String path;
}

// ---------------------------------------------------------------------------
// MessageApi
// ---------------------------------------------------------------------------

class MessageApi {
  MessageApi(this._dio);

  final Dio _dio;

  // ---- helpers -------------------------------------------------------

  /// Resolve the API path for sending to a target.
  /// Server contract: POST /api/{user|group}/{id}/send (NOT /api/message/...).
  static String _sendPath(MessageTarget target) {
    return target.map(
      user: (t) => '/api/user/${t.uid}/send',
      group: (t) => '/api/group/${t.gid}/send',
    );
  }

  // ---- send ----------------------------------------------------------

  /// [mentions] (group chats only, per web's `enableMention` gating) is sent
  /// as `properties.mentions` via the same `X-Properties` base64-JSON header
  /// mechanism already used by `uploadBytesAndSend` — confirmed accepted on
  /// this endpoint server-side (group.rs / user.rs both read
  /// X-Properties on /send, not just file uploads).
  /// [localId] is echoed unchanged by the server so identical concurrent
  /// messages can confirm their own optimistic rows unambiguously.
  Future<int> sendText(
    MessageTarget target,
    String text, {
    List<int>? mentions,
    int? localId,
  }) async {
    final resp = await _dio.post(
      _sendPath(target),
      data: text,
      options: Options(
        contentType: 'text/plain',
        headers: _propertiesHeader(mentions, localId: localId),
      ),
    );
    // Server returns raw i64 as JSON body (e.g. 602475), not {"mid": 602475}.
    return (resp.data as num).toInt();
  }

  Future<int> sendMarkdown(
    MessageTarget target,
    String md, {
    List<int>? mentions,
    int? localId,
  }) async {
    final resp = await _dio.post(
      _sendPath(target),
      data: md,
      options: Options(
        contentType: 'text/markdown',
        headers: _propertiesHeader(mentions, localId: localId),
      ),
    );
    // Server returns raw i64 as JSON body.
    return (resp.data as num).toInt();
  }

  /// The server accepts arbitrary properties for text, Markdown and replies.
  /// Omit the header when neither mentions nor a local confirmation ID exists.
  static Map<String, dynamic>? _propertiesHeader(
    List<int>? mentions, {
    int? localId,
  }) {
    final properties = <String, dynamic>{
      if (mentions != null && mentions.isNotEmpty) 'mentions': mentions,
      if (localId != null) 'local_id': localId,
    };
    if (properties.isEmpty) return null;
    return {'X-Properties': base64Encode(utf8.encode(jsonEncode(properties)))};
  }

  /// Keep file uploads off the Dart/Android heaps. Only a bounded prefix is
  /// read for MIME detection; each HTTP request streams a bounded file range.
  Future<SendFileResult> uploadFileAndSend(
    MessageTarget target,
    File file, {
    String? filename,
    String? contentType,
    int? width,
    int? height,
    int? localId,
    CancelToken? cancelToken,
    void Function(int sent, int total)? onSendProgress,
  }) async {
    final size = await file.length();
    final reader = await file.open();
    late Uint8List header;
    try {
      header = await reader.read(512);
    } finally {
      await reader.close();
    }
    final name = filename ?? file.uri.pathSegments.last;
    final type = contentType ?? _inferContentType(name, bytes: header);
    return _uploadAndSend(
      target,
      filename: resolveFilename(name, bytes: header, contentType: type),
      contentType: type,
      size: size,
      isMotionPhoto:
          type.startsWith('image/') && await inspectMotionFile(file) != null,
      openRange: (start, end) => file.openRead(start, end),
      width: width,
      height: height,
      localId: localId,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
    );
  }

  /// Clipboard/voice data is already in memory. Use the same bounded upload
  /// protocol as disk files without copying the whole buffer per request.
  Future<SendFileResult> uploadBytesAndSend(
    MessageTarget target, {
    required Uint8List bytes,
    required String filename,
    String? contentType,
    bool isVoiceMessage = false,
    int? width,
    int? height,
    int? localId,
    CancelToken? cancelToken,
    void Function(int sent, int total)? onSendProgress,
  }) async {
    final prepared = await AttachmentPreparer.prepare(
      bytes: bytes,
      filename: filename,
      contentType: contentType,
    );
    bytes = prepared.bytes;
    filename = prepared.filename;
    final resolvedType =
        prepared.contentType ?? _inferContentType(filename, bytes: bytes);
    return _uploadAndSend(
      target,
      filename: resolveFilename(
        filename,
        bytes: bytes,
        contentType: resolvedType,
      ),
      contentType: resolvedType,
      size: bytes.length,
      isMotionPhoto: prepared.isMotionPhoto,
      openRange: (start, end) =>
          Stream.value(Uint8List.sublistView(bytes, start, end)),
      isVoiceMessage: isVoiceMessage,
      width: width,
      height: height,
      localId: localId,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
    );
  }

  // Below the default Nginx 1 MiB body limit, including multipart overhead.
  static const uploadChunkSize = 512 * 1024;

  Future<SendFileResult> _uploadAndSend(
    MessageTarget target, {
    required String filename,
    required String contentType,
    required int size,
    required Stream<List<int>> Function(int start, int end) openRange,
    bool isVoiceMessage = false,
    bool isMotionPhoto = false,
    int? width,
    int? height,
    int? localId,
    CancelToken? cancelToken,
    void Function(int sent, int total)? onSendProgress,
  }) async {
    final prepareResp = await _uploadPost(
      '/api/resource/file/prepare',
      stage: 'prepare',
      fileSize: size,
      data: {'content_type': contentType, 'filename': filename},
      cancelToken: cancelToken,
    );
    final prepareData = prepareResp.data;
    final fileId = prepareData is String
        ? prepareData
        : (prepareData is Map ? prepareData['file_id'] as String? : null);
    if (fileId == null || fileId.isEmpty) {
      throw StateError('prepare upload returned no file_id');
    }

    // Chunks append to the prepared ID. Never replay an uncertain chunk:
    // manual retry starts with a fresh prepare ID, avoiding duplicated bytes.
    Map? uploaded;
    for (var offset = 0; offset < size || (size == 0 && offset == 0);) {
      if (cancelToken?.isCancelled == true) throw cancelToken!.cancelError!;
      final start = offset;
      final end = (start + uploadChunkSize).clamp(0, size);
      final chunk = MultipartFile.fromStream(
        () => openRange(start, end),
        end - start,
        filename: filename,
      );
      final form = FormData.fromMap({
        'file_id': fileId,
        'chunk_data': chunk,
        'chunk_is_last': end == size ? 'true' : 'false',
      });
      final overhead = form.length - chunk.length;
      final response = await _uploadPost(
        '/api/resource/file/upload',
        stage: end == size ? 'finalize' : 'chunk',
        offset: start,
        fileSize: size,
        data: form,
        cancelToken: cancelToken,
        onSendProgress: (sent, total) => onSendProgress?.call(
          start + (sent - overhead).clamp(0, end - start),
          size,
        ),
      );
      if (end == size) {
        if (response.data is! Map) {
          throw StateError('upload did not return a file path');
        }
        uploaded = response.data as Map;
        break;
      }
      if (response.data != null) {
        throw StateError('upload finalized before the last chunk');
      }
      offset = end;
    }
    final path = uploaded?['path'];
    if (path is! String ||
        path.isEmpty ||
        (uploaded?['size'] is num &&
            (uploaded!['size'] as num).toInt() != size)) {
      debugPrint('VoceUpload stage=metadata total=$size '
          'returnedSize=${uploaded?['size'] is num ? uploaded!['size'] : -1}');
      throw StateError('upload returned invalid file metadata');
    }
    final imgProps = uploaded?['image_properties'] as Map?;
    final properties = <String, dynamic>{
      'name': filename,
      'content_type': contentType,
      'size': size,
      if (isMotionPhoto) 'motion_photo': true,
      if (imgProps?['width'] != null || width != null)
        'width': (imgProps?['width'] as num?)?.toInt() ?? width,
      if (imgProps?['height'] != null || height != null)
        'height': (imgProps?['height'] as num?)?.toInt() ?? height,
      if (localId != null) 'local_id': localId,
    };
    final sendResp = await _uploadPost(
      _sendPath(target),
      stage: 'message',
      fileSize: size,
      data: jsonEncode({'path': path}),
      cancelToken: cancelToken,
      options: Options(
        contentType: isVoiceMessage ? 'vocechat/audio' : 'vocechat/file',
        headers: {
          'X-Properties': base64Encode(utf8.encode(jsonEncode(properties))),
        },
      ),
    );
    return SendFileResult(mid: (sendResp.data as num).toInt(), path: path);
  }

  /// Diagnostics contain only fixed stages, byte counts and HTTP/error codes.
  /// Never include file names, resource IDs, auth tokens or response bodies.
  Future<Response<dynamic>> _uploadPost(
    String path, {
    required String stage,
    required int fileSize,
    int offset = 0,
    dynamic data,
    Options? options,
    CancelToken? cancelToken,
    void Function(int, int)? onSendProgress,
  }) async {
    try {
      return await _dio.post(path,
          data: data,
          options: options,
          cancelToken: cancelToken,
          onSendProgress: onSendProgress);
    } on DioException catch (error) {
      debugPrint('VoceUpload stage=$stage offset=$offset total=$fileSize '
          'category=${error.type.name} status=${error.response?.statusCode ?? 0}');
      rethrow;
    }
  }

  // ---- history -------------------------------------------------------

  Future<List<ChatMessage>> getHistory(
    MessageTarget target, {
    int? beforeMid,
    int limit = 30,
  }) =>
      getHistoryForSearch(target, beforeMid: beforeMid, limit: limit);

  Future<List<ChatMessage>> getHistoryForSearch(
    MessageTarget target, {
    int? beforeMid,
    int limit = 100,
    CancelToken? cancelToken,
  }) async {
    final String path = target.map(
      user: (t) => '/api/user/${t.uid}/history',
      group: (t) => '/api/group/${t.gid}/history',
    );

    final Map<String, dynamic> queryParams = {'limit': limit};
    if (beforeMid != null) {
      queryParams['before'] = beforeMid;
    }

    final resp = await _dio.get(
      path,
      queryParameters: queryParams,
      cancelToken: cancelToken,
    );
    final list = resp.data as List<dynamic>;
    // Server returns oldest-first; the rest of the app (chat_controller,
    // conversation_providers, ListView with reverse:true) all assume
    // newest-first. Reverse once here so that contract is consistent.
    final parsed = list
        .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
        .toList();
    return parsed.reversed.toList(growable: false);
  }

  // ---- edit / delete / react ----------------------------------------

  Future<int> editMessage(int mid, String text) async {
    final resp = await _dio.put(
      '/api/message/$mid/edit',
      data: text,
      options: Options(contentType: 'text/plain'),
    );
    // Server returns raw i64 (the new reaction mid).
    return (resp.data as num).toInt();
  }

  Future<int> editMessageMarkdown(int mid, String md) async {
    final resp = await _dio.put(
      '/api/message/$mid/edit',
      data: md,
      options: Options(contentType: 'text/markdown'),
    );
    return (resp.data as num).toInt();
  }

  Future<int> deleteMessage(int mid) async {
    final resp = await _dio.delete('/api/message/$mid');
    // Server returns raw i64 (the new reaction mid).
    return (resp.data as num).toInt();
  }

  /// Post a reply to the message identified by [targetMid]. Server returns the
  /// new reply message's mid.
  Future<int> replyMessage(
    int targetMid,
    String text, {
    bool markdown = false,
    List<int>? mentions,
    int? localId,
  }) async {
    final resp = await _dio.post(
      '/api/message/$targetMid/reply',
      data: text,
      options: Options(
        contentType: markdown ? 'text/markdown' : 'text/plain',
        headers: _propertiesHeader(mentions, localId: localId),
      ),
    );
    return (resp.data as num).toInt();
  }

  Future<int> reactMessage(int mid, String emoji) async {
    final resp = await _dio.put(
      '/api/message/$mid/like',
      data: {'action': emoji},
    );
    // Server returns raw i64 (the new reaction mid).
    return (resp.data as num).toInt();
  }

  // ---- forward (archive) ----------------------------------------------

  /// Bundles [mids] into a new server-side archive. Server contract:
  /// POST /api/resource/archive, body {"mid_list": [...]}, response is a bare
  /// JSON string path like `2026/7/8/<uuid>` (`Json<String>`, not wrapped).
  /// Mirrors web's `createArchive` (src/app/services/message.ts).
  Future<String> createArchive(List<int> mids) async {
    final resp = await _dio.post(
      '/api/resource/archive',
      data: {'mid_list': mids},
    );
    final data = resp.data;
    final path =
        data is String ? data : (data is Map ? data['id'] as String? : null);
    if (path == null || path.isEmpty) {
      throw StateError('createArchive returned no path: $data');
    }
    return path;
  }

  /// Sends a forwarded-message reference to [target]. Server contract: the
  /// archive id is sent as the raw body string (not JSON-wrapped) with
  /// content-type `vocechat/archive` — mirrors web's
  /// `sendUserMsg({type:"archive", id, content: archive_id})` where `content`
  /// is used directly as the request body.
  Future<int> sendArchive(MessageTarget target, String archiveId) async {
    final resp = await _dio.post(
      _sendPath(target),
      data: archiveId,
      options: Options(contentType: 'vocechat/archive'),
    );
    return (resp.data as num).toInt();
  }

  /// Fetches the archive index for a forwarded-message card. Server contract:
  /// `GET /api/resource/archive?file_path=<path>` -> `Json<Archive>`.
  Future<Archive> getArchive(String filePath) async {
    final resp = await _dio.get(
      '/api/resource/archive',
      queryParameters: {'file_path': filePath},
    );
    return Archive.fromJson(resp.data as Map<String, dynamic>);
  }

  // ---- read index ----------------------------------------------------

  /// Report how far the user has read in one or more conversations.
  /// Server contract: POST /api/user/read-index with
  /// `{"users":[{"uid","mid"}], "groups":[{"gid","mid"}]}`. The server only
  /// moves a marker forward, so re-sending a stale mid is harmless.
  Future<void> readMessage({
    List<({int uid, int mid})>? users,
    List<({int gid, int mid})>? groups,
  }) async {
    final body = <String, dynamic>{
      if (users != null && users.isNotEmpty)
        'users': [
          for (final u in users) {'uid': u.uid, 'mid': u.mid},
        ],
      if (groups != null && groups.isNotEmpty)
        'groups': [
          for (final g in groups) {'gid': g.gid, 'mid': g.mid},
        ],
    };
    if (body.isEmpty) return;
    await _dio.post('/api/user/read-index', data: body);
  }

  // ---- burn-after-read (auto-delete) ---------------------------------

  /// Update the auto-delete ("burn after reading") setting for one or more
  /// DM peers / channels. Server contract: POST /api/user/burn-after-reading
  /// with `{"users":[{"uid","expires_in"}], "groups":[{"gid","expires_in"}]}`.
  /// `expiresIn` is seconds; `0` disables (server deletes the row), `>0`
  /// enables/updates. Verified against vocechat-server's
  /// `update_burn_after_reading` handler (api/user.rs) and web's
  /// `useUpdateAutoDeleteMsgMutation` (app/services/user.ts).
  Future<void> updateBurnAfterReading({
    List<({int uid, int expiresIn})>? users,
    List<({int gid, int expiresIn})>? groups,
  }) async {
    final body = <String, dynamic>{
      if (users != null && users.isNotEmpty)
        'users': [
          for (final u in users) {'uid': u.uid, 'expires_in': u.expiresIn},
        ],
      if (groups != null && groups.isNotEmpty)
        'groups': [
          for (final g in groups) {'gid': g.gid, 'expires_in': g.expiresIn},
        ],
    };
    if (body.isEmpty) return;
    await _dio.post('/api/user/burn-after-reading', data: body);
  }

  // ---- util ----------------------------------------------------------

  /// Public wrapper so callers (controller / UI staging) can resolve a MIME
  /// type for a picked/pasted file before constructing the optimistic message.
  static String inferContentType(String filename, {Uint8List? bytes}) =>
      _inferContentType(filename, bytes: bytes);

  /// Preserve supplied names; give unnamed attachments a type-based name.
  static String resolveFilename(
    String? filename, {
    required Uint8List bytes,
    String? contentType,
  }) {
    if (filename != null && filename.trim().isNotEmpty) return filename;
    final type = contentType?.split(';').first.trim().toLowerCase();
    final resolvedType =
        type == null || type.isEmpty || type == 'application/octet-stream'
            ? _inferContentType('', bytes: bytes)
            : type;
    final prefix = resolvedType.startsWith('image/') ? 'image' : 'file';
    final extension = resolvedType == 'image/jpeg'
        ? 'jpg'
        : extensionFromMime(resolvedType) ?? 'bin';
    return '$prefix.$extension';
  }

  static String _inferContentType(String filename, {Uint8List? bytes}) {
    final ext =
        filename.contains('.') ? filename.split('.').last.toLowerCase() : '';
    const map = {
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'gif': 'image/gif',
      'webp': 'image/webp',
      'mp4': 'video/mp4',
      'mp3': 'audio/mpeg',
      'm4a': 'audio/mp4',
      'pdf': 'application/pdf',
    };
    final byExt = map[ext];
    if (byExt != null) return byExt;

    // Clipboard images often arrive with no extension — sniff magic numbers.
    final sniffed = bytes == null ? null : _sniffImageType(bytes);
    return sniffed ??
        lookupMimeType(filename, headerBytes: bytes) ??
        'application/octet-stream';
  }

  /// Detect common image types from their leading bytes. Returns null when the
  /// bytes don't match a known signature.
  static String? _sniffImageType(Uint8List b) {
    if (b.length >= 8 &&
        b[0] == 0x89 &&
        b[1] == 0x50 &&
        b[2] == 0x4E &&
        b[3] == 0x47) {
      return 'image/png';
    }
    if (b.length >= 3 && b[0] == 0xFF && b[1] == 0xD8 && b[2] == 0xFF) {
      return 'image/jpeg';
    }
    if (b.length >= 6 &&
        b[0] == 0x47 &&
        b[1] == 0x49 &&
        b[2] == 0x46 &&
        b[3] == 0x38) {
      return 'image/gif';
    }
    // WEBP: "RIFF"...."WEBP"
    if (b.length >= 12 &&
        b[0] == 0x52 &&
        b[1] == 0x49 &&
        b[2] == 0x46 &&
        b[3] == 0x46 &&
        b[8] == 0x57 &&
        b[9] == 0x45 &&
        b[10] == 0x42 &&
        b[11] == 0x50) {
      return 'image/webp';
    }
    return null;
  }
}

// ---------------------------------------------------------------------------
// Riverpod provider
// ---------------------------------------------------------------------------

@riverpod
MessageApi messageApi(Ref ref) {
  return MessageApi(ref.watch(dioProvider));
}
