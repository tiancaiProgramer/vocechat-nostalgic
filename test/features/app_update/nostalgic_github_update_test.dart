import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocechat_client/features/app_update/data/nostalgic_github_update.dart';

Map<String, dynamic> release({String tag = 'v0.3.35-r10'}) => {
      'tag_name': tag,
      'html_url': 'https://github.com/$nostalgicRepository/releases/tag/$tag',
      'draft': false,
      'prerelease': false,
      'body': 'New features',
      'assets': [
        {
          'name': 'vocechat-nostalgic-arm64.apk',
          'state': 'uploaded',
          'browser_download_url':
              'https://github.com/$nostalgicRepository/releases/download/$tag/vocechat-nostalgic-arm64.apk'
        }
      ],
    };
Dio fake(Map<String, dynamic> data,
    {int code = 200, String version = '0.3.35-r10+3131'}) {
  final dio = Dio();
  dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
    expect(
        options.headers.keys.any((k) =>
            ['authorization', 'x-api-key', 'cookie'].contains(k.toLowerCase())),
        isFalse);
    expect(options.uri.host, 'api.github.com');
    if (options.path.endsWith('/releases')) {
      handler.resolve(Response(
          requestOptions: options,
          statusCode: code,
          data: code == 200 ? [data] : data));
    } else {
      expect(options.queryParameters['ref'], data['tag_name']);
      handler.resolve(Response(requestOptions: options, statusCode: 200, data: {
        'encoding': 'base64',
        'content': base64
            .encode(utf8.encode('name: vocechat_client\nversion: $version\n'))
      }));
    }
  }));
  return dio;
}

void main() {
  test('uses tagged Android build code and own ARM64 asset', () async {
    final dio = fake(release());
    addTearDown(() => dio.close());
    final latest = await NostalgicGithubUpdate(dio).latest(CancelToken());
    expect(latest!.build, 3131);
    expect(latest.version, '0.3.35-r10');
    expect(latest.android!.updateUrl.pathSegments.last,
        'vocechat-nostalgic-arm64.apk');
    expect(latest.android!.isNewerThan(3130), isTrue);
  });
  test('older public release cannot downgrade a newer local build', () async {
    final dio = fake(release(tag: 'v0.3.33-r6'), version: '0.3.33-r6+3127');
    final latest = await NostalgicGithubUpdate(dio).latest(CancelToken());
    expect(latest!.android!.isNewerThan(3130), isFalse);
    dio.close();
  });
  test('no release is different from a network error', () async {
    final dio = fake({}, code: 404);
    expect(await NostalgicGithubUpdate(dio).latest(CancelToken()), isNull);
    dio.close();
  });
  for (final field in ['draft', 'prerelease']) {
    test('rejects $field releases', () async {
      final dio = fake(release()..[field] = true);
      expect(await NostalgicGithubUpdate(dio).latest(CancelToken()), isNull);
      dio.close();
    });
  }
  test('rejects foreign release page', () async {
    final dio = fake(release()
      ..['html_url'] = 'https://github.com/other/app/releases/tag/v0.3.35-r10');
    await expectLater(NostalgicGithubUpdate(dio).latest(CancelToken()),
        throwsFormatException);
    dio.close();
  });
  test('rejects mismatch between release tag and tagged version', () async {
    final dio = fake(release(), version: '0.3.35-r9+3130');
    await expectLater(NostalgicGithubUpdate(dio).latest(CancelToken()),
        throwsFormatException);
    dio.close();
  });
  test('foreign APK is not offered to the native installer', () async {
    final data = release();
    (data['assets'] as List).first['browser_download_url'] =
        'https://evil.invalid/update.apk';
    final dio = fake(data);
    final latest = await NostalgicGithubUpdate(dio).latest(CancelToken());
    expect(latest!.android, isNull);
    dio.close();
  });
  test('current r series outranks old build tags despite stale Latest label',
      () async {
    final dio = Dio();
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      if (options.path.endsWith('/releases')) {
        handler
            .resolve(Response(requestOptions: options, statusCode: 200, data: [
          release(tag: 'v0.3.33-3119'),
          release(tag: 'v0.3.33-r6'),
          release(tag: 'v0.3.33-r5')
        ]));
      } else {
        expect(options.queryParameters['ref'], 'v0.3.33-r6');
        handler
            .resolve(Response(requestOptions: options, statusCode: 200, data: {
          'encoding': 'base64',
          'content': base64.encode(utf8.encode('version: 0.3.33-r6+3127\n'))
        }));
      }
    }));
    expect(
        (await NostalgicGithubUpdate(dio).latest(CancelToken()))!.build, 3127);
    dio.close();
  });
  test('legacy build tag matches its original source version', () async {
    final dio = fake(release(tag: 'v0.3.33-3119'), version: '0.3.33+3119');
    expect(
        (await NostalgicGithubUpdate(dio).latest(CancelToken()))!.build, 3119);
    dio.close();
  });
}
