import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocechat_client/features/messages/domain/message_models.dart';
import 'package:vocechat_client/features/search/data/message_search_filter.dart';
import 'package:vocechat_client/features/search/data/message_search_session.dart';

const a = SearchConversation(
    id: 'u-8', name: 'Alice', target: MessageTarget.user(uid: 8));
const b = SearchConversation(
    id: 'g-42', name: 'Group', target: MessageTarget.group(gid: 42));
ChatMessage row(int mid, String mime,
        {String? name, int sender = 8, DateTime? date}) =>
    ChatMessage(
        mid: mid,
        fromUid: sender,
        createdAt: (date ?? DateTime(2026, 10, 26, 12)).millisecondsSinceEpoch,
        target: a.target,
        detail: MessageDetail.normal(
            contentType: mime.startsWith('text/') ? mime : 'vocechat/file',
            content: mime.startsWith('text/')
                ? 'needle text'
                : '{"path":"private-upload-path"}',
            properties: {
              'content_type': mime,
              if (name != null) 'name': name
            }));

void main() {
  test(
      'media filters distinguish VC file MIME metadata and match only filenames',
      () async {
    final rows = [
      row(1, 'text/plain'),
      row(2, 'image/gif', name: 'Needle.gif'),
      row(3, 'video/mp4', name: 'trip.mp4'),
      row(4, 'application/pdf', name: 'guide.pdf')
    ];
    final session = MessageSearchSession(
        query: '',
        conversations: [a],
        cancelToken: CancelToken(),
        readCache: (_) async => rows,
        loadHistory: (target, {beforeMid, required limit, cancelToken}) async =>
            []);
    await session.prime();
    expect(session.hits, isEmpty);
    for (final entry in {
      SearchMessageKind.images: 2,
      SearchMessageKind.videos: 3,
      SearchMessageKind.files: 4
    }.entries) {
      session.filters = MessageSearchFilter(kind: entry.key);
      expect(session.hits.map((h) => h.message.mid), [entry.value]);
    }
    session.filters = const MessageSearchFilter(kind: SearchMessageKind.all);
    expect(session.hits, hasLength(4));
    final named = MessageSearchSession(
        query: 'needle',
        conversations: [a],
        cancelToken: CancelToken(),
        filters: const MessageSearchFilter(kind: SearchMessageKind.images),
        readCache: (_) async => rows,
        loadHistory: (target, {beforeMid, required limit, cancelToken}) async =>
            []);
    await named.prime();
    expect(named.hits.single.message.mid, 2);
    expect(messageSearchText(rows[2]), 'trip.mp4');
    expect(messageSearchText(row(5, 'image/png')), '');
  });

  test(
      'conversation, sender and inclusive local date filters combine without reading other chats',
      () async {
    final read = <MessageTarget>[];
    final rows = [
      row(1, 'text/plain', date: DateTime(2026, 10, 25, 23, 59)),
      row(2, 'text/plain', date: DateTime(2026, 10, 26)),
      row(3, 'text/plain', date: DateTime(2026, 10, 26, 23, 59, 59)),
      row(4, 'text/plain', date: DateTime(2026, 10, 27)),
      row(5, 'text/plain', sender: 9)
    ];
    final session = MessageSearchSession(
        query: 'needle',
        conversations: [a, b],
        cancelToken: CancelToken(),
        filters: MessageSearchFilter(
            conversationId: a.id,
            senderUid: 8,
            from: DateTime(2026, 10, 26),
            through: DateTime(2026, 10, 26)),
        readCache: (target) async {
          read.add(target);
          return rows;
        },
        loadHistory: (target, {beforeMid, required limit, cancelToken}) async {
          read.add(target);
          return [];
        });
    await session.prime();
    await session.loadMore();
    expect(read, everyElement(a.target));
    expect(session.hits.map((h) => h.message.mid), [3, 2]);
    expect(session.hasMore, isFalse);
  });

  test('filtered media still respects expiry and deletion reactions', () async {
    final expired = row(1, 'image/png', date: DateTime(2000)).copyWith(
        detail: const MessageDetail.normal(
            contentType: 'vocechat/file',
            content: '{}',
            properties: {'content_type': 'image/png', 'name': 'expired.png'},
            expiresIn: 1));
    final deleted = row(2, 'image/gif');
    final deletion = row(3, 'text/plain').copyWith(
        detail:
            const MessageDetail.reaction(mid: 2, detail: {'type': 'delete'}));
    final session = MessageSearchSession(
        query: '',
        conversations: [a],
        cancelToken: CancelToken(),
        filters: const MessageSearchFilter(kind: SearchMessageKind.images),
        readCache: (_) async => [expired, deleted, deletion],
        loadHistory: (target, {beforeMid, required limit, cancelToken}) async =>
            []);
    await session.prime();
    expect(session.hits, isEmpty);
  });
}
