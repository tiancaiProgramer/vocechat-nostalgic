import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player/video_player.dart';
// ignore: depend_on_referenced_packages
import 'package:video_player_platform_interface/video_player_platform_interface.dart';
import 'package:vocechat_client/core/network/dio_client.dart';
import 'package:vocechat_client/core/storage/account_store.dart';
import 'package:vocechat_client/features/messages/presentation/motion_photo_overlay.dart';
import 'package:vocechat_client/l10n/generated/app_localizations.dart';

class _Accounts extends AccountStore {
  @override
  Future<AccountState> build() async =>
      const AccountState(currentAccountId: 'test::7');
}

class _Adapter implements HttpClientAdapter {
  _Adapter(this.bytes);
  final Uint8List bytes;
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? body,
          Future<void>? cancel) async =>
      ResponseBody.fromBytes(bytes, 200, headers: {
        'content-length': ['${bytes.length}']
      });
  @override
  void close({bool force = false}) {}
}

class _Player extends VideoPlayerPlatform {
  int played = 0, paused = 0, disposed = 0;
  final volumes = <double>[];
  @override
  Future<void> init() async {}
  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async => 1;
  @override
  Stream<VideoEvent> videoEventsFor(int playerId) => Stream.value(VideoEvent(
      eventType: VideoEventType.initialized,
      duration: const Duration(seconds: 3),
      size: const Size(320, 240)));
  @override
  Future<void> dispose(int playerId) async {
    disposed++;
  }

  @override
  Future<void> setLooping(int playerId, bool looping) async {}
  @override
  Future<void> play(int playerId) async {
    played++;
  }

  @override
  Future<void> pause(int playerId) async {
    paused++;
  }

  @override
  Future<void> setVolume(int playerId, double volume) async {
    volumes.add(volume);
  }

  @override
  Future<void> seekTo(int playerId, Duration position) async {}
  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {}
  @override
  Future<Duration> getPosition(int playerId) async => Duration.zero;
  @override
  Widget buildViewWithOptions(VideoViewOptions options) =>
      const ColoredBox(color: Colors.red);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory root;
  late VideoPlayerPlatform original;
  late _Player player;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('vc-live-ui-');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (_) async => root.path);
    original = VideoPlayerPlatform.instance;
    VideoPlayerPlatform.instance = player = _Player();
  });
  tearDown(() async {
    VideoPlayerPlatform.instance = original;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'), null);
    if (await root.exists()) await root.delete(recursive: true);
  });
  Future<void> until(WidgetTester tester, bool Function() done) async {
    for (var i = 0; i < 150 && !done(); i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pump(const Duration(milliseconds: 10));
    }
    expect(done(), isTrue);
  }

  testWidgets(
      'ephemeral live preview mutes, pauses in background and deletes temporary resources on close',
      (tester) async {
    final data =
        File('test/fixtures/live_photos/legacy-motion.jpg').readAsBytesSync();
    final dio = Dio()..httpClientAdapter = _Adapter(data);
    addTearDown(() => dio.close(force: true));
    final container = ProviderContainer(overrides: [
      dioProvider.overrideWithValue(dio),
      accountStoreProvider.overrideWith(_Accounts.new)
    ]);
    addTearDown(container.dispose);
    await container.read(accountStoreProvider.future);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: AppL10n.localizationsDelegates,
            supportedLocales: AppL10n.supportedLocales,
            home: const Scaffold(
                body: MotionPhotoOverlay(
                    originUrl: 'https://example.test/api/resource/file',
                    headers: {},
                    cacheMedia: false,
                    hint: true)))));
    await until(tester, () => find.byType(VideoPlayer).evaluate().isNotEmpty);
    expect(player.volumes.last, 0);
    expect(player.played, greaterThan(0));
    final folders = root.listSync().whereType<Directory>().toList();
    expect(folders, hasLength(1));
    expect(File('${folders.single.path}/live.mov').readAsBytesSync(),
        File('test/fixtures/live_photos/paired.mov').readAsBytesSync());
    await tester.tap(find.byIcon(Icons.volume_off_outlined));
    await tester.pump();
    expect(player.volumes.last, 1);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(find.byType(VideoPlayer), findsNothing);
    expect(player.paused, greaterThan(0));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.tap(find.text('Live Photo'));
    await tester.pump();
    expect(find.byType(VideoPlayer), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await until(tester, () => root.listSync().isEmpty);
    expect(player.disposed, 1);
    expect(tester.takeException(), isNull);
  });
}
