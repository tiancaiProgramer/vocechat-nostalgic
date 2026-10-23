import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/storage/account_store.dart';
import '../../../shared/widgets/voce_dialog.dart';
import '../application/custom_stickers_provider.dart';
import '../data/custom_sticker_store.dart';
import '../data/sticker_sync.dart';
import 'sticker_feedback.dart';

import '../../../l10n/generated/app_localizations.dart';

const _emojis = [
  '😀',
  '😃',
  '😄',
  '😁',
  '😆',
  '😅',
  '😂',
  '🤣',
  '😊',
  '🥰',
  '😍',
  '😘',
  '😎',
  '🤩',
  '🥳',
  '🙂',
  '😉',
  '🙃',
  '😋',
  '😛',
  '🤪',
  '🤗',
  '🤭',
  '🫣',
  '🤔',
  '🫡',
  '🤫',
  '😐',
  '🙄',
  '😏',
  '😴',
  '🤤',
  '😢',
  '😭',
  '🥹',
  '🥺',
  '😤',
  '😡',
  '🤯',
  '😱',
  '😨',
  '😳',
  '🫠',
  '🤒',
  '🤕',
  '🤢',
  '🤮',
  '😷',
  '👍',
  '👎',
  '👏',
  '🙌',
  '🤝',
  '🙏',
  '💪',
  '✌️',
  '👌',
  '🤞',
  '👋',
  '🫶',
  '❤️',
  '🧡',
  '💛',
  '💚',
  '💙',
  '💜',
  '🖤',
  '🤍',
  '💔',
  '💕',
  '💯',
  '🔥',
  '✨',
  '⭐',
  '🌟',
  '🎉',
  '🎊',
  '🎁',
  '🏆',
  '🥇',
  '🎂',
  '🍰',
  '☕',
  '🍵',
  '🍻',
  '🥂',
  '🍕',
  '🍔',
  '🐶',
  '🐱',
  '🐼',
  '🐻',
  '🐰',
  '🦊',
  '🌹',
  '🌻',
  '🌈',
  '☀️',
  '🌙',
  '⚡',
  '🚀',
  '🎯',
  '✅',
  '❌',
];

sealed class ComposerEmojiSelection {
  const ComposerEmojiSelection();
}

class TextEmojiSelection extends ComposerEmojiSelection {
  const TextEmojiSelection(this.emoji);
  final String emoji;
}

class StickerEmojiSelection extends ComposerEmojiSelection {
  const StickerEmojiSelection(this.sticker);
  final CustomSticker sticker;
}

const _lastSavedTabKey = 'voce_composer_saved_tab';

Future<ComposerEmojiSelection?> showComposerEmojiPicker(BuildContext context,
    {String? accountId}) async {
  SharedPreferences? preferences;
  try {
    preferences = await SharedPreferences.getInstance();
  } catch (_) {
    // A preference read failure must not prevent opening the emoji panel.
  }
  if (!context.mounted) return null;
  final prefs = preferences;
  return showModalBottomSheet<ComposerEmojiSelection>(
    context: context,
    showDragHandle: true,
    constraints: const BoxConstraints(maxWidth: 440),
    builder: (sheetContext) => ComposerEmojiPicker(
      accountId: accountId,
      initialSavedTab: prefs?.getBool(_lastSavedTabKey) ?? false,
      onTabChanged: (saved) => prefs?.setBool(_lastSavedTabKey, saved).ignore(),
      onSelected: (emoji) =>
          Navigator.of(sheetContext).pop(TextEmojiSelection(emoji)),
      onStickerSelected: (sticker) =>
          Navigator.of(sheetContext).pop(StickerEmojiSelection(sticker)),
    ),
  );
}

class ComposerEmojiPicker extends ConsumerStatefulWidget {
  const ComposerEmojiPicker(
      {super.key,
      required this.onSelected,
      this.accountId,
      this.initialSavedTab = false,
      this.onTabChanged,
      this.onStickerSelected});

  final ValueChanged<String> onSelected;
  final String? accountId;
  final bool initialSavedTab;
  final ValueChanged<bool>? onTabChanged;
  final ValueChanged<CustomSticker>? onStickerSelected;

  @override
  ConsumerState<ComposerEmojiPicker> createState() =>
      _ComposerEmojiPickerState();
}

class _ComposerEmojiPickerState extends ConsumerState<ComposerEmojiPicker> {
  bool _savedTab = false;
  bool _managing = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _savedTab = widget.accountId != null && widget.initialSavedTab;
  }

  void _selectTab(bool saved) {
    setState(() {
      _savedTab = saved;
      _managing = false;
    });
    widget.onTabChanged?.call(saved);
    if (saved) {
      ref.read(customStickersProvider(widget.accountId!).notifier).sync();
    }
  }

  bool get _isCurrentAccount =>
      widget.accountId ==
      ref.read(accountStoreProvider).valueOrNull?.currentAccountId;

  void _feedback(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _import() async {
    if (_busy || !_isCurrentAccount) return;
    final l = AppL10n.of(context);
    setState(() => _busy = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['png', 'jpg', 'jpeg', 'gif', 'webp'],
        allowMultiple: true,
        allowCompression: false,
        withData: false,
      );
      if (!mounted || !_isCurrentAccount || result == null) return;
      var added = 0;
      var duplicates = 0;
      var failed = 0;
      Object? lastError;
      for (final picked in result.files) {
        if (!mounted || !_isCurrentAccount) break;
        try {
          if (picked.size > maxStickerBytes) {
            throw const StickerException(StickerFailure.tooLarge);
          }
          final bytes = picked.bytes ??
              (picked.path == null
                  ? null
                  : await _readPickedFile(picked.path!));
          if (bytes == null) {
            throw const StickerException(StickerFailure.missing);
          }
          final saved = await ref
              .read(customStickersProvider(widget.accountId!).notifier)
              .add(bytes);
          if (saved.added) {
            added++;
          } else {
            duplicates++;
          }
        } catch (error) {
          failed++;
          lastError = error;
        }
      }
      if (!mounted || !_isCurrentAccount) return;
      _feedback(result.files.length == 1 && lastError != null
          ? stickerErrorLabel(l, lastError)
          : l.stickerImportSummary(added, duplicates, failed));
    } catch (error) {
      if (mounted && _isCurrentAccount) _feedback(stickerErrorLabel(l, error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<Uint8List> _readPickedFile(String path) async {
    final file = File(path);
    if (await file.length() > maxStickerBytes) {
      throw const StickerException(StickerFailure.tooLarge);
    }
    return file.readAsBytes();
  }

  Future<void> _remove(CustomSticker sticker) async {
    if (_busy || !_isCurrentAccount) return;
    final l = AppL10n.of(context);
    final confirmed = await showVoceConfirm(
        context: context,
        title: l.stickerRemoveTitle,
        body: l.stickerRemoveBody,
        confirmLabel: l.chatActionDelete,
        cancelLabel: l.actionCancel,
        danger: true);
    if (!mounted || confirmed != true || !_isCurrentAccount) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(customStickersProvider(widget.accountId!).notifier)
          .remove(sticker);
    } catch (error) {
      if (mounted) _feedback(stickerErrorLabel(l, error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Keep the account state alive while a native picker is open.
    ref.watch(accountStoreProvider);
    final l = AppL10n.of(context);
    return SafeArea(
        top: false,
        child: SizedBox(
            height: 360,
            child: Column(children: [
              Padding(
                  padding: const EdgeInsets.only(left: 8, right: 4),
                  child: Row(children: [
                    Expanded(
                        child: TextButton(
                            onPressed: () => _selectTab(false),
                            style: TextButton.styleFrom(
                                foregroundColor: _savedTab
                                    ? Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant
                                    : null),
                            child: Text(l.chatEmoji,
                                maxLines: 1, overflow: TextOverflow.ellipsis))),
                    if (widget.accountId != null)
                      Expanded(
                          child: TextButton(
                              onPressed: () => _selectTab(true),
                              style: TextButton.styleFrom(
                                  foregroundColor: !_savedTab
                                      ? Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant
                                      : null),
                              child: Text(l.stickerFavorites,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis))),
                    IconButton(
                        tooltip: l.actionClose,
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close)),
                  ])),
              Expanded(
                  child: _savedTab
                      ? _buildSaved(l)
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: 48),
                          itemCount: _emojis.length,
                          itemBuilder: (context, index) {
                            final emoji = _emojis[index];
                            return Semantics(
                                button: true,
                                label: emoji,
                                child: InkWell(
                                    borderRadius: BorderRadius.circular(8),
                                    onTap: () => widget.onSelected(emoji),
                                    child: Center(
                                        child: Text(emoji,
                                            style: const TextStyle(
                                                fontSize: 26)))));
                          })),
            ])));
  }

  Widget _buildSaved(AppL10n l) {
    final accountId = widget.accountId!;
    final stickers = ref.watch(customStickersProvider(accountId));
    final syncStatus = ref.watch(stickerSyncStatusProvider(accountId));
    final syncLabel = switch (syncStatus) {
      StickerSyncStatus.local => l.stickerSyncLocal,
      StickerSyncStatus.syncing => l.stickerSyncing,
      StickerSyncStatus.synced => l.stickerSynced,
      StickerSyncStatus.pending => l.stickerSyncPending,
      StickerSyncStatus.unavailable => l.stickerSyncUnavailable,
    };
    final store = ref.watch(customStickerStoreProvider(accountId)).valueOrNull;
    return Column(children: [
      Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(children: [
            Expanded(
                child: Align(
                    alignment: Alignment.centerLeft,
                    child: !_managing
                        ? const SizedBox.shrink()
                        : TextButton.icon(
                            onPressed: _busy ? null : _import,
                            icon: _busy
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2))
                                : const Icon(Icons.add),
                            label: Text(l.stickerImport,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis)))),
            IconButton(
                tooltip: syncLabel,
                onPressed: syncStatus == StickerSyncStatus.syncing
                    ? null
                    : () => ref
                        .read(customStickersProvider(accountId).notifier)
                        .sync(),
                icon: _StickerCloudStatus(status: syncStatus)),
            TextButton(
                onPressed:
                    _busy ? null : () => setState(() => _managing = !_managing),
                child: Text(_managing ? l.stickerDone : l.stickerManage)),
          ])),
      Expanded(
          child: stickers.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(stickerErrorLabel(l, error)),
          TextButton(
              onPressed: () =>
                  ref.invalidate(customStickersProvider(accountId)),
              child: Text(l.actionRetry)),
        ])),
        data: (items) => items.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.emoji_emotions_outlined, size: 38),
                  const SizedBox(height: 10),
                  Text(l.stickerEmpty),
                ])))
            : GridView.builder(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 90,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final sticker = items[index];
                  return Semantics(
                      button: true,
                      label: _managing ? l.chatActionDelete : l.stickerSend,
                      child: InkWell(
                          key: ValueKey('sticker-${sticker.id}'),
                          borderRadius: BorderRadius.circular(8),
                          onTap: _busy
                              ? null
                              : () {
                                  if (_managing) {
                                    _remove(sticker);
                                  } else if (_isCurrentAccount) {
                                    widget.onStickerSelected?.call(sticker);
                                  }
                                },
                          onLongPress: _busy ? null : () => _remove(sticker),
                          child: Stack(fit: StackFit.expand, children: [
                            Padding(
                                padding: const EdgeInsets.all(6),
                                child: store == null
                                    ? const SizedBox.shrink()
                                    : Image.file(store.fileFor(sticker),
                                        fit: BoxFit.contain,
                                        cacheWidth: 192,
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(
                                                Icons.broken_image_outlined))),
                            if (_managing)
                              const Positioned(
                                  right: 0,
                                  top: 0,
                                  child: Icon(Icons.remove_circle,
                                      color: Colors.red, size: 22)),
                          ])));
                }),
      )),
    ]);
  }
}

class _StickerCloudStatus extends StatelessWidget {
  const _StickerCloudStatus({required this.status});
  final StickerSyncStatus status;

  @override
  Widget build(BuildContext context) => switch (status) {
        StickerSyncStatus.synced => const Icon(Icons.cloud_done_outlined),
        StickerSyncStatus.pending => const Icon(Icons.cloud_upload_outlined),
        StickerSyncStatus.syncing => const SizedBox(
            width: 24,
            height: 24,
            child: Stack(alignment: Alignment.center, children: [
              Icon(Icons.cloud_outlined),
              Positioned(
                  top: 10,
                  child: SizedBox(
                      width: 9,
                      height: 9,
                      child: CircularProgressIndicator(strokeWidth: 1.3))),
            ])),
        StickerSyncStatus.local ||
        StickerSyncStatus.unavailable =>
          const SizedBox(
              width: 24,
              height: 24,
              child: Stack(alignment: Alignment.center, children: [
                Icon(Icons.cloud_outlined),
                Positioned(
                    top: 9, child: Icon(Icons.priority_high_rounded, size: 12)),
              ])),
      };
}
