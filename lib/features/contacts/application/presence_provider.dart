import '../../../core/network/sse_client.dart';
import '../../auth/application/auth_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/storage/account_store.dart';

part 'presence_provider.g.dart';

/// Per-user online state.
///
/// Mirrors the web client's `users_state` / `users_state_changed` SSE handling
/// in `useStreaming`: we hold a `uid -> online` map that the avatar status dot
/// consults. Driven by `MessageDispatcher` (single SSE consumer) so we don't
/// need a second `ref.listen` competing for the same stream.
@Riverpod(keepAlive: true)
class Presence extends _$Presence {
  @override
  Map<int, bool> build() {
    ref.listen(
        accountStoreProvider.select((s) => s.valueOrNull?.currentAccountId),
        (previous, next) {
      if (previous != next) state = const {};
    });
    return const {};
  }

  /// Replace the entire snapshot (from `users_state`).
  void applySnapshot(List<Map<String, dynamic>> users) {
    final next = <int, bool>{};
    for (final u in users) {
      final uid = (u['uid'] as num?)?.toInt();
      if (uid == null) continue;
      next[uid] = u['online'] == true;
    }
    state = next;
  }

  /// Patch a single uid (from `users_state_changed`).
  void applyChange(int uid, bool online) {
    state = {...state, uid: online};
  }
}

/// Whether the server admin has enabled per-user online dots.
///
/// Mirrors `store.server.show_user_online_status` from the web client. Updated
/// from `server_config_changed` SSE events. Defaults to `true` so first paint
/// shows the dots until the server tells us otherwise.
@Riverpod(keepAlive: true)
class ShowOnlineStatus extends _$ShowOnlineStatus {
  @override
  bool build() => true;

  // ignore: avoid_positional_boolean_parameters
  void set(bool value) {
    state = value;
  }
}

/// Servers omit the subscribing user from users_state. Only a live event
/// connection can supply our own presence; peer values remain server-driven.
final presenceForDisplayProvider = Provider<Map<int, bool>>((ref) {
  final reported = ref.watch(presenceProvider);
  final auth = ref.watch(authControllerProvider).valueOrNull;
  if (auth is! AuthStateAuthenticated) return reported;
  final status = ref.watch(sseConnectionStatusProvider);
  final display = {...reported}..remove(auth.user.uid);
  if (status == SseStatus.connected) display[auth.user.uid] = true;
  return display;
});
