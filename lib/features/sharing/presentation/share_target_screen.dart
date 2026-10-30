import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/storage/account_store.dart';
import '../../../core/background/background_preferences.dart';
import '../../../core/utils/safe_text.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../legacy_ui/legacy_chrome.dart';
import '../../channels/application/conversation_providers.dart';
import '../application/incoming_share_provider.dart';

class ShareTargetScreen extends ConsumerStatefulWidget {
  const ShareTargetScreen({super.key});
  @override
  ConsumerState<ShareTargetScreen> createState() => _ShareTargetScreenState();
}

class _ShareTargetScreenState extends ConsumerState<ShareTargetScreen> {
  bool _choosing = false;
  bool _leaving = false;

  Future<void> _choose({
    ConversationItem? target,
    bool transfer = false,
  }) async {
    final payload = ref.read(pendingIncomingShareProvider);
    final account =
        ref.read(accountStoreProvider).valueOrNull?.currentAccountId;
    if (_choosing || account == null || payload?.canChoose != true) {
      return;
    }
    setState(() => _choosing = true);
    final shares = ref.read(incomingSharesProvider.notifier);
    try {
      final ready = payload!.prepared
          ? payload
          : await shares.prepare(payload.id, forTransfer: transfer);
      if (!mounted ||
          account !=
              ref.read(accountStoreProvider).valueOrNull?.currentAccountId) {
        await shares.ack(payload.id);
        return;
      }
      if (!ready.prepared || !ready.canChoose) {
        return;
      }
      if (transfer) {
        if (ready.files.isEmpty) return;
        _leaving = true;
        shares.hold(ready.id);
        context.go('/home');
        unawaited(
          context.push<void>(
            '/file-transfer',
            extra: IncomingTransferSelection(account, ready),
          ),
        );
      } else if (target != null) {
        _leaving = true;
        final id = switch (target.key) {
          UserConversationKey(uid: final uid) => 'u-$uid',
          GroupConversationKey(gid: final gid) => 'g-$gid',
        };
        ref.read(selectedIncomingShareProvider.notifier).state =
            IncomingShareSelection(account, id, ready);
        shares.hold(ready.id);
        context.go('/home/chat/$id');
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppL10n.of(context).shareReceiveFailed)),
        );
      }
    } finally {
      if (mounted) setState(() => _choosing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final payload = ref.watch(pendingIncomingShareProvider);
    final conversations = ref.watch(conversationsProvider);
    final shares = ref.read(incomingSharesProvider.notifier);
    void cancel() {
      _leaving = true;
      if (payload != null) {
        unawaited(ref.read(incomingSharesProvider.notifier).ack(payload.id));
      }
      context.go('/home');
    }

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop && payload != null && !_leaving) {
          _leaving = true;
          unawaited(Future<void>.microtask(() => shares.ack(payload.id)));
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              LegacyTitleBar(
                title: l.shareTitle,
                leading: IconButton(
                  tooltip: l.actionCancel,
                  onPressed: cancel,
                  icon: const Icon(Icons.close),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(l.shareChooseTarget),
              ),
              if (payload?.loading == true || _choosing)
                const LinearProgressIndicator(minHeight: 2),
              if (payload?.text.isNotEmpty == true)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Text(
                    safeText(payload!.text),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              if (payload?.files.isNotEmpty == true)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Text(
                    safeText(payload!.files.map((f) => f.name).join(' · ')),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              if (payload?.error.isNotEmpty == true)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    payload!.error == 'too_many'
                        ? l.shareTooMany
                        : l.shareReceiveFailed,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              const Divider(height: 1),
              if (isAndroidBackgroundSupported &&
                  payload?.files.isNotEmpty == true)
                ListTile(
                  leading: const Icon(Icons.wifi_rounded),
                  title: Text(l.localTransferTitle),
                  subtitle: Text(l.shareTransferHint),
                  trailing: const Icon(Icons.chevron_right),
                  enabled: !_choosing && payload?.canChoose == true,
                  onTap: () => _choose(transfer: true),
                ),
              Expanded(
                child: conversations.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, __) => Center(
                    child: TextButton(
                      onPressed: () => ref.invalidate(conversationsProvider),
                      child: Text(l.actionRetry),
                    ),
                  ),
                  data: (items) => items.isEmpty
                      ? Center(child: Text(l.shareNoConversations))
                      : ListView.builder(
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final item = items[index];
                            return ListTile(
                              leading: Icon(
                                item.isChannel
                                    ? Icons.tag
                                    : Icons.person_outline,
                              ),
                              title: Text(safeText(item.name)),
                              trailing: const Icon(Icons.chevron_right),
                              enabled: !_choosing && payload?.canChoose == true,
                              onTap: () => _choose(target: item),
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
