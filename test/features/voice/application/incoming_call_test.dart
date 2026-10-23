import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocechat_client/core/background/background_lifecycle.dart';
import 'package:vocechat_client/features/auth/application/auth_controller.dart';
import 'package:vocechat_client/features/auth/domain/auth_models.dart';
import 'package:vocechat_client/features/messages/domain/message_models.dart';
import 'package:vocechat_client/features/voice/application/incoming_call_provider.dart';
import 'package:vocechat_client/features/voice/application/voice_controller.dart';
import 'package:vocechat_client/features/voice/data/agora_api.dart';
import 'package:vocechat_client/features/voice/domain/voice_models.dart';

class _Auth extends AuthController {
  @override
  Future<AuthState> build() async =>
      const AuthState.authenticated(user: VoceUser(uid: 7, name: 'Me'));
  void signOutForTest() => state = const AsyncData(AuthState.unauthenticated());
}

class _Voice extends VoiceController {
  @override
  VoicingInfo? build() => null;
}

class _Api extends AgoraApi {
  _Api() : super(Dio());
  bool active = true;
  Completer<List<int>>? pending;
  @override
  Future<List<ActiveVoiceChannel>> getActiveChannels(
          {int pageNo = 0, int pageSize = 100}) async =>
      active
          ? [
              const ActiveVoiceChannel(
                  channelName: 'vocechat:dm:7',
                  userCount: 1,
                  context: MessageTarget.user(uid: 7))
            ]
          : [];
  @override
  Future<List<int>> getChannelUsers(String channelName) async =>
      pending == null ? [42] : pending!.future;
}

void main() {
  testWidgets(
      'background discovers within five seconds, clears hangup, and suppresses rejected invite',
      (tester) async {
    final api = _Api();
    final c = ProviderContainer(overrides: [
      authControllerProvider.overrideWith(_Auth.new),
      voiceControllerProvider.overrideWith(_Voice.new),
      agoraApiProvider.overrideWithValue(api)
    ]);
    c.listen(authControllerProvider, (_, __) {}, fireImmediately: true);
    await c.read(authControllerProvider.future);
    c.read(androidBackgroundedProvider.notifier).state = true;
    c.read(incomingCallProvider);
    await tester.pump();
    expect(c.read(incomingCallProvider).calling, true);
    c.read(incomingCallProvider.notifier).dismiss();
    await tester.pump(const Duration(seconds: 5));
    expect(c.read(incomingCallProvider).calling, false);
    api.active = false;
    await tester.pump(const Duration(seconds: 5));
    expect(c.read(incomingCallProvider).fromUid, 0);
    api.active = true;
    await tester.pump(const Duration(seconds: 5));
    expect(c.read(incomingCallProvider).calling, true);
    api.active = false;
    await tester.pump(const Duration(seconds: 5));
    expect(c.read(incomingCallProvider).calling, false);
    c.dispose();
    await tester.pump(const Duration(milliseconds: 1));
  });
  testWidgets('late invite response cannot restore ringing after logout',
      (tester) async {
    final api = _Api()..pending = Completer<List<int>>();
    final c = ProviderContainer(overrides: [
      authControllerProvider.overrideWith(_Auth.new),
      voiceControllerProvider.overrideWith(_Voice.new),
      agoraApiProvider.overrideWithValue(api)
    ]);
    c.listen(authControllerProvider, (_, __) {}, fireImmediately: true);
    await c.read(authControllerProvider.future);
    c.read(incomingCallProvider);
    await tester.pump();
    (c.read(authControllerProvider.notifier) as _Auth).signOutForTest();
    api.pending!.complete([42]);
    await tester.pump();
    expect(c.read(incomingCallProvider).calling, false);
    expect(c.read(incomingCallProvider).fromUid, 0);
    c.dispose();
    await tester.pump(const Duration(milliseconds: 1));
  });
}
