import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocechat_client/features/contacts/application/contacts_provider.dart';
import 'package:vocechat_client/features/messages/data/message_api.dart';
import 'package:vocechat_client/features/messages/domain/message_models.dart';
import 'package:vocechat_client/features/search/data/contact_search_api.dart';
import 'package:vocechat_client/features/search/data/message_search_session.dart';

class _Adapter implements HttpClientAdapter {
  _Adapter(this.handler);
  final Future<ResponseBody> Function(RequestOptions) handler;
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? data,
          Future<void>? cancel) =>
      handler(options);
  @override
  void close({bool force = false}) {}
}

ResponseBody _reply(Object? body, [int status = 200]) =>
    ResponseBody.fromString(jsonEncode(body), status, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType]
    });
const _target = MessageTarget.user(uid: 8);
const _conversation = SearchConversation(
    id: 'u-8', name: 'Unrelated chat title', target: _target);
ChatMessage _message(int mid, String text,
        {MessageDetail? detail, int? time}) =>
    ChatMessage(
        mid: mid,
        fromUid: 8,
        createdAt: time ?? 10000 + mid,
        target: _target,
        detail: detail ??
            MessageDetail.normal(contentType: 'text/plain', content: text));

void main() {
  test(
      'contact matching supports partial names, account email and exact numeric ID',
      () {
    const person =
        ContactInfo(uid: 123, name: 'Alice 张', email: 'Alice@Example.test');
    for (final q in ['alice', ' 张 ', 'EXAMPLE.test', '123', '#123']) {
      expect(person.matchesQuery(q), isTrue, reason: q);
    }
    expect(person.matchesQuery('12'), isFalse);
  });

  test('user lookup uses the real POST contract and name/email/id types',
      () async {
    final requests = <RequestOptions>[];
    final dio = Dio()
      ..httpClientAdapter = _Adapter((request) async {
        requests.add(request);
        return _reply(
            {'uid': 8, 'name': 'Alice', 'email': 'alice@example.test'});
      });
    final api = ContactSearchApi(dio);
    for (final q in [' Alice ', 'alice@example.test', '#8']) {
      expect((await api.search(q, CancelToken()))!.uid, 8);
    }
    expect(requests.map((r) => r.method), everyElement('POST'));
    expect(requests.map((r) => r.path), everyElement('/api/user/search'));
    expect(requests.map((r) => r.data['search_type']), ['name', 'email', 'id']);
    expect(requests.last.data['keyword'], '8');
  });

  test(
      'missing user is empty, permission errors and cancellation stay distinguishable',
      () async {
    final dio = Dio()
      ..httpClientAdapter = _Adapter((_) async => _reply({}, 404));
    expect(
        await ContactSearchApi(dio).search('missing', CancelToken()), isNull);
    dio.httpClientAdapter = _Adapter((_) async => _reply({}, 403));
    await expectLater(ContactSearchApi(dio).search('denied', CancelToken()),
        throwsA(isA<DioException>()));
    final token = CancelToken()..cancel();
    await expectLater(ContactSearchApi(dio).search('Alice', token),
        throwsA(isA<DioException>()));
  });

  test(
      'history search reaches older pages, deduplicates cache and handles reply/markdown text',
      () async {
    final cursors = <int?>[];
    final session = MessageSearchSession(
        query: ' NEEDLE ',
        conversations: [_conversation],
        cancelToken: CancelToken(),
        pageSize: 2,
        readCache: (_) async => [_message(4, 'cached needle')],
        loadHistory: (target, {beforeMid, required limit, cancelToken}) async {
          cursors.add(beforeMid);
          if (beforeMid == null) {
            return [_message(4, 'cached needle'), _message(3, 'ordinary')];
          }
          if (beforeMid == 3) {
            return [
              _message(2, '',
                  detail: const MessageDetail.reply(
                      mid: 9,
                      contentType: 'text/markdown',
                      content: '**Needle** reply')),
              _message(1, 'older needle')
            ];
          }
          return [];
        });
    await session.prime();
    expect(session.hits.map((h) => h.message.mid), [4]);
    await session.loadMore();
    await session.loadMore();
    await session.loadMore();
    expect(cursors, [null, 3, 1]);
    expect(session.hits.map((h) => h.message.mid), [4, 2, 1]);
    expect(session.hasMore, isFalse);
  });

  test(
      'search uses edited text and excludes deleted, expired and reaction rows',
      () async {
    final rows = [
      _message(1, 'old text'),
      _message(2, 'needle deleted'),
      _message(3, '',
          detail: const MessageDetail.reaction(mid: 1, detail: {
            'type': 'edit',
            'content': 'needle edited',
            'content_type': 'text/plain'
          })),
      _message(4, '',
          detail:
              const MessageDetail.reaction(mid: 2, detail: {'type': 'delete'})),
      _message(5, '',
          time: 1,
          detail: const MessageDetail.normal(
              contentType: 'text/plain',
              content: 'needle expired',
              expiresIn: 1)),
      _message(6, '',
          detail: const MessageDetail.normal(
              contentType: 'vocechat/file', content: 'needle')),
    ];
    final session = MessageSearchSession(
        query: 'needle',
        conversations: [_conversation],
        cancelToken: CancelToken(),
        readCache: (_) async => rows,
        loadHistory: (target, {beforeMid, required limit, cancelToken}) async =>
            []);
    await session.prime();
    expect(session.hits.map((h) => h.message.mid), [1]);
    expect(session.hits.single.message.displayContent, 'needle edited');
  });

  test('network failures retain cache and retry without advancing the cursor',
      () async {
    var attempts = 0;
    final session = MessageSearchSession(
        query: 'needle',
        conversations: [_conversation],
        cancelToken: CancelToken(),
        readCache: (_) async => [_message(1, 'needle')],
        loadHistory: (target, {beforeMid, required limit, cancelToken}) async {
          expect(beforeMid, isNull);
          if (attempts++ == 0) throw StateError('offline');
          return [];
        });
    await session.prime();
    await session.loadMore();
    expect(session.lastErrors, 1);
    expect(session.hasMore, isTrue);
    expect(session.hits, hasLength(1));
    await session.loadMore();
    expect(session.lastErrors, 0);
    expect(session.hasMore, isFalse);
  });

  test(
      'late history response cannot be merged after query/account cancellation',
      () async {
    final pending = Completer<List<ChatMessage>>();
    final token = CancelToken();
    final session = MessageSearchSession(
        query: 'secret',
        conversations: [_conversation],
        cancelToken: token,
        readCache: (_) async => [],
        loadHistory: (target, {beforeMid, required limit, cancelToken}) =>
            pending.future);
    final run = session.loadMore();
    final assertion = expectLater(run, throwsA(isA<DioException>()));
    token.cancel();
    pending.complete([_message(1, 'secret')]);
    await assertion;
    expect(session.hits, isEmpty);
  });

  test('non-advancing server pages end the search rather than looping forever',
      () async {
    final session = MessageSearchSession(
        query: 'needle',
        conversations: [_conversation],
        cancelToken: CancelToken(),
        pageSize: 1,
        readCache: (_) async => [],
        loadHistory: (target, {beforeMid, required limit, cancelToken}) async =>
            [_message(1, 'needle')]);
    await session.loadMore();
    await session.loadMore();
    expect(session.hasMore, isFalse);
    expect(session.hits, hasLength(1));
  });

  test(
      'history request carries cancellation and before cursor without sending any messages',
      () async {
    RequestOptions? observed;
    final dio = Dio()
      ..httpClientAdapter = _Adapter((r) async {
        observed = r;
        return _reply([]);
      });
    final token = CancelToken();
    await MessageApi(dio)
        .getHistoryForSearch(_target, beforeMid: 80, limit: 100, cancelToken: token);
    expect(observed!.method, 'GET');
    expect(observed!.path, '/api/user/8/history');
    expect(observed!.queryParameters, {'limit': 100, 'before': 80});
    expect(observed!.cancelToken, same(token));
  });
}
