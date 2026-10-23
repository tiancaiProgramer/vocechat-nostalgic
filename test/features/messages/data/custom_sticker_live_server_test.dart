import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocechat_client/features/messages/data/custom_sticker_store.dart';
import 'package:vocechat_client/features/messages/data/message_api.dart';
import 'package:vocechat_client/features/messages/data/sticker_message_source.dart';
import 'package:vocechat_client/features/messages/domain/message_models.dart';

const origin = String.fromEnvironment('LOCAL_STICKER_SERVER');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
      'real isolated server receives reusable GIF as an ordinary image message',
      () async {
    expect(Uri.parse(origin).host, '127.0.0.1');
    HttpOverrides.global = null;
    Dio client() => Dio(BaseOptions(
        baseUrl: origin,
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Referer': '$origin/'}));
    final sender = client();
    final receiver = client();
    final root = await Directory.systemTemp.createTemp('voce-sticker-live-');
    addTearDown(() async {
      for (final dio in [sender, receiver]) {
        try {
          await dio.get('/api/token/logout');
        } catch (_) {/* isolated fixture */}
        dio.close(force: true);
      }
      await root.delete(recursive: true);
    });
    Future<Map<String, dynamic>> login(
        Dio dio, String email, String password) async {
      final response = await dio.post('/api/token/login', data: {
        'credential': {
          'type': 'password',
          'email': email,
          'password': password
        },
        'device': 'stickers-test-${DateTime.now().microsecondsSinceEpoch}',
      });
      final result = response.data as Map<String, dynamic>;
      dio.options.headers['X-API-Key'] = result['token'];
      return result;
    }

    final a =
        await login(sender, 'presence-probe@example.test', 'PresenceProbe2026');
    try {
      await receiver.post('/api/user/register', data: {
        'email': 'stickers-receiver@example.test',
        'password': 'StickerReceiver2026',
        'name': 'Sticker test receiver',
        'device': 'stickers-test-register',
      });
    } on DioException catch (error) {
      if (error.response?.statusCode != 409) rethrow;
    }
    final b = await login(
        receiver, 'stickers-receiver@example.test', 'StickerReceiver2026');
    final senderUid = (a['user'] as Map)['uid'] as int;
    final receiverUid = (b['user'] as Map)['uid'] as int;
    final original =
        File('test/fixtures/stickers/animated.gif').readAsBytesSync();
    final saved =
        await CustomStickerStore(root, 'sender::$senderUid').add(original);
    final result = await MessageApi(sender).uploadBytesAndSend(
        MessageTarget.user(uid: receiverUid),
        bytes: original,
        filename: saved.sticker.filename,
        contentType: saved.sticker.contentType,
        width: saved.sticker.width,
        height: saved.sticker.height);
    final incoming = (await MessageApi(receiver)
            .getHistory(MessageTarget.user(uid: senderUid)))
        .singleWhere((message) => message.mid == result.mid);
    expect(incoming.displayContentType, 'vocechat/file');
    expect(incoming.fromUid, senderUid);
    final path = stickerPathForMessage(incoming);
    expect(path, isNotNull);
    final downloaded = await downloadStickerOriginal(
        dio: receiver,
        baseUrl: origin,
        accessToken: b['token'] as String,
        resourcePath: path!);
    expect(downloaded, original);
    final recipientStore = CustomStickerStore(root, 'receiver::$receiverUid');
    final collected = await recipientStore.add(downloaded);
    expect(collected.sticker.contentType, 'image/gif');
    expect(collected.sticker.id, saved.sticker.id);
    final second = await MessageApi(receiver).uploadBytesAndSend(
        MessageTarget.user(uid: senderUid),
        bytes: await recipientStore.read(collected.sticker),
        filename: collected.sticker.filename,
        contentType: collected.sticker.contentType);
    final returned = (await MessageApi(sender)
            .getHistory(MessageTarget.user(uid: receiverUid)))
        .singleWhere((message) => message.mid == second.mid);
    expect(returned.displayContentType, 'vocechat/file');
    expect(returned.fromUid, receiverUid);
  },
      skip: origin.isEmpty
          ? 'Requires an isolated localhost VoceChat fixture'
          : false);
}
