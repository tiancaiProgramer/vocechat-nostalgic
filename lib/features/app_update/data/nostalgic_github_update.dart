import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/android_release.dart';

const nostalgicRepository = 'tiancaiProgramer/vocechat-nostalgic';
final nostalgicProjectUrl = Uri.https('github.com', '/$nostalgicRepository');
final nostalgicWebsiteUrl = Uri.https('voce.chat');

class NostalgicGithubRelease {
  const NostalgicGithubRelease(
      {required this.version,
      required this.page,
      required this.notes,
      required this.build,
      this.android});
  final String version;
  final Uri page;
  final String notes;
  final int build;
  final AndroidRelease? android;
}

/// A separate public client: chat interceptors/tokens must never reach GitHub.
final nostalgicGithubUpdateProvider = Provider<NostalgicGithubUpdate>((ref) {
  final dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 10),
    followRedirects: false,
    headers: {
      'Accept': 'application/vnd.github+json',
      'Cache-Control': 'no-cache'
    },
  ));
  ref.onDispose(() => dio.close(force: true));
  return NostalgicGithubUpdate(dio);
});

class NostalgicGithubUpdate {
  NostalgicGithubUpdate(this.dio);
  final Dio dio;
  static const api = 'https://api.github.com/repos/$nostalgicRepository';

  Future<NostalgicGithubRelease?> latest(CancelToken cancel) async {
    final response = await dio.get<Object?>('$api/releases',
        queryParameters: {'per_page': 100},
        cancelToken: cancel,
        options: Options(validateStatus: (s) => s == 200 || s == 404));
    if (response.statusCode == 404) return null;
    final items = response.data;
    if (items is! List) throw const FormatException('Invalid release list');
    final candidates = items
        .whereType<Map>()
        .where((item) =>
            item['draft'] == false &&
            item['prerelease'] == false &&
            item['tag_name'] is String &&
            _tagKey(item['tag_name'] as String) != null)
        .toList();
    if (candidates.isEmpty) return null;
    candidates.sort((a, b) {
      final left = _tagKey(a['tag_name'] as String)!;
      final right = _tagKey(b['tag_name'] as String)!;
      for (var i = 0; i < left.length; i++) {
        final order = right[i].compareTo(left[i]);
        if (order != 0) return order;
      }
      return 0;
    });
    final data = candidates.first;
    final tag = data['tag_name'] as String;
    final page = Uri.tryParse(data['html_url'] as String? ?? '');
    if (page == null ||
        !_ownedGithub(page) ||
        page.path != '/$nostalgicRepository/releases/tag/$tag') {
      throw const FormatException('Invalid release page');
    }
    // Read the tagged source version so comparison uses Android's real build
    // number, including older releases whose asset/tag omits that number.
    final source = await dio.get<Object?>('$api/contents/pubspec.yaml',
        queryParameters: {'ref': tag}, cancelToken: cancel);
    final file = source.data;
    if (file is! Map<String, dynamic> ||
        file['encoding'] != 'base64' ||
        file['content'] is! String) {
      throw const FormatException('Missing release version');
    }
    final text = utf8.decode(base64
        .decode((file['content'] as String).replaceAll(RegExp(r'\s'), '')));
    final match = RegExp(r'^version:\s*([^\s+]+)\+(\d+)\s*$', multiLine: true)
        .firstMatch(text);
    final build = match == null ? null : int.tryParse(match[2]!);
    if (match == null ||
        !_versionMatchesTag(tag, match[1]!, build) ||
        build == null ||
        build <= 0 ||
        build > 2100000000) {
      throw const FormatException('Inconsistent release version');
    }
    Uri? apk;
    final assets = data['assets'];
    if (assets is List) {
      for (final item in assets.whereType<Map>()) {
        final name = item['name'];
        if (name is! String ||
            !name.endsWith('.apk') ||
            !name.toLowerCase().contains('arm64') ||
            name.toLowerCase().contains('debug') ||
            item['state'] != 'uploaded') continue;
        final uri = Uri.tryParse(item['browser_download_url'] as String? ?? '');
        if (uri != null &&
            _ownedGithub(uri) &&
            uri.pathSegments.length == 6 &&
            uri.pathSegments.take(5).join('/') ==
                '$nostalgicRepository/releases/download/$tag' &&
            uri.pathSegments.last == name) {
          apk = uri;
          break;
        }
      }
    }
    final version = match[1]!;
    final notes = data['body'] is String ? data['body'] as String : '';
    return NostalgicGithubRelease(
        version: version,
        build: build,
        page: page,
        notes: notes,
        android: apk == null
            ? null
            : AndroidRelease(
                version: version,
                versionCode: build,
                timestamp: DateTime.now().millisecondsSinceEpoch,
                forceUpdate: false,
                updateUrl: apk,
                announcement: notes,
              ));
  }

  // rN is the current release series; historical -3119 tags predate r1.
  List<int>? _tagKey(String tag) {
    final m = RegExp(r'^v?(\d+)\.(\d+)\.(\d+)(?:-(r)?(\d+))?$').firstMatch(tag);
    if (m == null) return null;
    return [
      int.parse(m[1]!),
      int.parse(m[2]!),
      int.parse(m[3]!),
      m[4] == 'r' ? 1 : 0,
      int.tryParse(m[5] ?? '') ?? 0
    ];
  }

  bool _versionMatchesTag(String tag, String version, int? build) {
    final plain = tag.replaceFirst(RegExp(r'^v'), '');
    if (version == plain) return true;
    final old = RegExp(r'^(\d+\.\d+\.\d+)-(\d+)$').firstMatch(plain);
    return old != null && old[1] == version && int.tryParse(old[2]!) == build;
  }

  bool _ownedGithub(Uri uri) =>
      uri.scheme == 'https' &&
      uri.host == 'github.com' &&
      uri.port == 443 &&
      uri.userInfo.isEmpty &&
      uri.query.isEmpty &&
      uri.fragment.isEmpty;
}
