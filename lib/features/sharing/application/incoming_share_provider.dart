import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/account_store.dart';
import '../../../core/utils/safe_text.dart';

class SharedFile {
  const SharedFile(this.path, this.name, this.mime, this.size);
  final String path, name, mime;
  final int size;
}

class IncomingShare {
  const IncomingShare({
    required this.id,
    required this.text,
    required this.files,
    this.prepared = true,
    this.loading = false,
    this.error = '',
  });
  final String id, text, error;
  final List<SharedFile> files;
  final bool loading, prepared;
  bool get hasContent => text.trim().isNotEmpty || files.isNotEmpty;
  bool get canChoose => !loading && hasContent && error.isEmpty;

  factory IncomingShare.fromMap(Map<dynamic, dynamic> data) {
    final id = data['id'] as String;
    final text = safeText(data['text'] as String? ?? '');
    if (!RegExp(r'^[A-Za-z0-9-]{1,80}$').hasMatch(id) ||
        text.length > 1000000) {
      throw const FormatException('Invalid share');
    }
    final files = <SharedFile>[];
    final prepared = data['prepared'] != false;
    var total = 0;
    for (final raw in data['files'] as List? ?? const []) {
      final row = raw as Map;
      final size = (row['size'] as num).toInt();
      final name = row['name'] as String;
      final path = row['path'] as String;
      total += size;
      if (size < 0 ||
          (prepared && size == 0) ||
          size > (1 << 40) ||
          total > (1 << 40) ||
          files.length >= 16 ||
          name.isEmpty ||
          (prepared && path.isEmpty)) {
        throw const FormatException('Invalid shared files');
      }
      files.add(SharedFile(path, name, row['mime'] as String? ?? '', size));
    }
    return IncomingShare(
      id: id,
      text: text,
      files: List.unmodifiable(files),
      prepared: prepared,
      loading: data['loading'] == true,
      error: data['error'] as String? ?? '',
    );
  }
}

class IncomingShareSelection {
  const IncomingShareSelection(this.accountId, this.chatId, this.payload);
  final String accountId, chatId;
  final IncomingShare payload;
}

class IncomingTransferSelection {
  const IncomingTransferSelection(this.accountId, this.payload);
  final String accountId;
  final IncomingShare payload;
}

final incomingShareChannelProvider = Provider(
  (ref) => const MethodChannel('vocechat/incoming_share'),
);
final incomingShareSupportedProvider = Provider(
  (ref) => !kIsWeb && defaultTargetPlatform == TargetPlatform.android,
);
final selectedIncomingShareProvider = StateProvider<IncomingShareSelection?>(
  (ref) => null,
);
final incomingSharesProvider =
    NotifierProvider<IncomingShares, List<IncomingShare>>(IncomingShares.new);
final pendingIncomingShareProvider = Provider<IncomingShare?>(
  (ref) => ref.watch(incomingSharesProvider).firstOrNull,
);
Object? _channelOwner;

class IncomingShares extends Notifier<List<IncomingShare>> {
  final _held = <String>{};
  bool _disposed = false;
  int _readRevision = 0;
  Future<void>? _reading;

  @override
  List<IncomingShare> build() {
    final owner = Object();
    final channel = ref.read(incomingShareChannelProvider);
    final supported = ref.read(incomingShareSupportedProvider);
    if (supported) {
      _channelOwner = owner;
      channel.setMethodCallHandler((call) async {
        if (!_disposed &&
            identical(_channelOwner, owner) &&
            call.method == 'available') {
          await refresh();
        }
      });
      unawaited(Future<void>.microtask(refresh));
    }
    ref.listen(
      accountStoreProvider.select((s) => s.valueOrNull?.currentAccountId),
      (before, next) {
        if (before != null && before != next) {
          final selection = ref.read(selectedIncomingShareProvider);
          if (selection != null) {
            ref.read(selectedIncomingShareProvider.notifier).state = null;
            unawaited(ack(selection.payload.id));
          }
        }
      },
    );
    ref.onDispose(() {
      _disposed = true;
      if (supported && identical(_channelOwner, owner)) {
        _channelOwner = null;
        channel.setMethodCallHandler(null);
      }
    });
    return const [];
  }

  Future<void> refresh() {
    if (_disposed) return Future.value();
    return _reading ??= _refresh().whenComplete(() => _reading = null);
  }

  Future<void> _refresh() async {
    final revision = ++_readRevision;
    try {
      final rows = await ref
          .read(incomingShareChannelProvider)
          .invokeListMethod<dynamic>('pending');
      if (_disposed || revision != _readRevision) return;
      state = (rows ?? const [])
          .map((r) => IncomingShare.fromMap(r as Map))
          .where((r) => !_held.contains(r.id))
          .toList();
    } on MissingPluginException {
      // Unsupported platforms and unit tests have no Android bridge.
    } catch (_) {
      // A transient bridge failure must not erase an already received share.
    }
  }

  void hold(String id) {
    if (_disposed) {
      return;
    }
    _held.add(id);
    state = state.where((p) => p.id != id).toList();
  }

  Future<IncomingShare> prepare(String id, {required bool forTransfer}) async {
    final packet = await ref
        .read(incomingShareChannelProvider)
        .invokeMapMethod<dynamic, dynamic>('prepare', {
      'id': id,
      'mode': forTransfer ? 'transfer' : 'chat',
    });
    if (packet == null || _disposed || _held.contains(id)) {
      throw const FormatException('Share is no longer available');
    }
    final share = IncomingShare.fromMap(packet);
    if (share.id != id) throw const FormatException('Unexpected share');
    state = [
      for (final item in state)
        if (item.id == id) share else item,
    ];
    return share;
  }

  Future<void> ack(String id) async {
    if (_disposed) {
      return;
    }
    hold(id);
    try {
      await ref.read(incomingShareChannelProvider).invokeMethod<void>('ack', {
        'id': id,
      });
    } catch (_) {
      // Native imports also have a TTL cleanup.
    }
  }
}
