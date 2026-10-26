import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
// ignore: depend_on_referenced_packages
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vocechat_client/features/messages/application/chat_drafts_provider.dart';
import 'package:vocechat_client/features/sharing/application/incoming_share_provider.dart';
import 'package:vocechat_client/core/storage/server_store.dart';
import 'package:vocechat_client/core/storage/account_store.dart';
import 'package:vocechat_client/features/messages/application/custom_stickers_provider.dart';
import 'package:vocechat_client/features/auth/application/auth_controller.dart';
import 'package:vocechat_client/features/auth/domain/auth_models.dart';
import 'package:vocechat_client/features/contacts/application/user_directory_provider.dart';
import 'package:vocechat_client/features/messages/application/chat_controller.dart';
import 'package:vocechat_client/features/messages/application/read_index_provider.dart';
import 'package:vocechat_client/features/messages/domain/message_models.dart';
import 'package:vocechat_client/features/messages/presentation/chat_header_details.dart';
import 'package:vocechat_client/features/messages/presentation/chat_screen.dart';
import 'package:vocechat_client/features/messages/presentation/composer_emoji_picker.dart';
import 'package:vocechat_client/features/messages/presentation/pinned_message_bar.dart';
import 'package:vocechat_client/l10n/generated/app_localizations.dart';

const _name = 'A community with a very long group name that needs two lines';
final _description =
    List.filled(30, 'A complete community introduction.').join('\n');
const _target = MessageTarget.group(gid: 42);

PinnedMessageSummary _pin(int mid) => PinnedMessageSummary(
    mid: mid,
    content: 'Pinned message $mid',
    contentType: 'text/plain',
    createdBy: 8,
    createdAt: mid);

class _Auth extends AuthController {
  @override
  Future<AuthState> build() async =>
      const AuthState.authenticated(user: VoceUser(uid: 7, name: 'Me'));
}

class _Accounts extends AccountStore {
  void switchAccount() =>
      state = const AsyncData(AccountState(currentAccountId: 'first::8'));
  @override
  Future<AccountState> build() async =>
      const AccountState(currentAccountId: 'first::7', accounts: [
        AccountConfig(
            accountId: 'first::7', serverId: 'first', uid: 7, name: 'Me')
      ]);
}

class _NativeCamera extends ImagePickerPlatform {
  XFile? result;
  Object? failure;
  Completer<XFile?>? gate;
  final photoSources = <ImageSource>[];
  final videoSources = <ImageSource>[];
  Future<XFile?> _capture() async {
    if (failure != null) throw failure!;
    return gate == null ? result : await gate!.future;
  }

  @override
  Future<XFile?> getImageFromSource(
      {required ImageSource source,
      ImagePickerOptions options = const ImagePickerOptions()}) {
    photoSources.add(source);
    return _capture();
  }

  @override
  Future<XFile?> getVideo(
      {required ImageSource source,
      CameraDevice preferredCameraDevice = CameraDevice.rear,
      Duration? maxDuration}) {
    videoSources.add(source);
    return _capture();
  }
}

class _Servers extends ServerStore {
  @override
  Future<ServerState> build() async => const ServerState();
}

class _Users extends UserDirectory {
  @override
  Future<Map<int, UserSummary>> build() async =>
      const {8: UserSummary(uid: 8, name: 'Peer')};
}

class _Groups extends GroupDirectory {
  @override
  Future<Map<int, GroupSummary>> build() async => {
        42: GroupSummary(
            gid: 42,
            name: _name,
            description: _description,
            pinnedMessages: [_pin(10), _pin(20)]),
      };
}

class _ReadIndex extends ReadIndex {
  @override
  Future<ReadIndexState> build() async => const ReadIndexState();
  @override
  void setGroup(int gid, int mid) {}
}

class _Chat extends ChatController {
  final located = <int>[];
  final sentTexts = <(String, bool)>[];
  @override
  Future<void> sendText(String text,
      {List<int>? mentions, bool markdown = false}) async {
    sentTexts.add((text, markdown));
  }

  final sentStickers = <(Uint8List, String, String?)>[];
  @override
  Future<void> sendImage(
      {required Uint8List bytes,
      required String filename,
      String? contentType}) async {
    sentStickers.add((bytes, filename, contentType));
  }

  ChatMessage message(int mid) => ChatMessage(
      mid: mid,
      fromUid: 8,
      createdAt: 1000,
      target: _target,
      detail: MessageDetail.normal(
          contentType: 'text/plain', content: 'Message $mid'));
  @override
  Future<List<ChatMessage>> build(MessageTarget target) async => [message(30)];
  @override
  Future<void> loadMore() async {}
  @override
  Future<bool> ensureMessageLoaded(int mid,
      {bool Function()? shouldContinue}) async {
    located.add(mid);
    state = AsyncData([message(30), message(mid)]);
    return true;
  }
}

class _DelayedDrafts extends ChatDrafts {
  final gate = Completer<Map<String, ChatDraft>>();
  final writes = <String>[];
  @override
  Future<Map<String, ChatDraft>> build(String arg) => gate.future;
  @override
  Future<void> setDraft(String target, String text, List<int> mentions) async {
    await gate.future;
    writes.add(text);
  }

  @override
  Future<void> flush() async {}
}

Widget _app(Widget child) => MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppL10n.localizationsDelegates,
      supportedLocales: AppL10n.supportedLocales,
      home: Scaffold(body: child),
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  Future<ProviderContainer> pumpChat(WidgetTester tester,
      {double width = 390,
      Directory? stickerDocuments,
      String? draft,
      IncomingShareSelection? share,
      ChatDrafts? draftStore}) async {
    tester.view.physicalSize = Size(width, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = ProviderContainer(overrides: [
      authControllerProvider.overrideWith(_Auth.new),
      accountStoreProvider.overrideWith(_Accounts.new),
      if (draftStore != null) chatDraftsProvider.overrideWith(() => draftStore),
      if (stickerDocuments != null)
        stickerDocumentsProvider.overrideWith((ref) async => stickerDocuments),
      serverStoreProvider.overrideWith(_Servers.new),
      userDirectoryProvider.overrideWith(_Users.new),
      groupDirectoryProvider.overrideWith(_Groups.new),
      readIndexProvider.overrideWith(_ReadIndex.new),
      chatControllerProvider(_target).overrideWith(_Chat.new),
    ]);
    addTearDown(container.dispose);
    container.listen(accountStoreProvider, (_, __) {});
    await container.read(accountStoreProvider.future);
    if (draftStore == null) {
      await tester.runAsync(() async {
        await container.read(chatDraftsProvider('first::7').future);
        if (draft != null) {
          await container
              .read(chatDraftsProvider('first::7').notifier)
              .setDraft('g-42', draft, []);
          await container.read(chatDraftsProvider('first::7').notifier).flush();
        }
      });
    }
    if (share != null) {
      container.read(selectedIncomingShareProvider.notifier).state = share;
    }
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: _app(const ChatScreen(id: 'g-42')),
    ));
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets(
      'text draft restores after remount, clears on send and is isolated on account switch',
      (tester) async {
    final first = await pumpChat(tester, draft: 'saved before restart');
    final input = find.byType(TextField);
    expect(tester.widget<TextField>(input).controller!.text,
        'saved before restart');
    await tester.enterText(input, 'new unfinished draft');
    await tester.runAsync(
        () => first.read(chatDraftsProvider('first::7').notifier).flush());
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(() async => Future<void>.delayed(Duration.zero));
    final next = await pumpChat(tester);
    expect(tester.widget<TextField>(input).controller!.text,
        'new unfinished draft');
    final chat = next.read(chatControllerProvider(_target).notifier) as _Chat;
    expect(chat.sentTexts, isEmpty);
    await tester.tap(find.byTooltip('Send'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 400));
    expect(chat.sentTexts.single.$1, 'new unfinished draft');
    expect(next.read(chatDraftsProvider('first::7')).requireValue, isEmpty);
    await tester.enterText(input, 'private account draft');
    await tester.pump();
    (next.read(accountStoreProvider.notifier) as _Accounts).switchAccount();
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(input).controller!.text, isEmpty);
    expect(next.read(chatDraftsProvider('first::7')).requireValue['g-42']!.text,
        'private account draft');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'system share appends to a restored draft and stages files without sending',
      (tester) async {
    final source = File('test/fixtures/stickers/red.png');
    final container = await pumpChat(tester,
        draft: 'existing draft',
        share: IncomingShareSelection(
            'first::7',
            'g-42',
            IncomingShare(id: 'shared-test', text: 'shared link', files: [
              SharedFile(source.absolute.path, 'shared.png', 'image/png',
                  source.lengthSync())
            ])));
    for (var i = 0; i < 20 && find.text('shared.png').evaluate().isEmpty; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pump();
    }
    await tester.pumpAndSettle();
    final chat =
        container.read(chatControllerProvider(_target).notifier) as _Chat;
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'existing draft\nshared link');
    expect(find.text('shared.png'), findsOneWidget);
    expect(chat.sentTexts, isEmpty);
    expect(chat.sentStickers, isEmpty);
    expect(container.read(selectedIncomingShareProvider), isNull);
    await tester.tap(find.byTooltip('Send'));
    await tester.pumpAndSettle();
    expect(chat.sentTexts.single.$1, 'existing draft\nshared link');
    expect(chat.sentStickers.single.$2, 'shared.png');
    expect(tester.takeException(), isNull);
  });

  testWidgets('late draft restoration never overwrites newly typed text',
      (tester) async {
    final delayed = _DelayedDrafts();
    await pumpChat(tester, draftStore: delayed);
    final input = find.byType(TextField);
    await tester.enterText(input, 'newly typed');
    delayed.gate.complete({'g-42': const ChatDraft('old stored text', [], 1)});
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(input).controller!.text, 'newly typed');
    expect(delayed.writes, contains('newly typed'));
    expect(tester.takeException(), isNull);
  });

  Future<_NativeCamera> setupCamera(
      {bool galleryAllowed = true, bool galleryVideo = false}) async {
    final root = Directory.systemTemp.createTempSync('voce-gallery-video-');
    addTearDown(() => root.deleteSync(recursive: true));
    final video = File('${root.path}/saved-video.mp4')
      ..writeAsBytesSync([0, 0, 0, 24, 102, 116, 121, 112, 105, 115, 111, 109]);
    final photo = File('${root.path}/saved-photo.png')
      ..writeAsBytesSync(
          File('test/fixtures/stickers/red.png').readAsBytesSync());
    final original = ImagePickerPlatform.instance;
    final camera = _NativeCamera();
    ImagePickerPlatform.instance = camera;
    addTearDown(() => ImagePickerPlatform.instance = original);
    const gallery = MethodChannel('com.fluttercandies/photo_manager');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(gallery, (call) async {
      switch (call.method) {
        case 'requestPermissionExtend':
          return galleryAllowed ? 3 : 2;
        case 'getAssetPathList':
          expect((call.arguments as Map)['type'], 3,
              reason: 'images and videos');
          return {
            'data': galleryVideo
                ? [
                    {
                      'id': 'test-album',
                      'name': 'Recent',
                      'assetCount': 2,
                      'isAll': true,
                    }
                  ]
                : []
          };
        case 'getAssetListPaged':
          return {
            'data': [
              {
                'id': 'test-video',
                'type': 2,
                'width': 24,
                'height': 18,
                'duration': 12,
                'title': 'saved-video.mp4',
              },
              {
                'id': 'test-photo',
                'type': 1,
                'width': 24,
                'height': 18,
                'title': 'saved-photo.png',
              }
            ]
          };
        case 'getThumb':
          return File('test/fixtures/stickers/red.png').readAsBytesSync();
        case 'getFullFile':
          return (call.arguments as Map)['id'] == 'test-photo'
              ? photo.path
              : video.path;
        case 'getSystemVersion':
          return '36';
        case 'getOriginBytes':
          return Uint8List.fromList(
              [0, 0, 0, 24, 102, 116, 121, 112, 105, 115, 111, 109]);
        default:
          return null;
      }
    });
    addTearDown(() => TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger
        .setMockMethodCallHandler(gallery, null));
    return camera;
  }

  Future<void> flushIo(WidgetTester tester, bool Function() finished) async {
    for (var i = 0; i < 100 && !finished(); i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pump(const Duration(milliseconds: 10));
    }
    expect(finished(), isTrue);
    await tester.pumpAndSettle();
  }

  testWidgets(
      'composer removes Markdown and its extra menu and sends ordinary text',
      (tester) async {
    final container = await pumpChat(tester);
    expect(
        find.descendant(
            of: find.byKey(const ValueKey('chat-composer')),
            matching: find.byTooltip('More')),
        findsNothing);
    expect(find.text('Markdown'), findsNothing);
    expect(find.text('Video message'), findsNothing);
    await tester.enterText(find.byType(TextField), '**plain text**');
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Send'));
    await tester.pump();
    final chat =
        container.read(chatControllerProvider(_target).notifier) as _Chat;
    expect(chat.sentTexts, [('**plain text**', false)]);
  });

  for (final video in [false, true]) {
    testWidgets(
        '${video ? 'hold' : 'tap'} camera uses native ${video ? 'video' : 'photo'} and stages before sending',
        (tester) async {
      final camera = await setupCamera();
      final root = Directory.systemTemp.createTempSync('voce-camera-test-');
      addTearDown(() => root.deleteSync(recursive: true));
      final bytes = video
          ? Uint8List.fromList(
              [0, 0, 0, 24, 102, 116, 121, 112, 105, 115, 111, 109])
          : File('test/fixtures/stickers/red.png').readAsBytesSync();
      final file = File('${root.path}/capture.${video ? 'mp4' : 'png'}')
        ..writeAsBytesSync(bytes);
      camera.result = XFile(file.path);
      final container = await pumpChat(tester, width: 320);
      final chat =
          container.read(chatControllerProvider(_target).notifier) as _Chat;
      await tester.enterText(find.byType(TextField), 'Keep draft');
      await tester.tap(find.byTooltip('Attach').first);
      await tester.pumpAndSettle();
      final tile = find.byKey(const ValueKey('attachment-system-camera'));
      expect(find.text('Tap for photo · Hold for video'), findsOneWidget);
      if (video) {
        await tester.longPress(tile);
      } else {
        await tester.tap(tile);
      }
      await flushIo(tester,
          () => find.text(file.uri.pathSegments.last).evaluate().isNotEmpty);
      expect(camera.photoSources, video ? isEmpty : [ImageSource.camera]);
      expect(camera.videoSources, video ? [ImageSource.camera] : isEmpty);
      expect(chat.sentStickers, isEmpty);
      expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
          'Keep draft');
      await tester.tap(find.byTooltip('Send'));
      await tester.pumpAndSettle();
      expect(chat.sentStickers.single.$1, bytes);
      expect(chat.sentStickers.single.$3, video ? 'video/mp4' : 'image/png');
      expect(chat.sentTexts, [('Keep draft', false)]);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
      'camera remains available when photo-library permission is denied; cancelling preserves draft',
      (tester) async {
    final camera = await setupCamera(galleryAllowed: false);
    final container = await pumpChat(tester);
    await tester.enterText(find.byType(TextField), 'Unfinished');
    await tester.tap(find.byTooltip('Attach').first);
    await tester.pumpAndSettle();
    final tile = find.byKey(const ValueKey('attachment-system-camera'));
    expect(tile, findsOneWidget);
    await tester.tap(tile);
    await tester.pumpAndSettle();
    expect(camera.photoSources, [ImageSource.camera]);
    expect(tile, findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    Navigator.of(tester.element(tile)).pop();
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Unfinished');
    expect(
        (container.read(chatControllerProvider(_target).notifier) as _Chat)
            .sentStickers,
        isEmpty);
  });

  testWidgets(
      'capture permission failure restores camera controls and permits retry',
      (tester) async {
    final camera = await setupCamera();
    camera.failure = PlatformException(code: 'camera_access_denied');
    await pumpChat(tester);
    await tester.tap(find.byTooltip('Attach').first);
    await tester.pumpAndSettle();
    final tile = find.byKey(const ValueKey('attachment-system-camera'));
    await tester.longPress(tile);
    await tester.pumpAndSettle();
    expect(
        find.text(
            'Permission denied — enable microphone/camera access in system settings'),
        findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    camera.failure = null;
    await tester.tap(tile);
    await tester.pumpAndSettle();
    expect(camera.videoSources, [ImageSource.camera]);
    expect(camera.photoSources, [ImageSource.camera]);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'only one capture is active and account switching discards its return',
      (tester) async {
    final camera = await setupCamera();
    camera.gate = Completer<XFile?>();
    final container = await pumpChat(tester);
    await tester.tap(find.byTooltip('Attach').first);
    await tester.pumpAndSettle();
    final tile = find.byKey(const ValueKey('attachment-system-camera'));
    await tester.tap(tile);
    await tester.pump();
    await tester.tap(tile);
    expect(camera.photoSources, hasLength(1));
    (container.read(accountStoreProvider.notifier) as _Accounts)
        .switchAccount();
    camera.gate!
        .complete(XFile(File('test/fixtures/stickers/red.png').absolute.path));
    await flushIo(tester, () => tile.evaluate().isEmpty);
    expect(find.text('red.png'), findsNothing);
    expect(
        (container.read(chatControllerProvider(_target).notifier) as _Chat)
            .sentStickers,
        isEmpty);
  });

  testWidgets(
      'image panel shows photos and videos together and stages a mixed selection',
      (tester) async {
    await setupCamera(galleryVideo: true);
    final container = await pumpChat(tester);
    await tester.tap(find.byTooltip('Attach').first);
    await tester.pumpAndSettle();
    expect(find.text('0:12'), findsOneWidget);
    expect(find.byType(AssetEntityImage), findsNWidgets(2));
    await tester.tap(find.text('0:12'));
    await tester.tap(find.byType(AssetEntityImage).last);
    await tester.pump();
    await tester.tap(find.text('Send (2)'));
    await flushIo(
        tester, () => find.text('saved-photo.png').evaluate().isNotEmpty);
    expect(find.text('saved-video.mp4'), findsOneWidget);
    expect(find.text('saved-photo.png'), findsOneWidget);
    final chat =
        container.read(chatControllerProvider(_target).notifier) as _Chat;
    expect(chat.sentStickers, isEmpty);
    await tester.tap(find.byTooltip('Send'));
    await tester.pumpAndSettle();
    expect(
        chat.sentStickers.map((file) => file.$3), ['video/mp4', 'image/png']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('composer emoji button inserts at caret and replaces selection',
      (tester) async {
    await pumpChat(tester);
    final input = find.byType(TextField);
    await tester.enterText(input, 'hello world');
    final controller = tester.widget<TextField>(input).controller!;
    controller.selection = const TextSelection.collapsed(offset: 6);
    await tester.tap(find.byTooltip('Emoji'));
    await tester.pumpAndSettle();
    expect(find.byType(ComposerEmojiPicker), findsOneWidget);
    await tester.tap(find.text('😀'));
    await tester.pumpAndSettle();
    expect(controller.text, 'hello 😀world');
    expect(controller.selection.baseOffset, 8);
    controller.selection = const TextSelection(baseOffset: 8, extentOffset: 13);
    await tester.tap(find.byTooltip('Emoji'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('🥰'));
    await tester.pumpAndSettle();
    expect(controller.text, 'hello 😀🥰');
    expect(tester.takeException(), isNull);
  });

  testWidgets('saved sticker sends once without clearing the composed text',
      (tester) async {
    final root = Directory.systemTemp.createTempSync('voce-sticker-composer-');
    addTearDown(() => root.deleteSync(recursive: true));
    final container =
        await pumpChat(tester, stickerDocuments: root, width: 320);
    final bytes = File('test/fixtures/stickers/red.png').readAsBytesSync();
    final saved = await tester.runAsync(() =>
        container.read(customStickersProvider('first::7').notifier).add(bytes));
    await tester.pump();
    final input = find.byType(TextField);
    await tester.enterText(input, 'Keep my unfinished draft');
    await tester.tap(find.byTooltip('Emoji'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Saved stickers'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ValueKey('sticker-${saved!.sticker.id}')));
    final chat =
        container.read(chatControllerProvider(_target).notifier) as _Chat;
    for (var i = 0; i < 100 && chat.sentStickers.isEmpty; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pump(const Duration(milliseconds: 10));
    }
    await tester.pumpAndSettle();
    expect(chat.sentStickers, hasLength(1));
    expect(chat.sentStickers.single.$1, bytes);
    expect(chat.sentStickers.single.$3, 'image/png');
    expect(tester.widget<TextField>(input).controller!.text,
        'Keep my unfinished draft');
    expect(find.byType(ComposerEmojiPicker), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final width in [320.0, 390.0, 900.0]) {
    testWidgets('long group title and full introduction at width $width',
        (tester) async {
      await pumpChat(tester, width: width);
      final title = tester.widget<Text>(find.text(_name));
      expect(title.maxLines, 2);
      expect(tester.getTopLeft(find.byType(PinnedMessageBar)).dy,
          greaterThan(tester.getBottomLeft(find.byType(ChatHeaderDetails)).dy));
      await tester.tap(find.byType(ChatHeaderDetails));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(SelectableText, _name), findsOneWidget);
      expect(find.widgetWithText(SelectableText, _description), findsOneWidget);
      await tester.drag(
          find.byType(SingleChildScrollView), const Offset(0, -500));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('pin bar cycles, locates, highlights and opens the full pin list',
      (tester) async {
    final container = await pumpChat(tester);
    final chat =
        container.read(chatControllerProvider(_target).notifier) as _Chat;
    expect(find.text('Pinned message 20'), findsOneWidget);
    await tester.tap(find.text('Pinned message 20'));
    await tester.pumpAndSettle();
    expect(chat.located, [20]);
    expect(find.text('Message 20'), findsOneWidget);
    expect(
        tester
            .widgetList<MessageRow>(find.byType(MessageRow))
            .any((row) => row.message.mid == 20 && row.highlighted),
        isTrue);
    expect(find.text('Pinned message 10'), findsOneWidget);
    await tester.tap(find.text('Pinned message 10'));
    await tester.pumpAndSettle();
    expect(chat.located, [20, 10]);
    await tester.tap(find.byIcon(Icons.format_list_bulleted));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pinned message 10').last);
    await tester.pumpAndSettle();
    expect(chat.located, [20, 10, 10]);
    expect(tester.takeException(), isNull);
    // Clear the temporary highlight before the test ends.
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('pin bar updates and disappears after pins are removed',
      (tester) async {
    final container = await pumpChat(tester);
    final groups = container.read(groupDirectoryProvider.notifier);
    groups.applyPinned(42, [_pin(5)]);
    await tester.pumpAndSettle();
    expect(find.text('Pinned message 5'), findsOneWidget);
    groups.applyPinned(42, []);
    await tester.pumpAndSettle();
    expect(find.byType(PinnedMessageBar), findsNothing);
  });
}
