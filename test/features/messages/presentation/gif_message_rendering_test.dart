import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocechat_client/core/storage/account_store.dart';
import 'package:vocechat_client/core/storage/server_store.dart';
import 'package:vocechat_client/core/storage/secure_token_store.dart';
import 'package:vocechat_client/features/messages/presentation/file_message_content.dart';
import 'package:vocechat_client/l10n/generated/app_localizations.dart';

class _Accounts extends AccountStore {
  @override
  Future<AccountState> build() async =>
      const AccountState(currentAccountId: 'server::7');
}

class _Servers extends ServerStore {
  @override
  Future<ServerState> build() async =>
      const ServerState(currentServerId: 'server', servers: [
        ServerConfig(id: 'server', baseUrl: 'https://chat.test', name: 'Test')
      ]);
}

class _Tokens extends SecureTokenStore {
  _Tokens() : super(id: 'server::7');
  @override
  Future<TokenData?> readTokens() async => null;
}

void main() {
  for (final mime in ['image/gif', 'image/png']) {
    testWidgets(
        '$mime bubble selects ${mime.endsWith('gif') ? 'original animation' : 'thumbnail'}',
        (tester) async {
      final container = ProviderContainer(overrides: [
        accountStoreProvider.overrideWith(_Accounts.new),
        serverStoreProvider.overrideWith(_Servers.new),
        secureTokenStoreProvider('server::7').overrideWith((ref) => _Tokens()),
      ]);
      addTearDown(container.dispose);
      container.listen(accountStoreProvider, (_, __) {});
      container.listen(serverStoreProvider, (_, __) {});
      await container.read(accountStoreProvider.future);
      await container.read(serverStoreProvider.future);
      await tester.pumpWidget(UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
              localizationsDelegates: AppL10n.localizationsDelegates,
              supportedLocales: AppL10n.supportedLocales,
              home: Scaffold(
                  body: FileMessageContent(
                      content: 'images/picture',
                      cacheMedia: false,
                      properties: {
                    'content_type': mime,
                    'size': 100,
                    'width': 24,
                    'height': 18
                  })))));
      final image = tester.widget<Image>(find.byType(Image));
      final url = Uri.parse((image.image as NetworkImage).url);
      expect(url.queryParameters['file_path'], 'images/picture');
      expect(url.queryParameters['thumbnail'],
          mime.endsWith('gif') ? isNull : 'true');
      await tester.pumpWidget(const SizedBox.shrink());
      expect(tester.takeException(), isNull);
    });
  }
}
