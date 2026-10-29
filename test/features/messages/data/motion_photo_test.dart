import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocechat_client/features/messages/data/attachment_preparer.dart';
import 'package:vocechat_client/features/messages/data/message_api.dart';
import 'package:vocechat_client/features/messages/data/motion_photo.dart';
import 'package:vocechat_client/features/messages/data/motion_photo_io.dart';
import 'package:vocechat_client/features/messages/domain/message_models.dart';

Uint8List fixture(String name) =>
    File('test/fixtures/live_photos/$name').readAsBytesSync();
Uint8List box(String type, List<int> content, {bool extended = false}) {
  final head = ByteData(extended ? 16 : 8)
    ..setUint32(0, extended ? 1 : content.length + 8);
  if (extended) head.setUint64(8, content.length + 16);
  final bytes = head.buffer.asUint8List()..setRange(4, 8, ascii.encode(type));
  return Uint8List.fromList([...bytes, ...content]);
}

Uint8List jpegXmp(Uint8List jpeg, String xmp) {
  final data = utf8.encode('http://ns.adobe.com/xap/1.0/\u0000$xmp');
  return Uint8List.fromList([
    255,
    216,
    255,
    225,
    (data.length + 2) >> 8,
    (data.length + 2) & 255,
    ...data,
    ...jpeg.skip(2)
  ]);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final still = fixture('still.jpg'), movie = fixture('paired.mov');
  for (final name in ['legacy-motion.jpg', 'trailer-motion.jpg']) {
    test('extracts complete synthetic movie from $name', () {
      final bytes = fixture(name),
          clip = MotionPhoto.inspectBytes(fixture(name));
      expect(clip, isNotNull);
      expect(bytes.sublist(clip!.offset, clip.offset + clip.length), movie);
    });
  }
  test(
      'combines Apple-style still/MOV resources into standard single-file transport',
      () async {
    final prepared = await AttachmentPreparer.prepareLivePhoto(
        still: still, movie: movie, filename: 'IMG_1234.JPG');
    expect(prepared.isMotionPhoto, isTrue);
    expect(prepared.filename, 'IMG_1234_MP.jpg');
    expect(prepared.contentType, 'image/jpeg');
    final clip = MotionPhoto.inspectBytes(prepared.bytes)!;
    expect(prepared.bytes.sublist(clip.offset), movie);
    final again = await AttachmentPreparer.prepare(
        bytes: prepared.bytes, filename: prepared.filename);
    expect(identical(again.bytes, prepared.bytes), isTrue);
    expect(again.isMotionPhoto, isTrue);
  });
  for (final extended in [false, true]) {
    test('HEIC final mpvd box has correct still boundary (extended=$extended)',
        () {
      final image = [
        ...box('ftyp', ascii.encode('heic0000mif1')),
        ...box('meta', [0, 0, 0, 0])
      ];
      final data = Uint8List.fromList(
          [...image, ...box('mpvd', movie, extended: extended)]);
      final clip = MotionPhoto.inspectBytes(data)!;
      expect(clip.stillLength, image.length);
      expect(data.sublist(clip.offset, clip.offset + clip.length), movie);
    });
  }
  test(
      'explicit MotionPhoto=0 remains a still even with an appended valid movie',
      () {
    final data = jpegXmp(still,
        '<x:xmpmeta xmlns:x="adobe:ns:meta/"><a MotionPhoto="0"/></x:xmpmeta>');
    expect(MotionPhoto.inspectBytes(Uint8List.fromList([...data, ...movie])),
        isNull);
  });
  test('supports element syntax and alternate XML prefixes for old offsets',
      () {
    final data = jpegXmp(still,
        '<x:xmpmeta xmlns:x="adobe:ns:meta/"><Other:MicroVideoOffset xmlns:Other="test">${movie.length}</Other:MicroVideoOffset></x:xmpmeta>');
    expect(
        MotionPhoto.inspectBytes(Uint8List.fromList([...data, ...movie]))!
            .length,
        movie.length);
  });
  test('ordinary JPEG and standalone MOV are not detected as live photos', () {
    expect(MotionPhoto.inspectBytes(still), isNull);
    expect(MotionPhoto.inspectBytes(movie), isNull);
  });
  test('invalid movie cannot be combined or accepted as a trailer', () {
    final broken = Uint8List.fromList([
      ...box('ftyp', ascii.encode('qt  0000')),
      ...box('mdat', [1, 2, 3])
    ]);
    expect(() => MotionPhoto.combineJpeg(still, broken), throwsFormatException);
    expect(MotionPhoto.inspectBytes(Uint8List.fromList([...still, ...broken])),
        isNull);
    final truncated = fixture('legacy-motion.jpg');
    expect(
        MotionPhoto.inspectBytes(
            Uint8List.sublistView(truncated, 0, truncated.length - 10)),
        isNull);
  });
  test('bad lengths and random headers never read outside file or throw', () {
    final random = Random(3119);
    for (var i = 0; i < 200; i++) {
      final data = Uint8List.fromList(
          List.generate(random.nextInt(2048), (_) => random.nextInt(256)));
      if (data.length > 2) {
        data[0] = 255;
        data[1] = 216;
      }
      expect(() => MotionPhoto.inspectBytes(data), returnsNormally);
    }
    expect(
        MotionPhoto.inspect(MotionPhoto.maxBytes + 1,
            (_, __) => throw StateError('must not read')),
        isNull);
  });
  test(
      'file extraction streams exact movie and does not create a file for stills',
      () async {
    final dir = await Directory.systemTemp.createTemp('vc-motion-');
    addTearDown(() => dir.delete(recursive: true));
    final source = File('${dir.path}/photo.jpg')
      ..writeAsBytesSync(fixture('legacy-motion.jpg'));
    final target = File('${dir.path}/video.mov');
    expect(await inspectMotionFile(source), isNotNull);
    expect(await extractMotionMovie(source, target), isTrue);
    expect(await target.readAsBytes(), movie);
    final noVideo = File('${dir.path}/no-video.mov');
    source.writeAsBytesSync(still);
    expect(await extractMotionMovie(source, noVideo), isFalse);
    expect(await noVideo.exists(), isFalse);
  });
  test('HEIC/MOV pairing converts still while preserving movie bytes',
      () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    const channel = MethodChannel('vocechat/image_conversion');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async => still);
    addTearDown(() => TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null));
    final heic = box('ftyp', ascii.encode('heic0000mif1heic'));
    final prepared = await AttachmentPreparer.prepareLivePhoto(
        still: heic, movie: movie, filename: 'IMG.HEIC');
    expect(prepared.filename, 'IMG_MP.jpg');
    final clip = MotionPhoto.inspectBytes(prepared.bytes)!;
    expect(prepared.bytes.sublist(clip.offset), movie);
  });
  test(
      'upload preserves original live bytes and adds motion flag to message properties',
      () async {
    final data = fixture('legacy-motion.jpg'), requests = <RequestOptions>[];
    final dio = Dio();
    addTearDown(() => dio.close(force: true));
    dio.interceptors.add(InterceptorsWrapper(onRequest: (request, handler) {
      requests.add(request);
      handler.resolve(Response<dynamic>(
          requestOptions: request,
          data: request.path.endsWith('/prepare')
              ? 'id'
              : request.path.endsWith('/upload')
                  ? {'path': 'photo', 'size': data.length}
                  : 123));
    }));
    await MessageApi(dio).uploadBytesAndSend(const MessageTarget.group(gid: 42),
        bytes: data, filename: 'photo.jpg', contentType: 'image/jpeg');
    final form = requests[1].data as FormData;
    expect(await form.files.single.value.finalize().expand((c) => c).toList(),
        data);
    final props = jsonDecode(
        utf8.decode(base64Decode(requests.last.headers['X-Properties'])));
    expect(props['motion_photo'], isTrue);
    expect(props['size'], data.length);
  });
}
