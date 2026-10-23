import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vocechat_client/core/storage/login_device_id.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
      'the login device survives a new provider scope and stays independent of the shared flutter device',
      () async {
    final first = ProviderContainer();
    final id = await first.read(loginDeviceIdProvider.future);
    expect(id, startsWith('vocechat-legacy-'));
    expect(id.length, lessThanOrEqualTo(64));
    expect(id, isNot('flutter'));
    first.dispose();

    final restarted = ProviderContainer();
    addTearDown(restarted.dispose);
    expect(await restarted.read(loginDeviceIdProvider.future), id);
  });

  test('separate installations do not share a login device', () async {
    final first = ProviderContainer();
    final id = await first.read(loginDeviceIdProvider.future);
    first.dispose();
    SharedPreferences.setMockInitialValues({});
    final other = ProviderContainer();
    addTearDown(other.dispose);
    expect(await other.read(loginDeviceIdProvider.future), isNot(id));
  });

  test('simultaneous login requests use the same persisted device', () async {
    final scope = ProviderContainer();
    addTearDown(scope.dispose);
    final results = await Future.wait(List.generate(
      8,
      (_) => scope.read(loginDeviceIdProvider.future),
    ));
    expect(results.toSet(), hasLength(1));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('legacy_login_device_id_v1'), results.first);
  });
}
