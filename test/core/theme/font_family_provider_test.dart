import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:vocechat_client/core/storage/preference_write.dart';
import 'package:vocechat_client/core/theme/font_family_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> load() async {
    await SharedPreferences.getInstance();
    await Future<void>.delayed(Duration.zero);
  }

  ProviderContainer container() {
    final result = ProviderContainer();
    addTearDown(result.dispose);
    return result;
  }

  test('defaults to system, restores bundled, and persists a reset', () async {
    final first = container();
    expect(first.read(fontFamilyProvider), AppFontFamily.system);
    await first.read(fontFamilyProvider.notifier).select(AppFontFamily.bundled);
    final second = container();
    second.read(fontFamilyProvider);
    await load();
    expect(second.read(fontFamilyProvider), AppFontFamily.bundled);
    await second.read(fontFamilyProvider.notifier).select(AppFontFamily.system);
    final third = container();
    third.read(fontFamilyProvider);
    await load();
    expect(third.read(fontFamilyProvider), AppFontFamily.system);
    expect(
        (await SharedPreferences.getInstance()).containsKey('app.fontFamily'),
        isFalse);
  });

  for (final invalid in ['unknown', 1, true]) {
    test('invalid saved value $invalid falls back to system', () async {
      SharedPreferences.setMockInitialValues({'app.fontFamily': invalid});
      final c = container();
      c.read(fontFamilyProvider);
      await load();
      expect(c.read(fontFamilyProvider), AppFontFamily.system);
    });
  }

  test('late loading cannot undo a new system selection', () async {
    SharedPreferences.setMockInitialValues({'app.fontFamily': 'bundled'});
    final c = container();
    final write =
        c.read(fontFamilyProvider.notifier).select(AppFontFamily.system);
    await load();
    await write;
    expect(c.read(fontFamilyProvider), AppFontFamily.system);
  });

  test('rapid selections leave the last choice on disk', () async {
    final notifier = container().read(fontFamilyProvider.notifier);
    await Future.wait([
      notifier.select(AppFontFamily.bundled),
      notifier.select(AppFontFamily.system),
      notifier.select(AppFontFamily.bundled),
    ]);
    expect((await SharedPreferences.getInstance()).getString('app.fontFamily'),
        'bundled');
  });

  test('failed writes report an error and can be retried', () async {
    final disk = _FailingPreferences();
    SharedPreferencesStorePlatform.instance = disk;
    addTearDown(() => SharedPreferences.setMockInitialValues({}));
    final notifier = container().read(fontFamilyProvider.notifier);
    await expectLater(notifier.select(AppFontFamily.bundled),
        throwsA(isA<PreferenceWriteException>()));
    disk.fail = false;
    await notifier.select(AppFontFamily.bundled);
    expect(disk.values['flutter.app.fontFamily'], 'bundled');
  });
}

class _FailingPreferences extends SharedPreferencesStorePlatform {
  final values = <String, Object>{};
  bool fail = true;
  @override
  Future<Map<String, Object>> getAll() async => Map.of(values);
  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    if (fail) return false;
    values[key] = value;
    return true;
  }

  @override
  Future<bool> remove(String key) async {
    if (fail) return false;
    values.remove(key);
    return true;
  }

  @override
  Future<bool> clear() async {
    values.clear();
    return true;
  }
}
