import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mime/mime.dart';
import 'package:vocechat_client/features/messages/data/message_api.dart';
import 'package:vocechat_client/features/messages/domain/message_models.dart';

const target = MessageTarget.user(uid: 2);

void main() {
  late Directory dir;
  late _AppendServer server;
  late Dio dio;
  late MessageApi api;
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('vc-stream-test-');
    server = _AppendServer(dir);
    dio = Dio()..httpClientAdapter = server;
    api = MessageApi(dio);
  });
  tearDown(() async {
    dio.close(force: true);
    await dir.delete(recursive: true);
  });

  test('150 MiB APK streams bounded chunks with exact contents and progress',
      () async {
    final file = File('${dir.path}/source.apk');
    final writer = await file.open(mode: FileMode.write);
    await writer.truncate(150 * 1024 * 1024 + 17);
    await writer.setPosition(150 * 1024 * 1024);
    await writer.writeFrom(List.generate(17, (i) => i + 1));
    await writer.close();
    final diskOnly = _DiskOnlyFile(file);
    final progress = <int>[];
    final result = await api.uploadFileAndSend(target, diskOnly,
        filename: 'renamed.apk', localId: 42, onSendProgress: (sent, total) {
      expect(total, 150 * 1024 * 1024 + 17);
      if (progress.isNotEmpty) {
        expect(sent, greaterThanOrEqualTo(progress.last));
      }
      progress.add(sent);
    });
    expect(result.mid, 99);
    expect(server.maxChunk, lessThanOrEqualTo(MessageApi.uploadChunkSize));
    expect(server.chunks, 301);
    expect(diskOnly.maxReadRange, MessageApi.uploadChunkSize);
    expect(await sha256.bind(file.openRead()).first,
        await sha256.bind(server.file('id1').openRead()).first);
    expect(server.properties!['size'], await file.length());
    expect(server.properties!['name'], 'renamed.apk');
    expect(server.properties!['local_id'], 42);
    expect(server.properties!['content_type'],
        'application/vnd.android.package-archive');
    expect(progress.last, await file.length());
    expect(server.sentMessages, 1);
  });

  test('failed append never sends a message; retry uses a new file ID',
      () async {
    final file = File('${dir.path}/source.apk');
    await file.writeAsBytes(Uint8List(MessageApi.uploadChunkSize + 13));
    server.failChunk = 2;
    await expectLater(api.uploadFileAndSend(target, _DiskOnlyFile(file)),
        throwsA(isA<DioException>()));
    expect(server.sentMessages, 0);
    expect(await server.file('id1').length(), MessageApi.uploadChunkSize);
    server.failChunk = null;
    await api.uploadFileAndSend(target, _DiskOnlyFile(file));
    expect(server.prepared, 2);
    expect(await server.file('id2').length(), await file.length());
    expect(server.sentMessages, 1);
  });

  test('empty file is finalized once', () async {
    final file = await File('${dir.path}/empty.txt').create();
    await api.uploadFileAndSend(target, file);
    expect(server.chunks, 1);
    expect(server.properties!['size'], 0);
    expect(server.sentMessages, 1);
  });

  test('cancellation between chunks never finalizes or sends', () async {
    final token = CancelToken();
    server.afterChunk = () => token.cancel('test');
    final file = File('${dir.path}/source.apk');
    await file.writeAsBytes(Uint8List(MessageApi.uploadChunkSize + 13));
    await expectLater(api.uploadFileAndSend(target, file, cancelToken: token),
        throwsA(isA<DioException>()));
    expect(server.chunks, 1);
    expect(server.sentMessages, 0);
  });

  test('voice and in-memory attachments share the chunk protocol', () async {
    await api.uploadBytesAndSend(target,
        bytes: Uint8List(MessageApi.uploadChunkSize + 13),
        filename: 'voice.m4a',
        contentType: 'audio/mp4',
        isVoiceMessage: true);
    expect(server.chunks, 2);
    expect(server.messageType, 'vocechat/audio');
    expect(server.sentMessages, 1);
  });
}

/// Fails if production code tries to materialize the full file.
class _DiskOnlyFile implements File {
  _DiskOnlyFile(this.file);
  final File file;
  int maxReadRange = 0;
  @override
  Future<int> length() => file.length();
  @override
  Future<RandomAccessFile> open({FileMode mode = FileMode.read}) =>
      file.open(mode: mode);
  @override
  Stream<List<int>> openRead([int? start, int? end]) {
    if (start == null ||
        end == null ||
        end - start > MessageApi.uploadChunkSize) {
      throw StateError('unbounded file read');
    }
    maxReadRange = (end - start) > maxReadRange ? end - start : maxReadRange;
    return file.openRead(start, end);
  }

  @override
  Future<Uint8List> readAsBytes() => throw StateError('whole-file read');
  @override
  Uri get uri => file.uri;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Exercises finalized Dio multipart streams using the VC append protocol.
class _AppendServer implements HttpClientAdapter {
  _AppendServer(this.dir);
  final Directory dir;
  int prepared = 0, chunks = 0, maxChunk = 0, sentMessages = 0;
  int? failChunk;
  void Function()? afterChunk;
  Map<String, dynamic>? properties;
  String? messageType;
  File file(String id) => File('${dir.path}/$id');
  ResponseBody json(Object? body) =>
      ResponseBody.fromString(jsonEncode(body), 200, headers: {
        Headers.contentTypeHeader: ['application/json']
      });
  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    if (options.path.endsWith('/prepare')) {
      final id = 'id${++prepared}';
      await file(id).writeAsBytes([]);
      return json(id);
    }
    if (options.path.endsWith('/upload')) {
      chunks++;
      if (chunks == failChunk) throw DioException(requestOptions: options);
      final type = ContentType.parse(
          options.headers[Headers.contentTypeHeader] as String);
      String? id;
      var last = false;
      var length = 0;
      final parts = MimeMultipartTransformer(type.parameters['boundary']!)
          .bind(requestStream!);
      await for (final part in parts) {
        final disposition = part.headers['content-disposition']!;
        if (disposition.contains('name="chunk_data"')) {
          final sink = file(id!).openWrite(mode: FileMode.append);
          await for (final bytes in part) {
            length += bytes.length;
            sink.add(bytes);
          }
          await sink.close();
        } else {
          final value = await utf8.decoder.bind(part).join();
          if (disposition.contains('name="file_id"')) id = value;
          if (disposition.contains('name="chunk_is_last"')) {
            last = value == 'true';
          }
        }
      }
      maxChunk = length > maxChunk ? length : maxChunk;
      afterChunk?.call();
      return json(last
          ? {'path': '2026/10/29/$id', 'size': await file(id!).length()}
          : null);
    }
    sentMessages++;
    messageType = options.contentType;
    properties = jsonDecode(utf8
            .decode(base64Decode(options.headers['X-Properties'] as String)))
        as Map<String, dynamic>;
    return json(99);
  }

  @override
  void close({bool force = false}) {}
}
