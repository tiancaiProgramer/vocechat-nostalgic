import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocechat_client/core/background/background_lifecycle.dart';
import 'package:vocechat_client/core/background/background_preferences.dart';
import 'package:vocechat_client/core/background/incoming_call_notifications.dart';
import 'package:vocechat_client/core/storage/account_store.dart';
import 'package:vocechat_client/features/auth/application/auth_controller.dart';
import 'package:vocechat_client/features/auth/domain/auth_models.dart';
import 'package:vocechat_client/features/contacts/application/user_directory_provider.dart';
import 'package:vocechat_client/features/voice/application/incoming_call_provider.dart';
import 'package:vocechat_client/features/voice/application/voice_controller.dart';
import 'package:vocechat_client/features/voice/domain/voice_models.dart';

class _Auth extends AuthController {
  @override
  Future<AuthState> build() async =>
      const AuthState.authenticated(user: VoceUser(uid: 7, name: 'Me'));
}

class _Accounts extends AccountStore {
  @override
  Future<AccountState> build() async =>
      const AccountState(currentAccountId: 'server::7');
}

class _Voice extends VoiceController {
  @override
  VoicingInfo? build() => null;
}

class _Incoming extends IncomingCall {
  @override
  IncomingCallState build() =>
      const IncomingCallState(fromUid: 42, toUid: 7, calling: true);
}

class _Directory extends UserDirectory {
  @override
  Future<Map<int, UserSummary>> build() async =>
      {42: const UserSummary(uid: 42, name: 'Caller')};
}

void main() {
  testWidgets(
      'background invite notifies, refreshes, and hangup/foreground cancel',
      (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final sent = <Map<dynamic, dynamic>>[];
    tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(backgroundChannel, (call) async {
      if (call.method == 'notifyCall')
        sent.add(call.arguments as Map<dynamic, dynamic>);
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(backgroundChannel, null));
    final c = ProviderContainer(overrides: [
      authControllerProvider.overrideWith(_Auth.new),
      accountStoreProvider.overrideWith(_Accounts.new),
      voiceControllerProvider.overrideWith(_Voice.new),
      incomingCallProvider.overrideWith(_Incoming.new),
      userDirectoryProvider.overrideWith(_Directory.new),
    ]);
    addTearDown(c.dispose);
    await c.read(authControllerProvider.future);
    await c.read(accountStoreProvider.future);
    await c.read(userDirectoryProvider.future);
    c.read(incomingCallNotificationsProvider);
    await tester.pump();
    expect(sent.last['ringing'], false);
    c.read(androidBackgroundedProvider.notifier).state = true;
    await tester.pump();
    expect(sent.last, containsPair('ringing', true));
    expect(sent.last['target'], 'u-42');
    expect(sent.last['title'], 'Caller');
    expect(sent.last['session'], 'server::7');
    final count = sent.length;
    await tester.pump(const Duration(seconds: 10));
    expect(sent.length, greaterThan(count));
    c.read(incomingCallProvider.notifier).clear();
    await tester.pump();
    expect(sent.last['ringing'], false);
    c
        .read(incomingCallProvider.notifier)
        .set(fromUid: 42, toUid: 7, calling: true);
    await tester.pump();
    expect(sent.last['ringing'], true);
    c.read(androidBackgroundedProvider.notifier).state = false;
    await tester.pump();
    expect(sent.last['ringing'], false);
    c.dispose();
    await tester.pump();
    debugDefaultTargetPlatformOverride = null;
  });
}
