import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/storage/account_store.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/safe_text.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../auth/application/auth_controller.dart';
import '../../channels/application/conversation_providers.dart';
import '../../contacts/application/user_directory_provider.dart';
import '../../messages/domain/message_models.dart';
import '../data/message_search_session.dart';
import 'search_page.dart';

class MessageSearchScreen extends ConsumerStatefulWidget {
  const MessageSearchScreen({super.key});
  @override
  ConsumerState<MessageSearchScreen> createState() =>
      _MessageSearchScreenState();
}

class _MessageSearchScreenState extends ConsumerState<MessageSearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  CancelToken? _token;
  MessageSearchSession? _session;
  List<MessageSearchHit> _results = const [];
  String _query = '';
  bool _busy = false, _failed = false;

  void _publish(MessageSearchSession session) {
    if (mounted && !session.cancelToken.isCancelled) {
      setState(() {
        _results = session.hits;
        _failed = session.lastErrors > 0;
      });
    }
  }

  void _search(String value) {
    _debounce?.cancel();
    _token?.cancel();
    final query = value.trim();
    setState(() {
      _query = query;
      _session = null;
      _results = const [];
      _busy = query.isNotEmpty;
      _failed = false;
    });
    if (query.isEmpty) return;
    final token = _token = CancelToken();
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      try {
        final conversations = await ref.read(conversationsProvider.future);
        if (!mounted || token.isCancelled) return;
        final auth = ref.read(authControllerProvider).valueOrNull;
        final uid = auth is AuthStateAuthenticated ? auth.user.uid : null;
        final targets = conversations
            .where(
                (c) => c.isChannel || (c.key as UserConversationKey).uid != uid)
            .map((c) => SearchConversation(
                  id: c.key is GroupConversationKey
                      ? 'g-${(c.key as GroupConversationKey).gid}'
                      : 'u-${(c.key as UserConversationKey).uid}',
                  name: c.name,
                  target: c.key is GroupConversationKey
                      ? MessageTarget.group(
                          gid: (c.key as GroupConversationKey).gid)
                      : MessageTarget.user(
                          uid: (c.key as UserConversationKey).uid),
                ))
            .toList();
        final session =
            ref.read(messageSearchFactoryProvider)(query, targets, token);
        _session = session;
        await session.prime();
        _publish(session);
        // Look beyond the first page automatically when there are no matches.
        // A visible "search earlier" action continues from these cursors.
        for (var i = 0; i < 3 && session.hasMore; i++) {
          await session.loadMore(onProgress: () => _publish(session));
          _publish(session);
          if (session.hits.isNotEmpty || session.lastErrors > 0) break;
        }
      } catch (_) {
        if (mounted && !token.isCancelled) setState(() => _failed = true);
      } finally {
        if (mounted && !token.isCancelled) setState(() => _busy = false);
      }
    });
  }

  Future<void> _loadMore() async {
    final session = _session;
    if (session == null) {
      _search(_controller.text);
      return;
    }
    if (_busy || session.cancelToken.isCancelled) return;
    setState(() {
      _busy = true;
      _failed = false;
    });
    try {
      await session.loadMore(onProgress: () => _publish(session));
      _publish(session);
    } catch (_) {
      if (mounted && !session.cancelToken.isCancelled) {
        setState(() => _failed = true);
      }
    } finally {
      if (mounted && !session.cancelToken.isCancelled) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _token?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(
        accountStoreProvider.select((s) => s.valueOrNull?.currentAccountId),
        (previous, next) {
      if (previous != null && previous != next) {
        _controller.clear();
        _search('');
        context.go('/home');
      }
    });
    final l = AppL10n.of(context);
    final users = ref.watch(userDirectoryProvider).valueOrNull ?? const {};
    return SearchPage(
      title: l.searchMessagesTitle,
      hint: l.chatSearchHint,
      controller: _controller,
      onChanged: _search,
      child: Column(children: [
        if (_busy) const LinearProgressIndicator(minHeight: 2),
        if (_failed)
          Padding(
              padding: const EdgeInsets.all(12),
              child: Text(l.searchMessagesUnavailable,
                  style: TextStyle(color: AppTokens.gray500, fontSize: 12))),
        Expanded(
            child: _query.isEmpty
                ? Center(
                    child: Text(l.searchMessagesPrompt,
                        style: TextStyle(color: AppTokens.gray500)))
                : ListView.builder(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    itemCount: _results.length + 1,
                    itemBuilder: (context, index) {
                      if (index == _results.length) {
                        return Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(children: [
                              if (!_busy && _results.isEmpty)
                                Text(l.chatSearchEmpty,
                                    style: TextStyle(color: AppTokens.gray500)),
                              if (!_busy &&
                                  (_failed || (_session?.hasMore ?? false)))
                                TextButton(
                                    onPressed: _loadMore,
                                    child: Text(_failed
                                        ? l.actionRetry
                                        : l.searchMessagesMore)),
                              if (!_busy &&
                                  !_failed &&
                                  _session != null &&
                                  !_session!.hasMore &&
                                  _results.isNotEmpty)
                                Text(l.searchMessagesComplete,
                                    style: TextStyle(
                                        color: AppTokens.gray500,
                                        fontSize: 12)),
                            ]));
                      }
                      final hit = _results[index];
                      final message = hit.message;
                      final time =
                          DateTime.fromMillisecondsSinceEpoch(message.createdAt)
                              .toLocal();
                      final stamp = '${time.year}/${time.month}/${time.day} '
                          '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                      final sender = users[message.fromUid]?.name ??
                          l.chatUserFallback(message.fromUid);
                      return ListTile(
                        title: Text(safeText(hit.conversation.name),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(safeText(message.displayContent),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: AppTokens.gray700)),
                              const SizedBox(height: 4),
                              Text('${safeText(sender)} · $stamp',
                                  style: TextStyle(
                                      color: AppTokens.gray500, fontSize: 11)),
                            ]),
                        trailing: const Icon(Icons.chevron_right, size: 20),
                        onTap: () {
                          FocusScope.of(context).unfocus();
                          context.push(
                              '/home/chat/${hit.conversation.id}?mid=${message.mid}');
                        },
                      );
                    },
                  )),
      ]),
    );
  }
}
