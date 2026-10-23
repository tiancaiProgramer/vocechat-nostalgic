import '../../../core/background/background_lifecycle.dart';
import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/application/auth_controller.dart';
import '../data/agora_api.dart';
import '../domain/voice_models.dart';
import 'voice_controller.dart';

part 'incoming_call_provider.g.dart';

/// Discovers incoming/outgoing DM call invites by polling the server's
/// active-channel list, mirroring the web reference's `useGetAgoraChannelsQuery`
/// (10s interval) in `components/Voice/index.tsx`. The server's `UserCalling`
/// push event exists but is not currently wired up server-side
/// (`admin_agora.rs` has the notify call commented out), so polling is the
/// only reliable signal; [MessageDispatcher] feeds `ChatEvent.userCalling`
/// into [set] too, so a future server fix needs no client change.
///
/// A DM call is "ringing" when exactly one participant (the caller) is in
/// the `vocechat:dm:{selfUid}` channel and it isn't us.
@Riverpod(keepAlive: true)
class IncomingCall extends _$IncomingCall {
  Timer? _timer;
  bool _polling = false;
  bool _disposed = false;
  int _generation = 0;
  int? _dismissedCaller;
  DateTime? _lastSeen;

  @override
  IncomingCallState build() {
    ref.onDispose(() {
      _disposed = true;
      _generation++;
      _timer?.cancel();
    });
    ref.listen(authControllerProvider, (previous, next) {
      if (previous?.valueOrNull != next.valueOrNull) clear();
      _dismissedCaller = null;
      _start();
    });
    ref.listen(androidBackgroundedProvider, (_, __) => _start());
    ref.listen(
      voiceControllerProvider.select((s) => s != null),
      (_, __) => _start(),
    );
    _start();
    return const IncomingCallState();
  }

  void _start() {
    _timer?.cancel();
    _generation++;
    if (ref.read(voiceControllerProvider) != null) return;
    // The retained engine keeps this timer alive with background reception.
    // A minute-long background interval misses most incoming calls entirely.
    const interval = Duration(seconds: 5);
    _timer = Timer.periodic(interval, (_) => _poll());
    // Fire once immediately rather than waiting a full interval.
    Future.microtask(_poll);
  }

  Future<void> _poll() async {
    if (_disposed || _polling) return;
    final generation = _generation;
    final authState = ref.read(authControllerProvider).valueOrNull;
    if (authState is! AuthStateAuthenticated) return;
    final selfUid = authState.user.uid;

    // Already in a call (either side) — the active-channel list would just
    // re-confirm what we already know, and re-triggering `set()` mid-call
    // risks clobbering the connected state with a stale "ringing" snapshot.
    if (ref.read(voiceControllerProvider) != null) return;

    _polling = true;
    try {
      final channels = await ref.read(agoraApiProvider).getActiveChannels();
      if (!_current(generation, authState)) return;
      final myChannel = channels.where((c) {
        return c.context?.map(
              user: (t) => t.uid == selfUid,
              group: (_) => false,
            ) ==
            true;
      }).firstOrNull;

      if (myChannel == null || myChannel.userCount != 1) {
        _dismissedCaller = null;
        clear();
        return;
      }

      final usersInChannel = await ref
          .read(agoraApiProvider)
          .getChannelUsers(myChannel.channelName);
      if (!_current(generation, authState)) return;
      final caller = usersInChannel.where((uid) => uid != selfUid).firstOrNull;
      if (caller == null) {
        _dismissedCaller = null;
        clear();
        return;
      }
      _lastSeen = DateTime.now();
      if (_dismissedCaller == caller) return;

      set(fromUid: caller, toUid: selfUid, calling: true);
    } catch (_) {
      // Never leave a ringing banner/notification indefinitely after a lost
      // connection. A later successful poll can discover a still-active call.
      if (_current(generation, authState) &&
          _lastSeen != null &&
          DateTime.now().difference(_lastSeen!) > const Duration(seconds: 30)) {
        clear();
      }
    } finally {
      _polling = false;
    }
  }

  bool _current(int generation, AuthState auth) =>
      !_disposed &&
      generation == _generation &&
      ref.read(authControllerProvider).valueOrNull == auth &&
      ref.read(voiceControllerProvider) == null;

  /// Update the ringing state. [calling] toggles visibility of the ringing
  /// banner; the caller/callee uids persist across mid-call widget rebuilds
  /// even after [calling] is cleared (mirrors the web slice's
  /// `updateCallInfo`, which keeps `from`/`to` when only muting `calling`).
  void set({int? fromUid, int? toUid, bool? calling}) {
    state = state.copyWith(
      fromUid: fromUid ?? state.fromUid,
      toUid: toUid ?? state.toUid,
      calling: calling ?? state.calling,
    );
  }

  void dismiss() {
    _dismissedCaller = state.fromUid;
    state = state.copyWith(calling: false);
  }

  void clear() {
    state = const IncomingCallState();
  }
}
