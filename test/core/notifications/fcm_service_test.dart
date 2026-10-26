import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocechat_client/core/background/background_preferences.dart';
import 'package:vocechat_client/core/notifications/fcm_service.dart';
import 'package:vocechat_client/core/notifications/fcm_token_sync.dart';
import 'package:vocechat_client/core/startup/app_startup.dart';
import 'package:vocechat_client/core/storage/account_store.dart';
import 'package:vocechat_client/features/auth/application/auth_controller.dart';
import 'package:vocechat_client/features/auth/data/auth_api.dart';
import 'package:vocechat_client/features/auth/domain/auth_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('background mode removes FCM registration even before Firebase init',
      () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(backgroundChannel, (_) async => null);
    addTearDown(() {
      debugDefaultTargetPlatformOverride = null;
      messenger.setMockMethodCallHandler(backgroundChannel, null);
    });
    final api = _TokenApi();
    final container = ProviderContainer(overrides: [
      authControllerProvider.overrideWith(_SignedIn.new),
      accountStoreProvider.overrideWith(_Accounts.new),
      backgroundPreferencesProvider.overrideWith(_Background.new),
      firebaseInitializedProvider.overrideWith((ref) => false),
      authApiProvider.overrideWithValue(api),
    ]);
    addTearDown(container.dispose);
    container.listen(authControllerProvider, (_, __) {});
    container.listen(accountStoreProvider, (_, __) {});
    await container.read(authControllerProvider.future);
    await container.read(accountStoreProvider.future);
    await container.read(backgroundPreferencesProvider.future);
    container.listen(fcmServiceProvider, (_, __) {});
    await api.updated.future;
    await Future<void>.delayed(Duration.zero);
    expect(api.tokens, [null]);
    expect(container.read(fcmPhaseProvider), FcmPhase.standby);
  });
  test('push tap requires matching login server and recipient', () {
    expect(
        fcmBelongsToAccount(
            {'vocechat_server_id': 'one', 'vocechat_to_uid': '7'}, 'one::7'),
        isTrue);
    expect(
        fcmBelongsToAccount(
            {'vocechat_server_id': 'one', 'vocechat_to_uid': 7}, 'one::7'),
        isTrue);
    expect(
        fcmBelongsToAccount(
            {'vocechat_server_id': 'two', 'vocechat_to_uid': '7'}, 'one::7'),
        isFalse);
    expect(
        fcmBelongsToAccount(
            {'vocechat_server_id': 'one', 'vocechat_to_uid': '8'}, 'one::7'),
        isFalse);
    expect(
        fcmBelongsToAccount(
            {'vocechat_server_id': 'one', 'vocechat_to_gid': '3'}, 'one::7'),
        isTrue);
    expect(fcmBelongsToAccount({}, 'one::7'), isFalse);
    expect(fcmBelongsToAccount({'vocechat_server_id': 'one'}, null), isFalse);
  });
  test('FCM handles numeric and string chat IDs', () {
    expect(parseFcmChatTarget({'vocechat_to_gid': '12'}), 'g-12');
    expect(parseFcmChatTarget({'vocechat_from_uid': 3}), 'u-3');
  });
  test('malformed notification data is ignored without throwing', () {
    for (final value in [null, '', 'bad', '-1', -1, 1.5, true, [], {}]) {
      expect(parseFcmChatTarget({'vocechat_to_gid': value}), isNull);
      expect(parseFcmChatTarget({'vocechat_from_uid': value}), isNull);
    }
    expect(parseFcmChatTarget({}), isNull);
    // An invalid group must not accidentally navigate to its sender's DM.
    expect(
        parseFcmChatTarget({'vocechat_to_gid': null, 'vocechat_from_uid': '3'}),
        isNull);
  });
}

class _TokenApi extends AuthApi {
  _TokenApi() : super(Dio());
  final tokens = <String?>[];
  final updated = Completer<void>();
  @override
  Future<void> updateDeviceToken(String? token,
      {CancelToken? cancelToken}) async {
    tokens.add(token);
    if (!updated.isCompleted) updated.complete();
  }
}

class _SignedIn extends AuthController {
  @override
  Future<AuthState> build() async =>
      const AuthState.authenticated(user: VoceUser(uid: 7, name: 'User'));
}

class _Accounts extends AccountStore {
  @override
  Future<AccountState> build() async =>
      const AccountState(currentAccountId: 'server::7');
}

class _Background extends BackgroundPreferences {
  @override
  Future<BackgroundStatus> build() async =>
      const BackgroundStatus(enabled: true);
}
