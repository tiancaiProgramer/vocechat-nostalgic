import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../messages/data/message_api.dart';
import '../../messages/data/message_cache.dart';
import '../../messages/domain/message_models.dart';
import 'message_search_filter.dart';

class SearchConversation {
  const SearchConversation(
      {required this.id, required this.name, required this.target});
  final String id;
  final String name;
  final MessageTarget target;
}

class MessageSearchHit {
  const MessageSearchHit(this.conversation, this.message);
  final SearchConversation conversation;
  final ChatMessage message;
}

typedef HistoryLoader = Future<List<ChatMessage>> Function(MessageTarget target,
    {int? beforeMid, required int limit, CancelToken? cancelToken});
typedef MessageSearchFactory = MessageSearchSession Function(String query,
    List<SearchConversation> conversations, CancelToken cancelToken);

final messageSearchFactoryProvider = Provider<MessageSearchFactory>((ref) {
  final api = ref.watch(messageApiProvider);
  final cache = ref.watch(messageCacheProvider.future);
  return (query, conversations, token) => MessageSearchSession(
      query: query,
      conversations: conversations,
      cancelToken: token,
      loadHistory: api.getHistoryForSearch,
      readCache: (target) async => (await cache).read(target));
});

class _History {
  _History(this.conversation);
  final SearchConversation conversation;
  final Map<int, ChatMessage> messages = {};
  int? before;
  bool exhausted = false;
}

/// Searches cached messages first, then contiguous server history pages.
/// Keeps the query and cursors within this account-scoped, cancellable session.
/// No search result is written back into the conversation or sent to the server.
class MessageSearchSession {
  MessageSearchSession(
      {required String query,
      required List<SearchConversation> conversations,
      required this.cancelToken,
      required this.loadHistory,
      required this.readCache,
      this.filters = const MessageSearchFilter(),
      this.pageSize = 100})
      : query = query.trim().toLowerCase(),
        _histories = {for (final c in conversations) c.id: _History(c)};

  final String query;
  final CancelToken cancelToken;
  final HistoryLoader loadHistory;
  final Future<List<ChatMessage>> Function(MessageTarget) readCache;
  final int pageSize;
  MessageSearchFilter filters;
  final Map<String, _History> _histories;
  int lastErrors = 0;
  Iterable<_History> get _activeHistories => _histories.values.where((h) =>
      filters.conversationId == null ||
      h.conversation.id == filters.conversationId);
  bool get hasMore => _activeHistories.any((h) => !h.exhausted);

  void _checkCancelled() {
    if (cancelToken.isCancelled) throw cancelToken.cancelError!;
  }

  void _remember(_History history, List<ChatMessage> rows) {
    for (var message in rows) {
      if (message.mid <= 0) continue;
      final old = history.messages[message.mid];
      if (old != null &&
          old.detail == message.detail &&
          message.editedContent == null) {
        message = message.copyWith(
            editedContent: old.editedContent,
            editedContentType: old.editedContentType);
      }
      history.messages[message.mid] = message;
    }
  }

  Future<void> prime() async {
    final histories = _activeHistories.toList();
    for (var i = 0; i < histories.length; i += 3) {
      _checkCancelled();
      await Future.wait(histories.skip(i).take(3).map((history) async {
        try {
          final rows = await readCache(history.conversation.target);
          _checkCancelled();
          _remember(history, rows);
        } catch (_) {
          _checkCancelled(); // An unavailable cache must not block server search.
        }
      }));
    }
  }

  Future<void> loadMore({void Function()? onProgress}) async {
    lastErrors = 0;
    final histories = _activeHistories.where((h) => !h.exhausted).toList();
    for (var i = 0; i < histories.length; i += 3) {
      _checkCancelled();
      await Future.wait(histories.skip(i).take(3).map((history) async {
        try {
          final rows = await loadHistory(history.conversation.target,
              beforeMid: history.before,
              limit: pageSize,
              cancelToken: cancelToken);
          _checkCancelled();
          final oldest = rows.where((m) => m.mid > 0).fold<int?>(null,
              (value, m) => value == null || m.mid < value ? m.mid : value);
          _remember(history, rows);
          history.exhausted = rows.length < pageSize ||
              oldest == null ||
              (history.before != null && oldest >= history.before!);
          if (oldest != null) history.before = oldest;
        } catch (_) {
          _checkCancelled();
          lastErrors++; // Leave cursor unchanged so retry cannot skip history.
        }
      }));
      _checkCancelled();
      onProgress?.call();
    }
  }

  List<MessageSearchHit> get hits {
    if (query.isEmpty && !filters.isActive) return const [];
    final hits = <MessageSearchHit>[];
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final history in _activeHistories) {
      final visible = Map<int, ChatMessage>.from(history.messages);
      final reactions = history.messages.values
          .where((m) => m.detail is ReactionMessageDetail)
          .toList()
        ..sort((a, b) => a.mid.compareTo(b.mid));
      for (final event in reactions) {
        final reaction = event.detail as ReactionMessageDetail;
        if (reaction.detail['type'] == 'delete') {
          visible.remove(reaction.mid);
        } else if (reaction.detail['type'] == 'edit' &&
            visible[reaction.mid] != null) {
          final text = reaction.detail['content'];
          final contentType = reaction.detail['content_type'];
          if (text is String) {
            visible[reaction.mid] = visible[reaction.mid]!.copyWith(
                editedContent: text,
                editedContentType: contentType is String ? contentType : null);
          }
        }
      }
      for (final message in visible.values) {
        if (message.detail is ReactionMessageDetail ||
            message.isExpiredAt(now)) {
          continue;
        }
        if (messageKind(message) == null ||
            !filters.includes(history.conversation.id, message)) {
          continue;
        }
        if (query.isEmpty ||
            messageSearchText(message).toLowerCase().contains(query)) {
          hits.add(MessageSearchHit(history.conversation, message));
        }
      }
    }
    hits.sort((a, b) {
      final byTime = b.message.createdAt.compareTo(a.message.createdAt);
      return byTime == 0 ? b.message.mid.compareTo(a.message.mid) : byTime;
    });
    return hits;
  }
}
