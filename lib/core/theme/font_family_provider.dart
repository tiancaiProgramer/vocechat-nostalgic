import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../storage/preference_write.dart';

enum AppFontFamily { system, bundled }

const _fontFamilyKey = 'app.fontFamily';

final fontFamilyProvider =
    NotifierProvider<FontFamilyNotifier, AppFontFamily>(FontFamilyNotifier.new);

class FontFamilyNotifier extends Notifier<AppFontFamily> {
  bool _changed = false;
  bool _disposed = false;
  Future<void> _write = Future.value();

  @override
  AppFontFamily build() {
    ref.onDispose(() => _disposed = true);
    _load();
    return AppFontFamily.system;
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.get(_fontFamilyKey);
      if (!_disposed && !_changed && saved == AppFontFamily.bundled.name) {
        state = AppFontFamily.bundled;
      }
    } catch (_) {
      // The system font remains usable without local storage.
    }
  }

  /// Apply immediately; queue commits so rapid changes keep the last choice.
  Future<void> select(AppFontFamily value) {
    _changed = true;
    state = value;
    final write = _write.catchError((_) {}).then((_) async {
      final prefs = await SharedPreferences.getInstance();
      await requirePreferenceWrite(
        prefs,
        value == AppFontFamily.system
            ? prefs.remove(_fontFamilyKey)
            : prefs.setString(_fontFamilyKey, value.name),
      );
    });
    _write = write;
    return write;
  }
}
