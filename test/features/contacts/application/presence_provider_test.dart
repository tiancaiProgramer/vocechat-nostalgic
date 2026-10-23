import 'package:vocechat_client/core/network/sse_client.dart';
import 'package:vocechat_client/features/auth/application/auth_controller.dart';
import 'package:vocechat_client/features/auth/domain/auth_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocechat_client/core/storage/account_store.dart';
import 'package:vocechat_client/features/contacts/application/presence_provider.dart';

class _Accounts extends AccountStore {
  @override
  Future<AccountState> build() async =>
      const AccountState(currentAccountId: 'first::1');
  void changeSession() =>
      state = const AsyncData(AccountState(currentAccountId: 'second::1'));
}

class _Auth extends AuthController {
  @override
  Future<AuthState> build() async =>
      const AuthState.authenticated(user: VoceUser(uid: 9, name: 'Self'));
  void switchUser(int uid) => state = AsyncData(AuthState.authenticated(
      user: VoceUser(uid: uid, name: 'Another account')));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
      'self is online after receiving events even when omitted from the server snapshot',
      () async {
    final c = ProviderContainer(overrides: [
      accountStoreProvider.overrideWith(_Accounts.new),
      authControllerProvider.overrideWith(_Auth.new),
    ]);
    addTearDown(c.dispose);
    await c.read(accountStoreProvider.future);
    await c.read(authControllerProvider.future);
    c.read(presenceProvider.notifier).applySnapshot([
      {'uid': 42, 'online': false},
      {'uid': 7, 'online': true},
    ]);
    expect(c.read(presenceForDisplayProvider).containsKey(9), false);
    c.read(sseConnectionStatusProvider.notifier).set(SseStatus.connected);
    expect(c.read(presenceForDisplayProvider), {42: false, 7: true, 9: true});
    expect(c.read(presenceProvider).containsKey(9), false);
    c.read(sseConnectionStatusProvider.notifier).set(SseStatus.reconnecting);
    expect(c.read(presenceForDisplayProvider).containsKey(9), false);
    expect(c.read(presenceForDisplayProvider)[42], false);
    c.read(sseConnectionStatusProvider.notifier).set(SseStatus.connected);
    expect(c.read(presenceForDisplayProvider)[9], true);
    (c.read(authControllerProvider.notifier) as _Auth).switchUser(8);
    expect(c.read(presenceForDisplayProvider).containsKey(9), false);
    expect(c.read(presenceForDisplayProvider)[8], true);
  });

  test(
      'presence stays unknown until server snapshot; deltas update and account switch resets',
      () async {
    final c = ProviderContainer(
        overrides: [accountStoreProvider.overrideWith(_Accounts.new)]);
    addTearDown(c.dispose);
    c.listen(accountStoreProvider, (_, __) {}, fireImmediately: true);
    await c.read(accountStoreProvider.future);
    final presence = c.read(presenceProvider.notifier);
    expect(c.read(presenceProvider).containsKey(42), false);
    presence.applySnapshot([
      {'uid': 42, 'online': true},
      {'uid': 9, 'online': false}
    ]);
    expect(c.read(presenceProvider), {42: true, 9: false});
    presence.applyChange(42, false);
    presence.applyChange(42, true);
    expect(c.read(presenceProvider)[42], true);
    (c.read(accountStoreProvider.notifier) as _Accounts).changeSession();
    expect(c.read(presenceProvider), isEmpty);
  });
}
