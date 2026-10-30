import 'package:vocechat_client/features/app_update/data/nostalgic_github_update.dart';
import 'package:vocechat_client/features/app_update/presentation/nostalgic_update_tile.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vocechat_client/core/background/background_preferences.dart';
import 'package:vocechat_client/core/notifications/fcm_service.dart';
import 'package:vocechat_client/core/notifications/fcm_token_sync.dart';
import 'package:vocechat_client/core/startup/app_startup.dart';

import 'package:vocechat_client/core/storage/server_store.dart';
import 'package:vocechat_client/features/auth/application/auth_controller.dart';
import 'package:vocechat_client/features/auth/domain/auth_models.dart';
import 'package:vocechat_client/features/settings/application/app_info_provider.dart';
import 'package:vocechat_client/features/settings/application/server_version_provider.dart';
import 'package:vocechat_client/features/settings/presentation/avo_settings_screen.dart';
import 'package:vocechat_client/features/settings/presentation/settings_screen.dart';
import 'package:vocechat_client/l10n/generated/app_localizations.dart';
import 'package:vocechat_client/shared/models/avo_params.dart';
import 'package:vocechat_client/shared/widgets/avo_avatar.dart';

void desktopTestWidgets(String name, WidgetTesterCallback callback) {
  testWidgets(name, callback,
      variant: TargetPlatformVariant.only(TargetPlatform.windows));
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('vocechat/system_font'),
            (call) async => call.method == 'describe' ? [] : null);
  });
  tearDown(() => TestDefaultBinaryMessengerBinding
      .instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
          const MethodChannel('vocechat/system_font'), null));

  testWidgets('Appearance and language exposes the font family choices',
      (tester) async {
    await tester.pumpWidget(ProviderScope(overrides: [
      authControllerProvider.overrideWith(_RegularAuthController.new),
      serverStoreProvider.overrideWith(_TestServerStore.new),
    ], child: _localizedApp()));
    await tester.pumpAndSettle();
    final menu = find.text('Appearance & Language');
    await tester.ensureVisible(menu);
    await tester.tap(menu);
    await tester.pumpAndSettle();
    final option = find.byKey(const Key('font-family-bundled'));
    await tester.ensureVisible(option);
    await tester.tap(option);
    await tester.pumpAndSettle();
    expect(find.text('Follow system font'), findsOneWidget);
    expect(find.text('App default font'), findsOneWidget);
    expect((await SharedPreferences.getInstance()).getString('app.fontFamily'),
        'bundled');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'nostalgic About exposes own website, project and update at large font',
      (tester) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final opened = <Uri>[];
    await tester.pumpWidget(ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(_RegularAuthController.new),
          serverStoreProvider.overrideWith(_TestServerStore.new),
          appPackageInfoProvider.overrideWith((ref) async => PackageInfo(
              appName: 'vocechat怀旧版',
              packageName: 'com.privoce.vocechatclient.legacyui',
              version: '0.3.35-r9',
              buildNumber: '3130')),
          serverVersionProvider.overrideWith((ref) async => '0.5.39'),
          aboutLinkLauncherProvider.overrideWithValue((uri) async {
            opened.add(uri);
            return true;
          }),
        ],
        child: MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: AppL10n.localizationsDelegates,
            supportedLocales: AppL10n.supportedLocales,
            builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: const TextScaler.linear(1.3)),
                child: child!),
            home: const Scaffold(body: SettingsScreen()))));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('About'));
    await tester.tap(find.text('About'));
    await tester.pumpAndSettle();
    expect(find.text('vocechat怀旧版'), findsOneWidget);
    expect(find.text('0.3.35-r9 (3130)'), findsOneWidget);
    expect(find.text('Check for updates'), findsOneWidget);
    final opens = find.text('Open');
    await tester.ensureVisible(opens.first);
    await tester.tap(opens.first);
    await tester.pump();
    await tester.ensureVisible(opens.last);
    await tester.tap(opens.last);
    await tester.pump();
    expect(opened, [nostalgicWebsiteUrl, nostalgicProjectUrl]);
    expect(tester.takeException(), isNull);
  });

  for (final keepAlive in [false, true]) {
    testWidgets(
        'notification controls accurately reflect FCM mode (keepAlive=$keepAlive)',
        (tester) async {
      await tester.pumpWidget(ProviderScope(overrides: [
        authControllerProvider.overrideWith(_RegularAuthController.new),
        serverStoreProvider.overrideWith(_TestServerStore.new),
        backgroundPreferencesProvider
            .overrideWith(() => _NotificationPreferences(keepAlive)),
        firebaseInitializedProvider.overrideWith((ref) => true),
        fcmPhaseProvider.overrideWith(
            (ref) => keepAlive ? FcmPhase.standby : FcmPhase.registered),
      ], child: _localizedApp()));
      await tester.pumpAndSettle();
      final menu = find.text('Notifications');
      await tester.ensureVisible(menu);
      await tester.tap(menu);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('fcm-status')), findsOneWidget);
      final switches = tester.widgetList<Switch>(find.byType(Switch)).toList();
      expect(switches.length, greaterThanOrEqualTo(3));
      expect(switches[0].onChanged, isNotNull);
      expect(switches[1].onChanged != null, keepAlive);
      expect(switches[2].onChanged != null, keepAlive);
      expect(tester.takeException(), isNull);
    });
  }

  for (final width in [390.0, 1000.0]) {
    desktopTestWidgets('AVO opens only from its own menu at width $width',
        (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(_RegularAuthController.new),
          serverStoreProvider.overrideWith(_TestServerStore.new),
        ],
        child: _localizedApp(),
      ));
      await tester.pumpAndSettle();
      expect(find.byType(AvoSettingsCard), findsNothing);

      await tester.tap(find.text('AVO'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(AvoSettingsCard), findsOneWidget);
      expect(find.byKey(const Key('avo-name')), findsOneWidget);
      expect(tester.widget<AvoAvatar>(find.byType(AvoAvatar)).params,
          AvoParams.fromName('Regular user'));
      await tester.enterText(find.byKey(const Key('avo-name')), '张三');
      await tester.pump();
      final generated = tester.widget<AvoAvatar>(find.byType(AvoAvatar)).params;
      expect(generated, AvoParams.fromName('张三'));
      await tester.enterText(find.byKey(const Key('avo-name')), 'Alice');
      await tester.pump();
      expect(tester.widget<AvoAvatar>(find.byType(AvoAvatar)).params,
          isNot(generated));
      await tester.enterText(find.byKey(const Key('avo-name')), '张三');
      await tester.pump();
      expect(
          tester.widget<AvoAvatar>(find.byType(AvoAvatar)).params, generated);
      tester.testTextInput.hide();
      expect(tester.takeException(), isNull);

      if (width < 700) {
        await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
      } else {
        await tester.tap(find.text('My Account'));
      }
      await tester.pumpAndSettle();
      expect(find.byType(AvoSettingsCard), findsNothing);
    });

    for (final fail in [false, true]) {
      desktopTestWidgets(
          'About loads server version (failure=$fail) at width $width',
          (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final serverVersion = Completer<String>();

        await tester.pumpWidget(ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(_RegularAuthController.new),
            serverStoreProvider.overrideWith(_TestServerStore.new),
            appPackageInfoProvider.overrideWith((ref) async => PackageInfo(
                  appName: 'VoceChat',
                  packageName: 'chat.voce',
                  version: '0.3.21',
                  buildNumber: '21',
                )),
            serverVersionProvider.overrideWith((ref) => serverVersion.future),
          ],
          child: _localizedApp(),
        ));
        await tester.pumpAndSettle();
        await tester.tap(find.text('About').last);
        await tester.pumpAndSettle();
        expect(find.text('SERVER VERSION'), findsOneWidget);
        expect(find.text('…'), findsOneWidget);
        expect(find.text('0.3.21 (21)'), findsOneWidget);

        if (fail) {
          serverVersion.completeError(Exception('Server unavailable'));
        } else {
          serverVersion.complete('0.5.22');
        }
        await tester.pumpAndSettle();
        expect(find.text(fail ? '—' : '0.5.22'), findsOneWidget);
        expect(find.text('0.3.21 (21)'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  desktopTestWidgets('regular user can confirm account deletion',
      (tester) async {
    tester.view.physicalSize = const Size(1000, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(_RegularAuthController.new),
        serverStoreProvider.overrideWith(_TestServerStore.new),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: _localizedApp(),
      ),
    );
    await tester.pumpAndSettle();

    final deleteButton = find.text('Delete account');
    expect(deleteButton, findsOneWidget);

    await tester.ensureVisible(deleteButton);
    await tester.tap(deleteButton);
    await tester.pumpAndSettle();

    expect(find.text('Delete this account?'), findsOneWidget);
    final confirmLabel = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.text('Delete account'),
    );
    await tester.tap(confirmLabel);
    await tester.pump();

    final controller = container.read(authControllerProvider.notifier)
        as _RegularAuthController;
    expect(controller.deleteCalls, 1);
  });

  desktopTestWidgets('initial uid 1 account cannot be deleted', (tester) async {
    tester.view.physicalSize = const Size(1000, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(_InitialAuthController.new),
          serverStoreProvider.overrideWith(_TestServerStore.new),
        ],
        child: _localizedApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Delete account'), findsNothing);
  });
}

class _NotificationPreferences extends BackgroundPreferences {
  _NotificationPreferences(this.keepAlive);
  final bool keepAlive;
  @override
  Future<BackgroundStatus> build() async => BackgroundStatus(
      enabled: keepAlive,
      notifications: true,
      batteryExempt: true,
      pushEnabled: true);
}

Widget _localizedApp() {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppL10n.localizationsDelegates,
    supportedLocales: AppL10n.supportedLocales,
    home: const Scaffold(body: SettingsScreen()),
  );
}

class _RegularAuthController extends AuthController {
  int deleteCalls = 0;

  @override
  Future<AuthState> build() async => const AuthState.authenticated(
        user: VoceUser(uid: 7, name: 'Regular user', email: 'user@example.com'),
      );

  @override
  Future<void> deleteCurrentAccount() async {
    deleteCalls++;
  }
}

class _InitialAuthController extends AuthController {
  @override
  Future<AuthState> build() async => const AuthState.authenticated(
        user: VoceUser(uid: 1, name: 'Initial user'),
      );
}

class _TestServerStore extends ServerStore {
  @override
  Future<ServerState> build() async => const ServerState(
        servers: [
          ServerConfig(
            id: 'server',
            baseUrl: 'https://chat.example.com',
            name: 'Test server',
          ),
        ],
        currentServerId: 'server',
      );
}
