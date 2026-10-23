import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'custom_sticker_store.dart';

enum StickerSyncStatus { local, syncing, synced, pending, unavailable }

/// Snapshot of a single VC account. Tokens are never sent to another origin.
class StickerSession {
  const StickerSession(this.baseUrl, this.uid, this.token);
  final String baseUrl;
  final int uid;
  final String token;
}

typedef StickerSessionReader = Future<StickerSession?> Function();

class StickerSync {
  StickerSync(this.store, this.session, {Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
                connectTimeout: const Duration(seconds: 5),
                receiveTimeout: const Duration(seconds: 20),
                sendTimeout: const Duration(seconds: 20),
                followRedirects: false));

  final CustomStickerStore store;
  final StickerSessionReader session;
  final Dio _dio;
  final CancelToken _cancel = CancelToken();
  StickerSession? _identity;

  void dispose() {
    _cancel.cancel();
    _dio.close(force: true);
  }

  Future<Response<dynamic>> _request(String method, String suffix,
      {Uint8List? bytes, CustomSticker? sticker}) async {
    final credentials = await session();
    if (_cancel.isCancelled || credentials == null) {
      throw StateError('Account changed');
    }
    final previous = _identity;
    if (previous != null &&
        (credentials.baseUrl != previous.baseUrl ||
            credentials.uid != previous.uid)) {
      throw StateError('Account changed');
    }
    _identity = credentials;
    final base = Uri.parse(credentials.baseUrl);
    if (!const {'http', 'https'}.contains(base.scheme) ||
        base.host.isEmpty ||
        base.userInfo.isNotEmpty) {
      throw StateError('Invalid server URL');
    }
    // Match the VC server's optional URL prefix; never follow redirects with
    // the session header, including redirects to a login page or CDN.
    final prefix = base.path.replaceFirst(RegExp(r'/+$'), '');
    final url = base.replace(
        path: '$prefix/stickers/v1/stickers$suffix',
        query: null,
        fragment: null);
    return _dio.requestUri(url,
        data: bytes,
        cancelToken: _cancel,
        options: Options(
            method: method,
            followRedirects: false,
            responseType: method == 'GET' && suffix.isNotEmpty
                ? ResponseType.stream
                : ResponseType.json,
            headers: {
              'X-API-Key': credentials.token,
              'Referer': base
                  .replace(path: '/', query: null, fragment: null)
                  .toString(),
              if (bytes != null) ...{
                'Content-Type': sticker!.contentType,
                'Content-Length': bytes.length,
                'X-Sticker-Width': sticker.width,
                'X-Sticker-Height': sticker.height,
              },
            }));
  }

  Future<List<CustomSticker>> _list() async {
    final response = await _request('GET', '');
    final data = response.data;
    if (data is! Map ||
        data['service'] != 'vocechat-stickers' ||
        data['version'] != 1 ||
        data['uid'] != _identity!.uid ||
        data['items'] is! List) {
      throw const FormatException('Not a sticker service');
    }
    final items = (data['items'] as List)
        .map((e) => CustomSticker.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    if (items.length > 512 ||
        items.map((e) => e.id).toSet().length != items.length) {
      throw const FormatException('Invalid library');
    }
    return items;
  }

  Future<StickerSyncStatus> run() async {
    _identity = null;
    try {
      // Do not upload anything until the same-origin endpoint identifies
      // itself and confirms the expected VC user. Unconfigured servers simply
      // retain the existing local-only behavior.
      await _list();
    } on DioException catch (e) {
      return const {404, 405}.contains(e.response?.statusCode)
          ? StickerSyncStatus.local
          : StickerSyncStatus.unavailable;
    } on FormatException {
      return StickerSyncStatus.local;
    } catch (_) {
      return StickerSyncStatus.unavailable;
    }
    try {
      final operations = await store.pending();
      for (final entry in operations.entries) {
        if (entry.value.action == 'delete') {
          await _request('DELETE', '/${entry.key}');
        } else {
          final sticker =
              (await store.list()).where((e) => e.id == entry.key).firstOrNull;
          if (sticker == null) continue; // removed while synchronizing
          final bytes = await store.read(sticker);
          await _request('PUT', '/${entry.key}',
              bytes: bytes, sticker: sticker);
        }
        await store.acknowledge(entry.key, entry.value);
      }
      final remote = await _list();
      final local = {for (final item in await store.list()) item.id: item};
      for (final item in remote) {
        // Also repair a missing cache file without manufacturing a new upload.
        if (local.containsKey(item.id) && await store.fileFor(item).exists()) {
          continue;
        }
        final response = await _request('GET', '/${item.id}');
        final body = response.data as ResponseBody;
        final builder = BytesBuilder(copy: false);
        await for (final chunk
            in body.stream.timeout(const Duration(seconds: 20))) {
          if (builder.length + chunk.length > maxStickerBytes) {
            throw const FormatException('Oversized image');
          }
          builder.add(chunk);
        }
        final raw = builder.takeBytes();
        await store.receive(item, raw);
      }
      // A failed/truncated snapshot or download never reaches this removal.
      if (await session() == null || _cancel.isCancelled) {
        throw StateError('Account changed');
      }
      await store.reconcile(remote.map((e) => e.id).toSet());
      return (await store.pending()).isEmpty
          ? StickerSyncStatus.synced
          : StickerSyncStatus.pending;
    } catch (_) {
      return StickerSyncStatus.pending;
    }
  }
}
