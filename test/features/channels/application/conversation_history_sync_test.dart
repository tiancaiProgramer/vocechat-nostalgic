import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocechat_client/core/network/dio_client.dart';
import 'package:vocechat_client/features/auth/application/auth_controller.dart';
import 'package:vocechat_client/features/channels/application/conversation_providers.dart';
import 'package:vocechat_client/features/messages/data/message_api.dart';
import 'package:vocechat_client/features/messages/data/message_cache.dart';
import 'package:vocechat_client/features/messages/domain/message_models.dart';

const target = MessageTarget.group(gid: 42);
const oldPreview = ConversationItem(
  key: GroupConversationKey(42),
  name: 'Channel',
  isChannel: true,
  lastMid: 20,
  lastAt: 1000,
  lastPreview: 'old text',
  lastFromUid: 2,
);

ChatMessage message(int mid) => ChatMessage(
      mid: mid,
      fromUid: 2,
      createdAt: 1000,
      target: target,
      detail: const MessageDetail.normal(
        contentType: 'text/plain',
        content: 'text',
      ),
    );

class Cache implements MessageCache {
  final rows = [message(20)];
  List<Map<String, dynamic>> conversations = [oldPreview.toJson()];
  @override
  Future<List<Map<String, dynamic>>?> readConversations() async =>
      conversations;
  @override
  Future<void> writeConversations(List<Map<String, dynamic>> items) async {
    conversations = items;
  }

  @override
  Future<List<ChatMessage>> read(
    MessageTarget target, {
    int limit = 500,
  }) async =>
      List.of(rows);
  @override
  Future<void> deleteMid(MessageTarget target, int mid) async {
    rows.removeWhere((m) => m.mid == mid);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class Api extends MessageApi {
  Api() : super(Dio());
  final responses = <Completer<List<ChatMessage>>>[];
  @override
  Future<List<ChatMessage>> getHistory(
    MessageTarget target, {
    int? beforeMid,
    int limit = 30,
  }) {
    final response = Completer<List<ChatMessage>>();
    responses.add(response);
    return response.future;
  }
}

class Auth extends AuthController {
  @override
  Future<AuthState> build() async => const AuthState.unauthenticated();
}

class Client implements VoceDioClient {
  Client(this.dio);
  @override
  final Dio dio;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> flush() async {
  for (var i = 0; i < 12; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Cache cache;
  late Api api;
  late ProviderContainer container;

  setUp(() async {
    cache = Cache();
    api = Api();
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              data: options.path == '/api/group'
                  ? [
                      {'gid': 42, 'name': 'Channel'},
                    ]
                  : [],
            ),
          );
        },
      ),
    );
    container = ProviderContainer(
      overrides: [
        messageCacheProvider.overrideWith((ref) async => cache),
        messageApiProvider.overrideWith((ref) => api),
        dioClientProvider.overrideWith((ref) => Client(dio)),
        authControllerProvider.overrideWith(Auth.new),
      ],
    );
    await container.read(authControllerProvider.future);
    await container.read(conversationsProvider.future);
    await flush();
    expect(api.responses, hasLength(1));
  });
  tearDown(() => container.dispose());

  test(
    'successful empty history removes an offline-deleted preview and disk rows',
    () async {
      expect(
        container.read(conversationsProvider).requireValue.single.lastMid,
        20,
      );
      api.responses.single.complete([]);
      await flush();
      final item = container.read(conversationsProvider).requireValue.single;
      expect(item.lastMid, isNull);
      expect(item.lastPreview, isNull);
      expect(cache.rows, isEmpty);
      await Future<void>.delayed(const Duration(milliseconds: 450));
      expect(cache.conversations.single['lastMid'], isNull);
    },
  );

  test('history errors retain the cached preview and text', () async {
    api.responses.single.completeError(
      DioException(requestOptions: RequestOptions()),
    );
    await flush();
    expect(
      container.read(conversationsProvider).requireValue.single.lastMid,
      20,
    );
    expect(cache.rows.single.mid, 20);
  });

  test('a full page of reactions retains the older message preview', () async {
    api.responses.single.complete([
      for (var mid = 60; mid > 40; mid--)
        message(mid).copyWith(
          detail: const MessageDetail.reaction(
            mid: 20,
            detail: {'type': 'like', 'action': '👍'},
          ),
        ),
    ]);
    await flush();
    expect(
      container.read(conversationsProvider).requireValue.single.lastMid,
      20,
    );
    expect(cache.rows.single.mid, 20);
  });

  test('an empty response cannot overwrite a new live preview', () async {
    // A group message does not require auth to resolve the conversation key.
    container
        .read(conversationsProvider.notifier)
        .applyIncomingMessage(message(21));
    await flush();
    api.responses.single.complete([]);
    await flush();
    expect(
      container.read(conversationsProvider).requireValue.single.lastMid,
      21,
    );
  });

  test(
    'an old request cannot restore a preview after cache invalidation',
    () async {
      final oldResponse = api.responses.single;
      cache.conversations = [];
      cache.rows.clear();
      container.invalidate(conversationsProvider);
      await container.read(conversationsProvider.future);
      oldResponse.complete([message(20)]);
      await flush();
      expect(
        container.read(conversationsProvider).requireValue.single.lastMid,
        isNull,
      );
      // Allow delayed enrichment to finish before disposing the container.
      await Future<void>.delayed(const Duration(milliseconds: 60));
      api.responses.last.complete([]);
      await flush();
      expect(
        container.read(conversationsProvider).requireValue.single.lastMid,
        isNull,
      );
    },
  );
}
