import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/storage/account_store.dart';
import '../../../core/storage/server_store.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/safe_text.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/voce_avatar.dart';
import '../../contacts/application/contacts_provider.dart';
import '../../contacts/application/user_directory_provider.dart';
import '../data/contact_search_api.dart';
import 'search_page.dart';

class ContactSearchScreen extends ConsumerStatefulWidget {
  const ContactSearchScreen({super.key});
  @override
  ConsumerState<ContactSearchScreen> createState() =>
      _ContactSearchScreenState();
}

class _ContactSearchScreenState extends ConsumerState<ContactSearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  CancelToken? _token;
  ContactInfo? _remote;
  String _query = '';
  bool _busy = false, _failed = false, _disabled = false;

  void _search(String value) {
    _debounce?.cancel();
    _token?.cancel();
    final query = value.trim();
    setState(() {
      _query = query;
      _remote = null;
      _busy = query.isNotEmpty;
      _failed = _disabled = false;
    });
    if (query.isEmpty) return;
    final token = _token = CancelToken();
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      try {
        final result =
            await ref.read(contactSearchApiProvider).search(query, token);
        if (!mounted || token.isCancelled) return;
        setState(() => _remote = result);
      } on DioException catch (error) {
        if (!mounted || token.isCancelled) return;
        setState(() {
          _disabled = error.response?.statusCode == 403;
          _failed = !_disabled;
        });
      } catch (_) {
        if (mounted && !token.isCancelled) setState(() => _failed = true);
      } finally {
        if (mounted && !token.isCancelled) setState(() => _busy = false);
      }
    });
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
    final contacts = ref.watch(contactsProvider);
    final users = ref.watch(userDirectoryProvider).valueOrNull ?? const {};
    final byId = <int, ContactInfo>{
      for (final u in users.values)
        u.uid: ContactInfo(uid: u.uid, name: u.name),
      for (final c in contacts.valueOrNull ?? const <ContactInfo>[]) c.uid: c,
      if (_remote != null) _remote!.uid: _remote!,
    };
    final results = byId.values
        .where((c) => c.matchesQuery(_query) || c.uid == _remote?.uid)
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    final servers = ref.watch(serverStoreProvider).valueOrNull;
    final base = servers?.servers
        .where((s) => s.id == servers.currentServerId)
        .firstOrNull
        ?.baseUrl;
    return SearchPage(
      title: l.searchPeopleTitle,
      hint: l.searchPeopleHint,
      controller: _controller,
      onChanged: _search,
      child: Column(children: [
        if (_busy || (contacts.isLoading && results.isEmpty))
          const LinearProgressIndicator(minHeight: 2),
        if (_disabled || _failed)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              Expanded(
                  child: Text(
                      _disabled
                          ? l.searchPeopleDisabled
                          : l.searchPeopleUnavailable,
                      style:
                          TextStyle(color: AppTokens.gray500, fontSize: 12))),
              if (_failed)
                TextButton(
                    onPressed: () => _search(_controller.text),
                    child: Text(l.actionRetry)),
            ]),
          ),
        Expanded(
            child: results.isEmpty
                ? Center(
                    child: Text(_busy ? l.contactsLoading : l.searchPeopleEmpty,
                        style: TextStyle(color: AppTokens.gray500)))
                : ListView.separated(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    itemCount: results.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: .5, indent: 68),
                    itemBuilder: (context, index) {
                      final contact = results[index];
                      return ListTile(
                        leading: VoceAvatar(
                            name: contact.name,
                            size: 40,
                            imageUrl: base == null
                                ? null
                                : '$base/api/resource/avatar?uid=${contact.uid}'),
                        title: Text(safeText(contact.name),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(
                            contact.email.isEmpty
                                ? 'ID: ${contact.uid}'
                                : '${safeText(contact.email)} · ID: ${contact.uid}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          FocusScope.of(context).unfocus();
                          context.push('/home/chat/u-${contact.uid}',
                              extra: {'chatName': contact.name});
                        },
                      );
                    },
                  )),
      ]),
    );
  }
}
