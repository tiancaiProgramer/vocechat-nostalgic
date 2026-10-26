import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/storage/account_store.dart';
import '../../../core/utils/safe_text.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../legacy_ui/legacy_chrome.dart';
import '../../channels/application/conversation_providers.dart';
import '../application/incoming_share_provider.dart';

class ShareTargetScreen extends ConsumerWidget {
  const ShareTargetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final payload = ref.watch(pendingIncomingShareProvider);
    final conversations = ref.watch(conversationsProvider);
    void cancel() {
      if (payload != null) {
        unawaited(ref.read(incomingSharesProvider.notifier).ack(payload.id));
      }
      context.go('/home');
    }

    return PopScope(
        onPopInvokedWithResult: (didPop, _) {
          if (didPop && payload != null) {
            unawaited(
                ref.read(incomingSharesProvider.notifier).ack(payload.id));
          }
        },
        child: Scaffold(
            body: SafeArea(
                child: Column(children: [
          LegacyTitleBar(
              title: l.shareTitle,
              leading: IconButton(
                  tooltip: l.actionCancel,
                  onPressed: cancel,
                  icon: const Icon(Icons.close))),
          Padding(
              padding: const EdgeInsets.all(12),
              child: Text(l.shareChooseTarget)),
          if (payload?.loading == true)
            const LinearProgressIndicator(minHeight: 2),
          if (payload?.text.isNotEmpty == true)
            Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(safeText(payload!.text),
                    maxLines: 3, overflow: TextOverflow.ellipsis)),
          if (payload?.files.isNotEmpty == true)
            Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                    safeText(payload!.files.map((f) => f.name).join(' · ')),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis)),
          if (payload?.error.isNotEmpty == true)
            Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                    payload!.error == 'too_large'
                        ? l.shareTooLarge
                        : l.shareReceiveFailed,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error))),
          const Divider(height: 1),
          Expanded(
              child: conversations.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => Center(
                child: TextButton(
                    onPressed: () => ref.invalidate(conversationsProvider),
                    child: Text(l.actionRetry))),
            data: (items) => items.isEmpty
                ? Center(child: Text(l.shareNoConversations))
                : ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return ListTile(
                        leading: Icon(
                            item.isChannel ? Icons.tag : Icons.person_outline),
                        title: Text(safeText(item.name)),
                        trailing: const Icon(Icons.chevron_right),
                        enabled: payload?.hasContent == true &&
                            payload?.loading != true,
                        onTap: () {
                          final account = ref
                              .read(accountStoreProvider)
                              .valueOrNull
                              ?.currentAccountId;
                          if (account == null ||
                              payload == null ||
                              !payload.hasContent ||
                              payload.loading) {
                            return;
                          }
                          final id = switch (item.key) {
                            UserConversationKey(uid: final uid) => 'u-$uid',
                            GroupConversationKey(gid: final gid) => 'g-$gid',
                          };
                          ref
                                  .read(selectedIncomingShareProvider.notifier)
                                  .state =
                              IncomingShareSelection(account, id, payload);
                          ref
                              .read(incomingSharesProvider.notifier)
                              .hold(payload.id);
                          context.go('/home/chat/$id');
                        },
                      );
                    },
                  ),
          )),
        ]))));
  }
}
