import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/storage/preference_write.dart';

class ChatDraft {
  const ChatDraft(this.text, this.mentions, this.updatedAt);
  final String text;
  final List<int> mentions;
  final int updatedAt;
}

final draftSaveFailedProvider =
    StateProvider.family<bool, String>((ref, id) => false);
final chatDraftsProvider =
    AsyncNotifierProvider.family<ChatDrafts, Map<String, ChatDraft>, String>(
        ChatDrafts.new);

/// Account-scoped text drafts. The notifier owns pending disk writes so leaving
/// a chat cannot cancel the last edit. Attachments stay explicitly staged.
class ChatDrafts extends FamilyAsyncNotifier<Map<String, ChatDraft>, String> {
  SharedPreferences? _preferences;
  Map<String, ChatDraft> _entries = {};
  Future<void> _writes = Future.value();
  Timer? _timer;
  bool _disposed = false;
  bool _loaded = false;
  int _revision = 0;
  int _queuedRevision = 0;

  String get _key => 'voce_drafts_${sha256.convert(utf8.encode(arg))}';

  @override
  Future<Map<String, ChatDraft>> build(String arg) async {
    ref.onDispose(() {
      _disposed = true;
      _timer?.cancel();
      // Use the owned snapshot, never ref/state after disposal.
      if (_loaded) unawaited(_persist());
    });
    _preferences = await SharedPreferences.getInstance();
    final raw = _preferences!.getString(_key);
    if (raw != null) {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      if (data['version'] != 1) {
        throw const FormatException('Unknown draft format');
      }
      final rows = data['items'] as Map<String, dynamic>;
      _entries = rows.map((key, value) {
        if (!RegExp(r'^[ug]-\d+$').hasMatch(key)) {
          throw const FormatException('Invalid draft target');
        }
        final row = value as Map<String, dynamic>;
        return MapEntry(
            key,
            ChatDraft(
                row['text'] as String,
                (row['mentions'] as List).cast<int>(),
                row['updated_at'] as int));
      });
    }
    _loaded = true;
    return Map.unmodifiable(_entries);
  }

  Future<void> setDraft(String target, String text, List<int> mentions) async {
    if (!_loaded) await future;
    if (_disposed) return;
    if (!RegExp(r'^[ug]-\d+$').hasMatch(target)) {
      throw ArgumentError.value(target);
    }
    final previous = _entries[target];
    final cleanMentions = mentions.where((id) => id > 0).toSet().toList();
    if (previous?.text == text &&
        jsonEncode(previous?.mentions) == jsonEncode(cleanMentions)) {
      return;
    }
    _entries = {..._entries};
    if (text.isEmpty) {
      _entries.remove(target);
    } else {
      _entries[target] = ChatDraft(text, List.unmodifiable(cleanMentions),
          DateTime.now().millisecondsSinceEpoch);
    }
    state = AsyncData(Map.unmodifiable(_entries));
    _revision++;
    _timer?.cancel();
    _timer =
        Timer(const Duration(milliseconds: 350), () => unawaited(_persist()));
  }

  Future<void> flush() async {
    _timer?.cancel();
    if (_loaded) await _persist();
  }

  Future<void> _persist() {
    final prefs = _preferences;
    if (prefs == null || !_loaded) return Future.value();
    if (_revision == _queuedRevision) return _writes;
    final revision = _queuedRevision = _revision;
    final json = jsonEncode({
      'version': 1,
      'items': _entries.map((key, draft) => MapEntry(key, {
            'text': draft.text,
            'mentions': draft.mentions,
            'updated_at': draft.updatedAt,
          }))
    });
    final key = _key;
    _writes = _writes.then((_) async {
      try {
        await requirePreferenceWrite(prefs, prefs.setString(key, json));
        if (!_disposed) {
          ref.read(draftSaveFailedProvider(arg).notifier).state = false;
        }
      } catch (_) {
        if (_queuedRevision == revision) _queuedRevision = -1;
        if (!_disposed) {
          ref.read(draftSaveFailedProvider(arg).notifier).state = true;
        }
      }
    });
    return _writes;
  }
}
