import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/storage/account_store.dart';
import '../../../core/storage/server_store.dart';
import '../../../core/storage/secure_token_store.dart';
import '../data/custom_sticker_store.dart';
import '../data/sticker_sync.dart';

final stickerDocumentsProvider =
    FutureProvider<Directory>((ref) => getApplicationDocumentsDirectory());

final customStickerStoreProvider =
    FutureProvider.family<CustomStickerStore, String>(
  (ref, accountId) async => CustomStickerStore(
      await ref.watch(stickerDocumentsProvider.future), accountId),
);

final customStickersProvider =
    AsyncNotifierProvider.family<CustomStickers, List<CustomSticker>, String>(
        CustomStickers.new);

final stickerSyncStatusProvider =
    StateProvider.family<StickerSyncStatus, String>(
        (ref, accountId) => StickerSyncStatus.local);

class CustomStickers extends FamilyAsyncNotifier<List<CustomSticker>, String> {
  Timer? _timer;
  StickerSync? _sync;
  Future<void>? _running;
  bool _queued = false;
  Object? _generation;

  @override
  Future<List<CustomSticker>> build(String arg) async {
    final generation = Object();
    _generation = generation;
    // Rebuild/dispose the sync connection when the selected identity changes.
    ref.watch(
        accountStoreProvider.select((a) => a.valueOrNull?.currentAccountId));
    ref.onDispose(() {
      _generation = null;
      _timer?.cancel();
      _sync?.dispose();
      _sync = null;
      _running = null;
      _queued = false;
    });
    final store = await ref.watch(customStickerStoreProvider(arg).future);
    final items = await store.list();
    if (_generation == generation) {
      _sync = StickerSync(store, () async {
        if (_generation != generation) return null;
        final accounts = ref.read(accountStoreProvider).valueOrNull;
        if (accounts?.currentAccountId != arg) return null;
        final account =
            accounts!.accounts.where((a) => a.accountId == arg).firstOrNull;
        if (account == null) return null;
        final server = ref
            .read(serverStoreProvider)
            .valueOrNull
            ?.servers
            .where((s) => s.id == account.serverId)
            .firstOrNull;
        if (server == null) return null;
        final tokens =
            await ref.read(secureTokenStoreProvider(arg)).readTokens();
        if (_generation != generation ||
            tokens == null ||
            ref.read(accountStoreProvider).valueOrNull?.currentAccountId !=
                arg) {
          return null;
        }
        return StickerSession(server.baseUrl, account.uid, tokens.accessToken);
      });
      _schedule();
    }
    return items;
  }

  void _schedule() {
    _timer?.cancel();
    if (!_canSync) return;
    _timer = Timer(const Duration(milliseconds: 500), () => unawaited(sync()));
  }

  bool get _canSync {
    final accounts = ref.read(accountStoreProvider).valueOrNull;
    return _generation != null &&
        accounts?.currentAccountId == arg &&
        accounts!.accounts.any((account) => account.accountId == arg);
  }

  Future<void> sync() async {
    if (_running != null) {
      _queued = true;
      return _running;
    }
    if (_sync == null || !_canSync) {
      return;
    }
    final generation = _generation;
    final syncer = _sync!;
    _running = () async {
      ref.read(stickerSyncStatusProvider(arg).notifier).state =
          StickerSyncStatus.syncing;
      final result = await syncer.run();
      if (_generation != generation) return;
      if (result == StickerSyncStatus.local ||
          result == StickerSyncStatus.unavailable) {
        // Discovery did not modify the local library.
        ref.read(stickerSyncStatusProvider(arg).notifier).state = result;
        return;
      }
      // Keep local edits visible even if the network side failed.
      try {
        final items = await syncer.store.list();
        if (_generation != generation) return;
        state = AsyncData(items);
        ref.read(stickerSyncStatusProvider(arg).notifier).state = result;
      } catch (error, stack) {
        if (_generation != generation) return;
        state = AsyncError(error, stack);
        ref.read(stickerSyncStatusProvider(arg).notifier).state =
            StickerSyncStatus.pending;
      }
    }();
    try {
      await _running;
    } finally {
      if (_generation == generation) {
        _running = null;
        if (_queued) {
          _queued = false;
          _schedule();
        }
      }
    }
  }

  Future<StickerSaveResult> add(Uint8List bytes) async {
    await future;
    final store = await ref.read(customStickerStoreProvider(arg).future);
    final result = await store.add(bytes);
    state = AsyncData(await store.list());
    ref.read(stickerSyncStatusProvider(arg).notifier).state =
        StickerSyncStatus.pending;
    _schedule();
    return result;
  }

  Future<void> remove(CustomSticker sticker) async {
    await future;
    final store = await ref.read(customStickerStoreProvider(arg).future);
    await store.remove(sticker);
    state = AsyncData(await store.list());
    ref.read(stickerSyncStatusProvider(arg).notifier).state =
        StickerSyncStatus.pending;
    _schedule();
  }
}
