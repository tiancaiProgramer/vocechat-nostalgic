import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:vocechat_client/core/network/dio_client.dart';
import 'package:vocechat_client/features/auth/application/auth_controller.dart';
import 'package:vocechat_client/features/channels/application/conversation_providers.dart';
import 'package:vocechat_client/features/messages/data/message_api.dart';
import 'package:vocechat_client/features/messages/data/message_cache.dart';
import 'package:vocechat_client/features/messages/domain/message_models.dart';

ChatMessage message(int mid, {int gid = 42}) => ChatMessage(
      mid: mid,
      fromUid: 2,
      createdAt: 1700000000000 + mid,
      target: MessageTarget.group(gid: gid),
      detail: MessageDetail.normal(
          contentType: 'text/plain', content: '测试消息 $mid ' * 8),
    );

void metric(String name, Stopwatch watch,
    {Map<String, dynamic> extra = const {}}) {
  // ignore: avoid_print
  print('PERF ${jsonEncode({
        'name': name,
        'microseconds': watch.elapsedMicroseconds,
        'rss_bytes': ProcessInfo.currentRss,
        ...extra
      })}');
}

class CachedRoster implements MessageCache {
  final rows = List.generate(
      200,
      (i) => ConversationItem(
            key: GroupConversationKey(i + 1),
            name: 'Group ${i + 1}',
            isChannel: true,
            lastMid: 500,
            lastAt: 1700000000500,
            lastPreview: 'cached preview',
          ).toJson());
  @override
  Future<List<Map<String, dynamic>>?> readConversations() async => rows;
  @override
  Future<void> writeConversations(List<Map<String, dynamic>> data) async {}
  @override
  Future<List<ChatMessage>> read(MessageTarget target,
      {int limit = 500}) async {
    final gid = (target as MessageTargetGroup).gid;
    return [
      for (var mid = 500; mid > 500 - limit; mid--) message(mid, gid: gid)
    ];
  }

  @override
  Future<void> deleteMid(MessageTarget target, int mid) async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class HistoryApi extends MessageApi {
  HistoryApi() : super(Dio());
  int calls = 0;
  int bytes = 0;
  int active = 0;
  int maxActive = 0;
  @override
  Future<List<ChatMessage>> getHistory(MessageTarget target,
      {int? beforeMid, int limit = 30}) async {
    calls++;
    active++;
    if (active > maxActive) maxActive = active;
    await Future<void>.delayed(const Duration(milliseconds: 5));
    final gid = (target as MessageTargetGroup).gid;
    final raw = jsonEncode([
      for (var mid = 500; mid > 500 - limit; mid--)
        message(mid, gid: gid).toJson()
    ]);
    bytes += utf8.encode(raw).length;
    final result = (jsonDecode(raw) as List)
        .map((row) =>
            ChatMessage.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList();
    active--;
    return result;
  }
}

class Client implements VoceDioClient {
  Client(this.dio);
  @override
  final Dio dio;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class Auth extends AuthController {
  @override
  Future<AuthState> build() async => const AuthState.unauthenticated();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  test('benchmark parses 10000 incoming message events', () {
    final raw = jsonEncode({'type': 'chat', ...message(1).toJson()});
    for (var warm = 0; warm < 1000; warm++) {
      expect(parseSseEvent('chat', raw), isA<ChatEventChat>());
    }
    final watch = Stopwatch()..start();
    var count = 0;
    for (var i = 0; i < 10000; i++) {
      if (parseSseEvent('chat', raw) is ChatEventChat) count++;
    }
    watch.stop();
    expect(count, 10000);
    metric('parse_10000_events', watch);
  });

  test('benchmark SQLite writes, cursor and 500-row read', () async {
    final directory =
        await Directory.systemTemp.createTemp('vocechat-perf-db-');
    final db = await databaseFactoryFfi.openDatabase(
        '${directory.path}/messages.sqlite',
        options: OpenDatabaseOptions(singleInstance: false));
    final cache = MessageCache.forTesting(db);
    try {
      await db.execute(
          'CREATE TABLE messages (target_key TEXT NOT NULL, mid INTEGER NOT NULL, from_uid INTEGER NOT NULL, created_at INTEGER NOT NULL, payload TEXT NOT NULL, PRIMARY KEY (target_key, mid))');
      await db.execute(
          'CREATE TABLE meta (key TEXT PRIMARY KEY, value TEXT NOT NULL)');
      await db.execute('PRAGMA journal_mode=WAL');
      final watch = Stopwatch()..start();
      const target = MessageTarget.group(gid: 42);
      for (var mid = 1; mid <= 1000; mid++) {
        await cache.appendOne(target, message(mid), advanceCursor: true);
      }
      watch.stop();
      expect(await cache.getCursor(), 1000);
      metric('sqlite_1000_atomic_writes', watch);
      final readWatch = Stopwatch()..start();
      final rows = await cache.read(target);
      readWatch.stop();
      expect(rows.first.mid, 1000);
      expect(rows.length, lessThanOrEqualTo(500));
      expect(rows.map((m) => m.mid).toSet().length, rows.length);
      metric('sqlite_read_500', readWatch, extra: {'rows': rows.length});
    } finally {
      await db.close();
      await directory.delete(recursive: true);
    }
  });

  test('benchmark 200 cached conversations and background refresh', () async {
    final cache = CachedRoster();
    final api = HistoryApi();
    final dio = Dio();
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      handler.resolve(Response<dynamic>(
          requestOptions: options,
          data: options.path == '/api/group'
              ? List.generate(
                  200, (i) => {'gid': i + 1, 'name': 'Group ${i + 1}'})
              : []));
    }));
    final container = ProviderContainer(overrides: [
      messageCacheProvider.overrideWith((ref) async => cache),
      messageApiProvider.overrideWith((ref) => api),
      dioClientProvider.overrideWith((ref) => Client(dio)),
      authControllerProvider.overrideWith(Auth.new),
    ]);
    try {
      final watch = Stopwatch()..start();
      final list = await container.read(conversationsProvider.future);
      watch.stop();
      expect(list.length, 200);
      metric('cached_200_conversations_first_state', watch);
      final refresh = Stopwatch()..start();
      await container.read(conversationsProvider.notifier).refresh();
      refresh.stop();
      expect(container.read(conversationsProvider).requireValue.length, 200);
      expect(api.maxActive, lessThanOrEqualTo(3));
      metric('refresh_200_cached_conversations', refresh, extra: {
        'http_history_calls': api.calls,
        'decoded_response_bytes': api.bytes,
        'max_concurrent_requests': api.maxActive,
      });
    } finally {
      container.dispose();
    }
  });
}
