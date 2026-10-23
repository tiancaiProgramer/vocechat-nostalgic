import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocechat_client/features/messages/data/custom_sticker_store.dart';
import 'package:vocechat_client/features/messages/data/sticker_message_source.dart';
import 'package:vocechat_client/features/messages/domain/message_models.dart';

ChatMessage image(
        {String content = '2026/10/file',
        String mime = 'image/gif',
        int? expiresIn,
        int mid = 10,
        bool reply = false}) =>
    ChatMessage(
        mid: mid,
        fromUid: 7,
        createdAt: 1000,
        target: const MessageTarget.user(uid: 8),
        detail: reply
            ? MessageDetail.reply(
                mid: 5,
                contentType: 'vocechat/file',
                content: content,
                properties: {'content_type': mime},
                expiresIn: expiresIn)
            : MessageDetail.normal(
                contentType: 'vocechat/file',
                content: content,
                properties: {'content_type': mime},
                expiresIn: expiresIn));

void main() {
  test('collects normal and reply images using bare or JSON resource paths',
      () {
    expect(stickerPathForMessage(image()), '2026/10/file');
    expect(
        stickerPathForMessage(
            image(reply: true, content: jsonEncode({'path': 'image/path'}))),
        'image/path');
    for (final msg in [
      image(expiresIn: 60),
      image(reply: true, expiresIn: 60),
      image(mid: -1),
      image(content: 'local:123'),
      image(mime: 'video/mp4'),
      image(content: '{bad json'),
      image(content: '')
    ]) {
      expect(stickerPathForMessage(msg), isNull);
    }
  });

  test('download requests original from fixed server with fixed-account auth',
      () async {
    final dio = Dio();
    addTearDown(() => dio.close(force: true));
    RequestOptions? sent;
    dio.interceptors.add(InterceptorsWrapper(onRequest: (request, handler) {
      sent = request;
      handler.resolve(Response(
          requestOptions: request,
          data: ResponseBody.fromBytes([1, 2, 3], 200)));
    }));
    final bytes = await downloadStickerOriginal(
        dio: dio,
        baseUrl: 'https://chat.test/prefix/',
        accessToken: 'test-key',
        resourcePath: 'dir/a & b.gif');
    expect(bytes, [1, 2, 3]);
    expect(sent!.uri.path, '/prefix/api/resource/file');
    expect(sent!.uri.queryParameters, {'file_path': 'dir/a & b.gif'});
    expect(sent!.headers['X-API-Key'], 'test-key');
    expect(sent!.headers['Referer'], 'https://chat.test/');
    expect(sent!.followRedirects, isFalse);
    expect(sent!.responseType, ResponseType.stream);
  });

  for (final declared in [true, false]) {
    test('rejects oversized ${declared ? 'declared' : 'streamed'} download',
        () async {
      final dio = Dio();
      addTearDown(() => dio.close(force: true));
      dio.interceptors.add(InterceptorsWrapper(onRequest: (request, handler) {
        handler.resolve(Response(
            requestOptions: request,
            headers: Headers.fromMap(declared
                ? {
                    'content-length': ['${maxStickerBytes + 1}']
                  }
                : {}),
            data: ResponseBody(
                Stream.value(Uint8List(maxStickerBytes + 1)), 200)));
      }));
      await expectLater(
          downloadStickerOriginal(
              dio: dio,
              baseUrl: 'https://chat.test',
              accessToken: 'test-key',
              resourcePath: 'image'),
          throwsA(isA<StickerException>()
              .having((e) => e.reason, 'reason', StickerFailure.tooLarge)));
    });
  }
}
