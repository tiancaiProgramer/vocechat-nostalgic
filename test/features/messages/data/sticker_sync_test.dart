import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocechat_client/features/messages/data/custom_sticker_store.dart';
import 'package:vocechat_client/features/messages/data/sticker_sync.dart';

class Remote implements HttpClientAdapter {
  final items = <String, (CustomSticker, Uint8List)>{};
  final requests = <RequestOptions>[];
  int listStatus = 200;
  int uid = 7;
  bool corrupt = false;
  bool quota = false;
  Future<void> Function(RequestOptions)? before;
  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    requests.add(options);
    expect(options.uri.origin, 'https://vc.example.test');
    expect(options.followRedirects, isFalse);
    expect(options.headers['X-API-Key'], 'test-session');
    await before?.call(options);
    final path = options.uri.path;
    final id = path.split('/').last;
    Object body = {};
    var status = 200;
    if (id == 'stickers') {
      status = listStatus;
      body = {
        'service': 'vocechat-stickers',
        'version': 1,
        'uid': uid,
        'items': items.values.map((v) => v.$1.toJson()).toList()
      };
    } else if (options.method == 'PUT') {
      final bytes = await requestStream!.fold<BytesBuilder>(
          BytesBuilder(), (builder, chunk) => builder..add(chunk));
      if (quota) {
        status = 409;
      } else {
        final raw = bytes.takeBytes();
        final metadata = await inspectSticker(raw);
        expect(metadata.id, id);
        items[id] = (metadata, raw);
      }
    } else if (options.method == 'DELETE') {
      items.remove(id);
    } else {
      final bytes = corrupt ? Uint8List.fromList([1, 2, 3]) : items[id]!.$2;
      return ResponseBody.fromBytes(bytes, 200, headers: {
        'content-type': ['application/octet-stream']
      });
    }
    return ResponseBody.fromString(jsonEncode(body), status, headers: {
      'content-type': ['application/json']
    });
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory root;
  late CustomStickerStore a;
  late CustomStickerStore b;
  late Remote remote;
  final png = File('test/fixtures/stickers/red.png').readAsBytesSync();
  final gif = File('test/fixtures/stickers/animated.gif').readAsBytesSync();
  setUp(() async {
    root = await Directory.systemTemp.createTemp('sticker-sync-test-');
    a = CustomStickerStore(Directory('${root.path}/device-a'), 'server::7');
    b = CustomStickerStore(Directory('${root.path}/device-b'), 'server::7');
    remote = Remote();
  });
  tearDown(() async => root.delete(recursive: true));
  StickerSync client(CustomStickerStore store,
      {StickerSessionReader? session}) {
    final dio = Dio()..httpClientAdapter = remote;
    final sync = StickerSync(
        store,
        session ??
            () async => const StickerSession(
                'https://vc.example.test', 7, 'test-session'),
        dio: dio);
    addTearDown(sync.dispose);
    return sync;
  }

  test('two phones upload, restore GIF bytes and propagate deletions',
      () async {
    final saved = (await a.add(gif)).sticker;
    expect(await client(a).run(), StickerSyncStatus.synced);
    expect(remote.items[saved.id]!.$2, gif);
    expect(await client(b).run(), StickerSyncStatus.synced);
    expect(await b.read((await b.list()).single), gif);
    await a.remove(saved);
    expect(await client(a).run(), StickerSyncStatus.synced);
    expect(await client(b).run(), StickerSyncStatus.synced);
    expect(await b.list(), isEmpty);
    expect(await b.pending(), isEmpty);
  });
  test('unconfigured or failed service keeps all local files and operations',
      () async {
    final saved = (await a.add(png)).sticker;
    for (final code in [404, 502, 401]) {
      remote.listStatus = code;
      expect(
          await client(a).run(),
          code == 404
              ? StickerSyncStatus.local
              : StickerSyncStatus.unavailable);
      expect(await a.read(saved), png);
      expect(await a.pending(), hasLength(1));
    }
    expect(remote.requests.every((o) => o.method == 'GET'), isTrue);
  });
  test('wrong server user never receives uploads', () async {
    await a.add(png);
    remote.uid = 8;
    expect(await client(a).run(), StickerSyncStatus.local);
    expect(remote.items, isEmpty);
    expect(await a.pending(), hasLength(1));
  });
  test('quota leaves a durable pending upload and succeeds on retry', () async {
    await a.add(png);
    remote.quota = true;
    expect(await client(a).run(), StickerSyncStatus.pending);
    a = CustomStickerStore(Directory('${root.path}/device-a'), 'server::7');
    expect(await a.pending(), hasLength(1));
    remote.quota = false;
    expect(await client(a).run(), StickerSyncStatus.synced);
  });
  test('corrupt download cannot remove existing local stickers', () async {
    final local = (await a.add(png)).sticker;
    await client(a).run();
    remote.items.clear();
    final g = await inspectSticker(gif);
    remote.items[g.id] = (g, gif);
    remote.corrupt = true;
    expect(await client(a).run(), StickerSyncStatus.pending);
    expect(await a.read(local), png);
  });
  test('account switch cancels before uploading private files', () async {
    await a.add(png);
    var active = true;
    remote.before = (o) async {
      active = false;
    };
    final sync = client(a,
        session: () async => active
            ? const StickerSession('https://vc.example.test', 7, 'test-session')
            : null);
    expect(await sync.run(), StickerSyncStatus.pending);
    expect(remote.items, isEmpty);
    expect(remote.requests, hasLength(1));
  });
  test('deletion during upload is not acknowledged as the newer operation',
      () async {
    final saved = (await a.add(png)).sticker;
    remote.before = (o) async {
      if (o.method == 'PUT') await a.remove(saved);
    };
    expect(await client(a).run(), StickerSyncStatus.pending);
    expect(await a.list(), isEmpty);
    expect((await a.pending())[saved.id]!.action, 'delete');
    remote.before = null;
    expect(await client(a).run(), StickerSyncStatus.synced);
    expect(remote.items, isEmpty);
  });
  test('old local-only index migrates without losing stickers', () async {
    final saved = (await a.add(png)).sticker;
    await File('${a.directory.path}/index.json').writeAsString(jsonEncode({
      'version': 1,
      'items': [saved.toJson()],
    }));
    a = CustomStickerStore(Directory('${root.path}/device-a'), 'server::7');
    expect(await client(a).run(), StickerSyncStatus.synced);
    expect(remote.items[saved.id]!.$2, png);
    expect(await a.read(saved), png);
  });
  test('a remote copy cannot resurrect a locally deleted sticker', () async {
    final saved = (await a.add(png)).sticker;
    await client(a).run();
    await a.remove(saved);
    await a.receive(saved, png);
    expect(await a.list(), isEmpty);
    expect((await a.pending())[saved.id]!.action, 'delete');
  });
}
