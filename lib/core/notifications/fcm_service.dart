import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/data/auth_api.dart';
import '../storage/account_store.dart';
import '../utils/app_log.dart';
import '../startup/app_startup.dart';
import '../background/background_preferences.dart';
import '../background/background_lifecycle.dart';
import 'fcm_token_sync.dart';

part 'fcm_service.g.dart';

// ---------------------------------------------------------------------------
// Pending chat navigation target
// ---------------------------------------------------------------------------

/// Set when the user taps a FCM notification. Format: `u-<uid>` for DMs,
/// `g-<gid>` for channels — matches GoRouter's `/home/chat/:id` parameter.
/// The router redirect reads and clears this on each evaluation.
final fcmPendingChatTargetProvider = StateProvider<String?>((ref) => null);
final fcmPhaseProvider = StateProvider<FcmPhase>((ref) => FcmPhase.connecting);
final fcmRetryProvider = StateProvider<int>((ref) => 0);

/// Official payloads contain the login server ID, not organization_server_id.
/// Never apply an old server/user's notification to the currently open chat.
@visibleForTesting
bool fcmBelongsToAccount(Map<String, dynamic> data, String? accountId) {
  if (accountId == null) return false;
  final separator = accountId.lastIndexOf('::');
  if (separator <= 0 ||
      data['vocechat_server_id'] != accountId.substring(0, separator)) {
    return false;
  }
  final recipient = data['vocechat_to_uid'];
  return recipient == null ||
      recipient.toString() == accountId.substring(separator + 2);
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

bool get _isMobile =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

/// True only once [Firebase.initializeApp] has actually succeeded (see
/// main.dart, which swallows init failures so a CI build without real
/// credentials — or the checked-in firebase_options.dart placeholders —
/// doesn't crash the app). Every entry point into FirebaseMessaging must
/// check this first, since the plugin throws if no app was initialized.
bool get _firebaseReady => Firebase.apps.isNotEmpty;

void _diagnostic(String reason, {int? status}) {
  if (!isAndroidBackgroundSupported) return;
  unawaited(backgroundChannel.invokeMethod('fcmDiagnostic', {
    'reason': reason,
    if (status != null) 'status': status,
  }).catchError((Object _) {}));
}

void _tokenFailure(Object error) {
  final message = error.toString();
  const known = [
    'SERVICE_NOT_AVAILABLE',
    'AUTHENTICATION_FAILED',
    'API_KEY_ANDROID_APP_BLOCKED',
    'API_KEY_INVALID',
    'FIS_AUTH_ERROR',
    'INSTALLATIONS_AUTH_ERROR',
    'PERMISSION_DENIED'
  ];
  _diagnostic(known.firstWhere(message.contains, orElse: () => 'token_failed'));
}

/// Returns the FCM device token, or an empty string on non-mobile / failure.
/// Applies a 3-second timeout to avoid blocking login on slow Play Services.
Future<String> getFcmDeviceToken() async {
  if (!_isMobile || !_firebaseReady) return '';
  try {
    final completer = Completer<String>();
    FirebaseMessaging.instance.getToken().then((t) {
      if (t?.isNotEmpty == true) _diagnostic('token_ready');
      if (!completer.isCompleted) completer.complete(t ?? '');
    }).catchError((Object error) {
      _tokenFailure(error);
      if (!completer.isCompleted) completer.complete('');
    });
    return await completer.future.timeout(
      const Duration(seconds: 3),
      onTimeout: () {
        _diagnostic('token_timeout');
        return '';
      },
    );
  } catch (error) {
    _tokenFailure(error);
    return '';
  }
}

@visibleForTesting
String? parseFcmChatTarget(Map<String, dynamic> data) {
  int? id(Object? value) {
    final parsed = value is int
        ? value
        : value is String
            ? int.tryParse(value)
            : null;
    return parsed != null && parsed >= 0 ? parsed : null;
  }

  if (data.containsKey('vocechat_to_gid')) {
    final gid = id(data['vocechat_to_gid']);
    if (gid != null) return 'g-$gid';
  } else if (data.containsKey('vocechat_from_uid')) {
    final uid = id(data['vocechat_from_uid']);
    if (uid != null) return 'u-$uid';
  }
  return null;
}

// ---------------------------------------------------------------------------
// FcmService provider
// ---------------------------------------------------------------------------

/// Initialises Firebase Messaging on Android/iOS and wires up notification
/// tap handlers. keepAlive ensures listeners are never torn down for the app's
/// lifetime. No-op on all other platforms.
@Riverpod(keepAlive: true)
Future<void> fcmService(Ref ref) async {
  if (!_isMobile) return;
  final ready = ref.watch(firebaseInitializedProvider) && _firebaseReady;
  // Removing a server-side registration does not require a working Firebase
  // SDK. Android's background/off selections must work even if init failed.
  if (!ready && !isAndroidBackgroundSupported) return;
  var disposed = false;
  var receivedWarmTap = false;
  RemoteMessage? pendingTap;
  void deliver(RemoteMessage message) {
    if (disposed) return;
    pendingTap = message;
    if (ref.read(authControllerProvider).isLoading ||
        ref.read(authControllerProvider).valueOrNull
            is! AuthStateAuthenticated) {
      return;
    }
    pendingTap = null;
    if (!fcmBelongsToAccount(message.data,
        ref.read(accountStoreProvider).valueOrNull?.currentAccountId)) {
      return;
    }
    final target = parseFcmChatTarget(message.data);
    if (target != null) {
      ref.read(fcmPendingChatTargetProvider.notifier).state = target;
    }
  }

  final sync = FcmTokenSync(
      getToken: getFcmDeviceToken,
      upload: (token, cancel) => ref
          .read(authApiProvider)
          .updateDeviceToken(token, cancelToken: cancel),
      onFailure: (error) {
        if (error is DioException) {
          _diagnostic('registration_failed',
              status: error.response?.statusCode);
        }
      },
      onPhase: (phase) {
        if (disposed) return;
        ref.read(fcmPhaseProvider.notifier).state = phase;
        if (isAndroidBackgroundSupported) {
          unawaited(backgroundChannel.invokeMethod(
              'fcmState', {'phase': phase.name}).catchError((Object _) {}));
        }
      });
  void schedule() {
    if (disposed) return;
    final auth = ref.read(authControllerProvider);
    if (auth.isLoading) return;
    final account = auth.valueOrNull is AuthStateAuthenticated
        ? ref.read(accountStoreProvider).valueOrNull?.currentAccountId
        : null;
    final preferences = isAndroidBackgroundSupported
        ? ref.read(backgroundPreferencesProvider).valueOrNull
        : const BackgroundStatus();
    if (isAndroidBackgroundSupported && preferences == null) return;
    unawaited(sync.update(
        account: account,
        enabled: preferences?.pushEnabled ?? true,
        keepAlive: preferences?.enabled ?? false));
  }

  // App was in the *background*; user tapped the notification.
  final backgroundSub = ready
      ? FirebaseMessaging.onMessageOpenedApp.listen((message) {
          receivedWarmTap = true;
          deliver(message);
        })
      : null;

  // Foreground messages — the SSE stream already delivers the payload, so we
  // only log here. Add local-notification display if needed in the future.
  final foregroundSub = ready
      ? FirebaseMessaging.onMessage.listen((message) {
          // Real-time events own foreground UI. Do not log notification content.
        })
      : null;
  final tokenSub = ready
      ? FirebaseMessaging.instance.onTokenRefresh.listen(
          (_) => schedule(),
          onError: (Object error) => AppLog.w(
              LogTag.general, () => 'FCM token refresh unavailable: $error'),
        )
      : null;
  // Firebase may initialize after an existing session has already restored.
  ref.listen(authControllerProvider, (_, next) {
    schedule();
    if (!next.isLoading && next.valueOrNull is AuthStateAuthenticated) {
      final tap = pendingTap;
      if (tap != null) deliver(tap);
    }
  });
  ref.listen(accountStoreProvider, (before, next) {
    if (before?.valueOrNull?.currentAccountId !=
        next.valueOrNull?.currentAccountId) {
      unawaited(sync.update(account: null, enabled: false, keepAlive: false));
    }
    schedule();
  });
  ref.listen(backgroundPreferencesProvider, (_, __) => schedule());
  ref.listen(fcmRetryProvider, (_, __) => schedule());
  ref.listen(androidBackgroundedProvider, (_, background) {
    if (!background) schedule();
  });
  unawaited(Future<void>.microtask(schedule));

  ref.onDispose(() {
    disposed = true;
    sync.dispose();
    backgroundSub?.cancel();
    foregroundSub?.cancel();
    tokenSub?.cancel();
  });

  if (!ready) return;
  // Permission UI or slow Play Services must not delay tap subscriptions.
  unawaited(FirebaseMessaging.instance
      .requestPermission(
    alert: true,
    badge: true,
    sound: true,
  )
      .then<void>((_) {}, onError: (Object error, StackTrace stackTrace) {
    AppLog.w(
        LogTag.general, () => 'FCM permission request unavailable: $error');
  }));
  try {
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null && !receivedWarmTap) deliver(initial);
  } catch (error) {
    AppLog.w(
        LogTag.general, () => 'FCM initial notification unavailable: $error');
  }
}
