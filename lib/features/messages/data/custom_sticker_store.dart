import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';

const maxStickerBytes = 10 * 1024 * 1024;

enum StickerFailure { tooLarge, unsupported, missing, storage, download }

class StickerException implements Exception {
  const StickerException(this.reason);
  final StickerFailure reason;
}

class CustomSticker {
  const CustomSticker({
    required this.id,
    required this.extension,
    required this.width,
    required this.height,
    required this.size,
  });

  final String id;
  final String extension;
  final int width;
  final int height;
  final int size;
  String get filename => '$id.$extension';
  String get contentType => switch (extension) {
        'jpg' => 'image/jpeg',
        _ => 'image/$extension',
      };

  Map<String, Object> toJson() => {
        'id': id,
        'extension': extension,
        'width': width,
        'height': height,
        'size': size,
      };

  factory CustomSticker.fromJson(Map<String, dynamic> json) {
    final sticker = CustomSticker(
      id: json['id'] as String,
      extension: json['extension'] as String,
      width: json['width'] as int,
      height: json['height'] as int,
      size: json['size'] as int,
    );
    if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(sticker.id) ||
        !const {'png', 'jpg', 'gif', 'webp'}.contains(sticker.extension) ||
        sticker.width <= 0 ||
        sticker.height <= 0 ||
        sticker.size <= 0 ||
        sticker.size > maxStickerBytes) {
      throw const StickerException(StickerFailure.storage);
    }
    return sticker;
  }
}

class StickerMutation {
  const StickerMutation(this.action, this.revision);
  final String action;
  final int revision;
}

class StickerSaveResult {
  const StickerSaveResult(this.sticker, {required this.added});
  final CustomSticker sticker;
  final bool added;
}

/// Owns original image bytes in Documents, independently of the media cache.
/// The account key includes the server identity. Mutations are serialized and
/// the manifest is replaced atomically so failed imports cannot erase a library.
class CustomStickerStore {
  CustomStickerStore(Directory documents, String accountId)
      : directory = Directory(
            '${documents.path}/custom_stickers/${sha256.convert(utf8.encode(accountId))}');

  final Directory directory;
  Future<void> _tail = Future.value();
  List<CustomSticker>? _items;
  Map<String, StickerMutation> _pending = {};
  int _revision = 0;
  File get _manifest => File('${directory.path}/index.json');
  File fileFor(CustomSticker sticker) =>
      File('${directory.path}/${sticker.filename}');

  Future<T> _serial<T>(Future<T> Function() action) {
    final result = _tail.then((_) => action());
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }

  Future<List<CustomSticker>> list() => _serial(() async {
        await _load();
        return List.unmodifiable(_items!);
      });

  Future<void> _load() async {
    if (_items != null) return;
    if (!await _manifest.exists()) {
      _items = [];
      return;
    }
    try {
      final data =
          jsonDecode(await _manifest.readAsString()) as Map<String, dynamic>;
      if (data['version'] != 1 && data['version'] != 2) {
        throw const FormatException();
      }
      if (data['sync_version'] != null && data['sync_version'] != 1) {
        throw const FormatException();
      }
      final items = (data['items'] as List)
          .map((e) => CustomSticker.fromJson(e as Map<String, dynamic>))
          .toList();
      if (items.map((e) => e.id).toSet().length != items.length) {
        throw const FormatException();
      }
      final revision = data['revision'] as int? ?? 0;
      final pending = <String, StickerMutation>{};
      final legacy = data['version'] == 1 && data['sync_version'] != 1;
      if (legacy) {
        // Existing local libraries become uploads on their first cloud sync.
        for (final item in items) {
          pending[item.id] = const StickerMutation('put', 1);
        }
      } else {
        for (final entry in (data['pending'] as Map<String, dynamic>).entries) {
          if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(entry.key)) {
            throw const FormatException();
          }
          final value = entry.value as Map<String, dynamic>;
          final action = value['action'] as String;
          final rev = value['revision'] as int;
          if (!const {'put', 'delete'}.contains(action) ||
              rev < 1 ||
              rev > revision ||
              (action == 'put' && !items.any((e) => e.id == entry.key))) {
            throw const FormatException();
          }
          pending[entry.key] = StickerMutation(action, rev);
        }
      }
      _revision = legacy ? 1 : revision;
      _pending = pending;
      _items = items;
    } catch (_) {
      throw const StickerException(StickerFailure.storage);
    }
  }

  Future<void> _persist(List<CustomSticker> items,
      {Map<String, StickerMutation>? pending, int? revision}) async {
    await directory.create(recursive: true);
    final temporary = File('${_manifest.path}.tmp');
    await temporary.writeAsString(
        jsonEncode({
          // Preserve the existing readable items format for older clients.
          'version': 1,
          'sync_version': 1,
          'revision': revision ?? _revision,
          'pending': (pending ?? _pending).map((id, op) => MapEntry(id, {
                'action': op.action,
                'revision': op.revision,
              })),
          'items': items.map((e) => e.toJson()).toList(),
        }),
        flush: true);
    await temporary.rename(_manifest.path);
    _items = items;
    if (pending != null) _pending = pending;
    if (revision != null) _revision = revision;
  }

  Future<StickerSaveResult> add(Uint8List bytes) => _serial(() async {
        final sticker = await inspectSticker(bytes);
        await _load();
        final existing = _items!.where((e) => e.id == sticker.id).firstOrNull;
        await directory.create(recursive: true);
        final file = fileFor(sticker);
        // Reimport also repairs a missing/damaged copy of an existing entry.
        final temporary = File('${file.path}.tmp');
        await temporary.writeAsBytes(bytes, flush: true);
        await temporary.rename(file.path);
        if (existing != null) return StickerSaveResult(existing, added: false);
        try {
          final rev = _revision + 1;
          await _persist([
            sticker,
            ..._items!
          ], pending: {
            ..._pending,
            sticker.id: StickerMutation('put', rev),
          }, revision: rev);
        } catch (_) {
          await file.delete();
          rethrow;
        }
        return StickerSaveResult(sticker, added: true);
      });

  Future<void> remove(CustomSticker sticker) => _serial(() async {
        await _load();
        final rev = _revision + 1;
        await _persist(_items!.where((e) => e.id != sticker.id).toList(),
            pending: {..._pending, sticker.id: StickerMutation('delete', rev)},
            revision: rev);
        // The manifest is authoritative; a failed cleanup leaves only an orphan.
        try {
          await fileFor(sticker).delete();
        } on FileSystemException {/* absent */}
      });

  /// Local presentation order only. Does not manufacture uploads/deletions or
  /// overwrite new items which arrived while the management list was open.
  Future<void> reorder(List<String> ids) => _serial(() async {
        await _load();
        if (ids.toSet().length != ids.length) {
          throw ArgumentError('Duplicate sticker ids');
        }
        final current = {for (final item in _items!) item.id: item};
        final ordered = <CustomSticker>[
          for (final id in ids)
            if (current.containsKey(id)) current.remove(id)!,
          ...current.values,
        ];
        await _persist(ordered);
      });

  Future<Map<String, StickerMutation>> pending() => _serial(() async {
        await _load();
        return Map.unmodifiable(_pending);
      });

  Future<void> acknowledge(String id, StickerMutation mutation) =>
      _serial(() async {
        await _load();
        if (_pending[id]?.revision != mutation.revision) return;
        await _persist(_items!, pending: {..._pending}..remove(id));
      });

  /// A downloaded copy must not undo an import or deletion made while the
  /// network request was in flight. Original bytes are independently verified.
  Future<void> receive(CustomSticker expected, Uint8List bytes) =>
      _serial(() async {
        await _load();
        if (_pending.containsKey(expected.id)) return;
        final actual = await inspectSticker(bytes);
        if (jsonEncode(actual.toJson()) != jsonEncode(expected.toJson())) {
          throw const StickerException(StickerFailure.download);
        }
        await directory.create(recursive: true);
        final file = fileFor(actual);
        final temporary = File('${file.path}.tmp');
        await temporary.writeAsBytes(bytes, flush: true);
        await temporary.rename(file.path);
        if (!_items!.any((e) => e.id == actual.id)) {
          await _persist([..._items!, actual]);
        }
      });

  Future<void> reconcile(Set<String> remoteIds) => _serial(() async {
        await _load();
        final removed = _items!
            .where(
                (e) => !remoteIds.contains(e.id) && !_pending.containsKey(e.id))
            .toList();
        if (removed.isEmpty) return;
        final ids = removed.map((e) => e.id).toSet();
        await _persist(_items!.where((e) => !ids.contains(e.id)).toList());
        for (final sticker in removed) {
          try {
            await fileFor(sticker).delete();
          } on FileSystemException {/* orphan */}
        }
      });

  Future<Uint8List> read(CustomSticker sticker) => _serial(() async {
        await _load();
        if (!_items!.any((e) => e.id == sticker.id)) {
          throw const StickerException(StickerFailure.missing);
        }
        final file = fileFor(sticker);
        if (!await file.exists() || await file.length() != sticker.size) {
          throw const StickerException(StickerFailure.missing);
        }
        final bytes = await file.readAsBytes();
        if (sha256.convert(bytes).toString() != sticker.id) {
          throw const StickerException(StickerFailure.missing);
        }
        return bytes;
      });
}

Future<CustomSticker> inspectSticker(Uint8List bytes) async {
  if (bytes.length > maxStickerBytes) {
    throw const StickerException(StickerFailure.tooLarge);
  }
  bool starts(List<int> signature, [int offset = 0]) =>
      bytes.length >= offset + signature.length &&
      List.generate(signature.length, (i) => bytes[offset + i] == signature[i])
          .every((match) => match);
  final extension = starts([137, 80, 78, 71, 13, 10, 26, 10])
      ? 'png'
      : starts([255, 216, 255])
          ? 'jpg'
          : starts(ascii.encode('GIF87a')) || starts(ascii.encode('GIF89a'))
              ? 'gif'
              : starts(ascii.encode('RIFF')) && starts(ascii.encode('WEBP'), 8)
                  ? 'webp'
                  : null;
  if (extension == null) {
    throw const StickerException(StickerFailure.unsupported);
  }
  ui.ImmutableBuffer? buffer;
  ui.ImageDescriptor? descriptor;
  ui.Codec? codec;
  try {
    buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    descriptor = await ui.ImageDescriptor.encoded(buffer);
    // Bound decoding memory even for a small compressed file with huge dimensions.
    if (descriptor.width > 16384 ||
        descriptor.height > 16384 ||
        descriptor.width * descriptor.height > 40000000) {
      throw const StickerException(StickerFailure.unsupported);
    }
    codec =
        await descriptor.instantiateCodec(targetWidth: 96, targetHeight: 96);
    final frame = await codec.getNextFrame();
    frame.image.dispose();
    return CustomSticker(
        id: sha256.convert(bytes).toString(),
        extension: extension,
        width: descriptor.width,
        height: descriptor.height,
        size: bytes.length);
  } catch (_) {
    throw const StickerException(StickerFailure.unsupported);
  } finally {
    codec?.dispose();
    descriptor?.dispose();
    buffer?.dispose();
  }
}
