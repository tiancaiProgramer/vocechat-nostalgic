import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/notifications/fcm_service.dart';
import '../../../core/notifications/fcm_token_sync.dart';
import '../../../core/startup/app_startup.dart';
import '../../../core/background/background_preferences.dart';
import '../../../features/auth/application/auth_controller.dart';
import '../../../l10n/generated/app_localizations.dart';

class FcmStatusTile extends ConsumerWidget {
  const FcmStatusTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final ready = ref.watch(firebaseInitializedProvider);
    final failed = ref.watch(firebaseInitializationFailedProvider);
    final phase = ref.watch(fcmPhaseProvider);
    final auth = ref.watch(authControllerProvider);
    final preferences = ref.watch(backgroundPreferencesProvider).valueOrNull;
    final fcmMode = preferences?.enabled == false;
    final signedIn = auth.valueOrNull is AuthStateAuthenticated;
    final text =
        preferences?.enabled == true && preferences?.pushEnabled == true
            ? (phase == FcmPhase.unavailable
                ? l.fcmUnregisterFailed
                : phase == FcmPhase.standby
                    ? l.fcmStandby
                    : l.fcmDisconnecting)
            : !ready
                ? (failed ? l.fcmUnavailable : l.fcmConnecting)
                : !signedIn
                    ? l.fcmSignInRequired
                    : switch (phase) {
                        FcmPhase.connecting => l.fcmConnecting,
                        FcmPhase.registered => l.fcmRegistered,
                        FcmPhase.standby => l.fcmStandby,
                        FcmPhase.disabled => l.fcmDisabled,
                        FcmPhase.unavailable => l.fcmUnavailable,
                      };
    return ListTile(
      key: const Key('fcm-status'),
      contentPadding: EdgeInsets.zero,
      leading: Icon(ready &&
              signedIn &&
              (phase == FcmPhase.registered || phase == FcmPhase.standby)
          ? Icons.cloud_done_outlined
          : Icons.cloud_outlined),
      title: Text(l.fcmStatusTitle),
      subtitle: Text(fcmMode ? '$text\n${l.fcmSettingsNotice}' : text),
      trailing: IconButton(
        tooltip: l.actionRetry,
        icon: const Icon(Icons.refresh),
        onPressed: () {
          if (!ready) ref.invalidate(appStartupProvider);
          ref.read(fcmRetryProvider.notifier).state++;
        },
      ),
    );
  }
}
