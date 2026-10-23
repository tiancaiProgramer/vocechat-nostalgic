import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:vocechat_client/features/messages/data/custom_sticker_store.dart';

Uint8List fixture(String name) =>
    File('test/fixtures/stickers/$name').readAsBytesSync();
Matcher fails(StickerFailure reason) =>
    throwsA(isA<StickerException>().having((e) => e.reason, 'reason', reason));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory root;
  late CustomStickerStore store;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('voce-stickers-test-');
    store = CustomStickerStore(root, 'server::7');
  });
  tearDown(() async => root.delete(recursive: true));

  test(
      'stores owned copies, reloads, deduplicates and removes without touching source',
      () async {
    final bytes = fixture('red.png');
    final first = await store.add(bytes);
    expect(first.added, isTrue);
    expect((first.sticker.width, first.sticker.height), (24, 18));
    expect((await store.add(bytes)).added, isFalse);
    final reopened = CustomStickerStore(root, 'server::7');
    expect((await reopened.list()).single.id, first.sticker.id);
    expect(await reopened.read(first.sticker), bytes);
    await reopened.remove(first.sticker);
    expect(await CustomStickerStore(root, 'server::7').list(), isEmpty);
    expect(await reopened.fileFor(first.sticker).exists(), isFalse);
    expect(fixture('red.png'), bytes);
  });

  test('GIF bytes and both animation frames survive storage', () async {
    final bytes = fixture('animated.gif');
    final saved = (await store.add(bytes)).sticker;
    expect(saved.contentType, 'image/gif');
    final reopened = CustomStickerStore(root, 'server::7');
    final original = await reopened.read((await reopened.list()).single);
    expect(original, bytes);
    final codec = await ui.instantiateImageCodec(original);
    expect(codec.frameCount, 2);
    codec.dispose();
  });

  test('isolation includes both account and server identity', () async {
    final saved = (await store.add(fixture('red.png'))).sticker;
    for (final id in ['server::8', 'another-server::7']) {
      final other = CustomStickerStore(root, id);
      expect(await other.list(), isEmpty);
      expect(other.directory.path, isNot(store.directory.path));
      await expectLater(other.read(saved), fails(StickerFailure.missing));
    }
    expect(await store.read(saved), fixture('red.png'));
  });

  test(
      'rejects oversized, corrupt and disguised non-images without changing library',
      () async {
    final saved = (await store.add(fixture('red.png'))).sticker;
    await expectLater(store.add(Uint8List(maxStickerBytes + 1)),
        fails(StickerFailure.tooLarge));
    for (final bytes in [
      Uint8List(0),
      Uint8List.fromList(utf8.encode('not a png')),
      Uint8List.fromList([137, 80, 78, 71, 13, 10, 26, 10])
    ]) {
      await expectLater(store.add(bytes), fails(StickerFailure.unsupported));
    }
    expect((await store.list()).single.id, saved.id);
  });

  test(
      'missing or altered files give an actionable error and reimport repairs them',
      () async {
    final bytes = fixture('red.png');
    final saved = (await store.add(bytes)).sticker;
    await store.fileFor(saved).delete();
    await expectLater(store.read(saved), fails(StickerFailure.missing));
    expect((await store.add(bytes)).added, isFalse);
    await store.fileFor(saved).writeAsBytes(Uint8List(bytes.length));
    await expectLater(store.read(saved), fails(StickerFailure.missing));
    await store.add(bytes);
    expect(await store.read(saved), bytes);
  });

  test('serializes simultaneous imports and removal', () async {
    final results = await Future.wait(List.generate(
        8, (i) => store.add(fixture(i.isEven ? 'red.png' : 'blue.png'))));
    expect(results.where((e) => e.added), hasLength(2));
    final items = await store.list();
    await Future.wait(items.map(store.remove));
    expect(await CustomStickerStore(root, 'server::7').list(), isEmpty);
  });

  test('a corrupt manifest is reported and never overwritten by an import',
      () async {
    await store.directory.create(recursive: true);
    final manifest = File('${store.directory.path}/index.json');
    for (final content in [
      'broken json',
      jsonEncode({'version': 100, 'items': []}),
      jsonEncode({'version': 1, 'sync_version': 100, 'items': []}),
      jsonEncode({
        'version': 1,
        'items': [
          {
            'id': '../escape',
            'extension': 'png',
            'width': 1,
            'height': 1,
            'size': 1
          }
        ]
      })
    ]) {
      await manifest.writeAsString(content);
      final reopened = CustomStickerStore(root, 'server::7');
      await expectLater(reopened.list(), fails(StickerFailure.storage));
      await expectLater(
          reopened.add(fixture('red.png')), fails(StickerFailure.storage));
      expect(await manifest.readAsString(), content);
    }
  });

  test('JPEG signature is accepted and assigned the proper MIME', () async {
    final saved = (await store.add(fixture('red.jpg'))).sticker;
    expect(saved.extension, 'jpg');
    expect(saved.contentType, 'image/jpeg');
  });
}
