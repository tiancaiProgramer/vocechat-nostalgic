import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocechat_client/core/network/sse_client.dart';
import 'package:vocechat_client/features/channels/application/conversation_providers.dart';
import 'package:vocechat_client/features/messages/application/message_dispatcher.dart';
import 'package:vocechat_client/features/messages/application/chat_controller.dart';
import 'package:vocechat_client/features/messages/application/reactions_provider.dart';
import 'package:vocechat_client/features/messages/data/message_cache.dart';
import 'package:vocechat_client/features/messages/domain/message_models.dart';

class _Cache implements MessageCache {
  final firstWrite = Completer<void>();
  final writes = <({int mid, bool advance})>[];
  final clears = <int>[];
  final marked = <int>[];

  @override
  void markMessagesCleared(int throughMid) => marked.add(throughMid);

  @override
  Future<void> clearMessagesThrough(int throughMid) async =>
      clears.add(throughMid);

  @override
  Future<void> appendOne(MessageTarget target, ChatMessage msg,
      {bool advanceCursor = false}) async {
    writes.add((mid: msg.mid, advance: advanceCursor));
    if (writes.length == 1) await firstWrite.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Conversations extends Conversations {
  @override
  Future<List<ConversationItem>> build() async => [];
  @override
  void applyIncomingMessage(ChatMessage msg) {}
}

class _Chat extends ChatController {
  int builds = 0;
  @override
  Future<List<ChatMessage>> build(MessageTarget target) async {
    builds++;
    return [];
  }
}

ChatEvent _message(int mid) => ChatEvent.chat(
      message: ChatMessage(
        mid: mid,
        fromUid: 2,
        createdAt: 1000,
        target: const MessageTarget.group(gid: 42),
        detail: const MessageDetail.normal(
            contentType: 'text/plain', content: 'message'),
      ),
    );

Future<void> _flush() async {
  for (var i = 0; i < 10; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'disk failures cannot let later messages acknowledge a missing gap',
    () async {
      final events = StreamController<ChatEvent>.broadcast();
      final cache = _Cache();
      final container = ProviderContainer(overrides: [
        sseEventsProvider.overrideWith((ref) => events.stream),
        messageCacheProvider.overrideWith((ref) async => cache),
        conversationsProvider.overrideWith(_Conversations.new),
      ]);
      addTearDown(container.dispose);
      addTearDown(events.close);
      await container.read(messageCacheProvider.future);
      container.read(messageDispatcherProvider);
      events.add(const ChatEvent.connectionOpened());
      events.add(_message(101));
      events.add(_message(102));
      await _flush();
      expect(cache.writes, [(mid: 101, advance: true)]);
      cache.firstWrite
          .completeError(StateError('disk temporarily unavailable'));
      await _flush();
      expect(cache.writes.last, (mid: 102, advance: false));
      // A new stream replays the missing row before advancing again.
      events.add(const ChatEvent.connectionOpened());
      events.add(_message(101));
      events.add(_message(102));
      await _flush();
      expect(cache.writes.skip(2),
          [(mid: 101, advance: true), (mid: 102, advance: true)]);
    },
  );

  test(
    'clear runs in stream order without restarting active chat controllers',
    () async {
      final events = StreamController<ChatEvent>.broadcast();
      final cache = _Cache();
      final chat = _Chat();
      const target = MessageTarget.group(gid: 42);
      final container = ProviderContainer(
        overrides: [
          sseEventsProvider.overrideWith((ref) => events.stream),
          messageCacheProvider.overrideWith((ref) async => cache),
          conversationsProvider.overrideWith(_Conversations.new),
          chatControllerProvider(target).overrideWith(() => chat),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(events.close);
      await container.read(messageCacheProvider.future);
      container.listen(chatControllerProvider(target), (_, __) {});
      await container.read(chatControllerProvider(target).future);
      container.read(messageDispatcherProvider);
      container
          .read(reactionsProvider.notifier)
          .applyLike(reactionMid: 99, targetMid: 98, fromUid: 2, emoji: '👍');

      events.add(_message(100));
      events.add(
        parseSseEvent('message_cleared', '{"latest_deleted_mid":100}'),
      );
      events.add(_message(101));
      await _flush();
      expect(cache.marked, [100]);
      expect(cache.clears, isEmpty, reason: 'wait for the earlier write');
      expect(cache.writes, [(mid: 100, advance: true)]);
      cache.firstWrite.complete();
      await _flush();
      expect(cache.clears, [100]);
      expect(cache.writes.last, (mid: 101, advance: true));
      expect(chat.builds, 1);
      expect(container.read(reactionsProvider), isEmpty);
      expect(
        container.exists(
          chatControllerProvider(const MessageTarget.group(gid: 999)),
        ),
        isFalse,
      );
    },
  );
}
