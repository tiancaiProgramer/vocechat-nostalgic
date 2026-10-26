import 'dart:async';

import 'package:dio/dio.dart';

enum FcmPhase { connecting, registered, standby, disabled, unavailable }

/// Serializes changes for the current device. VoceChat accepts JSON null to
/// remove its push token. This keeps SDK-displayed pushes from duplicating the
/// existing WebSocket notifications when keep-alive is enabled.
class FcmTokenSync {
  FcmTokenSync(
      {required this.getToken,
      required this.upload,
      required this.onPhase,
      this.onFailure,
      this.retryDelay = const Duration(seconds: 30)});

  final Future<String> Function() getToken;
  final Future<void> Function(String?, CancelToken) upload;
  final void Function(FcmPhase) onPhase;
  final void Function(Object)? onFailure;
  final Duration? retryDelay;
  Future<void> _queue = Future.value();
  Timer? _retry;
  CancelToken? _cancel;
  String? _account;
  bool _disposed = false;
  int _revision = 0;

  Future<void> update(
      {required String? account,
      required bool enabled,
      required bool keepAlive}) {
    if (_disposed) return Future.value();
    if (_account != account) _cancel?.cancel('Account changed');
    _account = account;
    final revision = ++_revision;
    _retry?.cancel();
    bool current() => !_disposed && revision == _revision;
    _queue = _queue.then((_) async {
      if (!current() || account == null) return;
      final cancel = _cancel = CancelToken();
      onPhase(FcmPhase.connecting);
      try {
        if (!enabled || keepAlive) await upload(null, cancel);
        if (!current()) return;
        // Background mode must not depend on Google connectivity or acquire a
        // token it will not use. Only the selected FCM path contacts the SDK.
        final token = enabled && !keepAlive ? await getToken() : null;
        if (!current()) return;
        if (token != null && token.isEmpty) throw StateError('No FCM token');
        if (enabled && !keepAlive) await upload(token, cancel);
        if (!current()) return;
        onPhase(!enabled
            ? FcmPhase.disabled
            : keepAlive
                ? FcmPhase.standby
                : FcmPhase.registered);
      } catch (error) {
        if (!current()) return;
        onFailure?.call(error);
        onPhase(FcmPhase.unavailable);
        final delay = retryDelay;
        if (delay != null) {
          _retry = Timer(delay, () {
            if (current()) {
              unawaited(update(
                  account: account, enabled: enabled, keepAlive: keepAlive));
            }
          });
        }
      }
    });
    return _queue;
  }

  void dispose() {
    _disposed = true;
    _revision++;
    _retry?.cancel();
    _cancel?.cancel('Disposed');
  }
}
