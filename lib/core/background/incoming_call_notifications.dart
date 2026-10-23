import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/application/auth_controller.dart';
import '../../features/contacts/application/user_directory_provider.dart';
import '../../features/voice/application/incoming_call_provider.dart';
import '../../features/voice/application/voice_controller.dart';
import '../storage/account_store.dart';
import '../utils/app_log.dart';
import 'background_lifecycle.dart';
import 'background_preferences.dart';

/// The same retained Flutter engine polls invites in foreground/background.
/// Native notifications have a short expiry, refreshed while the invite is
/// verified, so a killed process cannot leave an endless incoming-call alert.
final incomingCallNotificationsProvider = Provider<void>((ref) {
  if (!isAndroidBackgroundSupported) return;
  var disposed = false;
  Future<void> sync() async {
    if (disposed) return;
    final auth = ref.read(authControllerProvider).valueOrNull;
    final session =
        ref.read(accountStoreProvider).valueOrNull?.currentAccountId;
    final call = ref.read(incomingCallProvider);
    final ringing = auth is AuthStateAuthenticated &&
        session != null &&
        call.calling &&
        call.toUid == auth.user.uid &&
        call.fromUid != auth.user.uid &&
        ref.read(voiceControllerProvider) == null &&
        ref.read(androidBackgroundedProvider);
    final name = ringing
        ? (ref.read(userDirectoryProvider).valueOrNull ??
                const <int, UserSummary>{})[call.fromUid]
            ?.name
        : null;
    try {
      await backgroundChannel.invokeMethod('notifyCall', {
        'session': session ?? '',
        'ringing': ringing,
        'target': 'u-${call.fromUid}',
        'title': name ?? '#${call.fromUid}',
      });
    } catch (error) {
      AppLog.w(
          LogTag.voice, () => 'Incoming call notification unavailable: $error');
    }
  }

  void schedule() => Future.microtask(sync);
  ref.listen(authControllerProvider, (_, __) => schedule());
  ref.listen(accountStoreProvider, (_, __) => schedule());
  ref.listen(incomingCallProvider, (_, __) => schedule());
  ref.listen(
      voiceControllerProvider.select((s) => s != null), (_, __) => schedule());
  ref.listen(androidBackgroundedProvider, (_, __) => schedule());
  // Refresh timeout without replaying sound/vibration for the same call.
  final heartbeat =
      Timer.periodic(const Duration(seconds: 10), (_) => schedule());
  schedule();
  ref.onDispose(() {
    disposed = true;
    heartbeat.cancel();
  });
});
