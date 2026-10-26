import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vocechat_client/core/storage/account_store.dart';
import 'package:vocechat_client/features/messages/application/custom_stickers_provider.dart';
import 'package:vocechat_client/features/messages/data/custom_sticker_store.dart';
import 'package:vocechat_client/features/messages/data/sticker_sync.dart';
import 'package:vocechat_client/features/messages/presentation/composer_emoji_picker.dart';
import 'package:vocechat_client/l10n/generated/app_localizations.dart';

class _Accounts extends AccountStore {
  @override
  Future<AccountState> build() async =>
      const AccountState(currentAccountId: 'server::7');
  void switchAccount() =>
      state = const AsyncData(AccountState(currentAccountId: 'server::8'));
}

class _Picker extends FilePicker {
  FilePickerResult? result;
  int calls = 0;
  @override
  Future<FilePickerResult?> pickFiles(
      {String? dialogTitle,
      String? initialDirectory,
      FileType type = FileType.any,
      List<String>? allowedExtensions,
      Function(FilePickerStatus)? onFileLoading,
      bool allowCompression = true,
      int compressionQuality = 30,
      bool allowMultiple = false,
      bool withData = false,
      bool withReadStream = false,
      bool lockParentWindow = false,
      bool readSequential = false}) async {
    calls++;
    expect(allowMultiple, isTrue);
    expect(allowCompression, isFalse);
    expect(withData, isFalse);
    expect(allowedExtensions, contains('gif'));
    return result;
  }
}

void main() {
  late Directory root;
  late ProviderContainer container;
  late _Picker picker;
  FilePicker? original;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    root = await Directory.systemTemp.createTemp('voce-sticker-picker-');
    // Some platforms have no picker instance until their plugin registers.
    try {
      original = FilePicker.platform;
    } catch (_) {
      original = null;
    }
    picker = _Picker();
    FilePicker.platform = picker;
    container = ProviderContainer(overrides: [
      accountStoreProvider.overrideWith(_Accounts.new),
      stickerDocumentsProvider.overrideWith((ref) async => root),
    ]);
    container.listen(accountStoreProvider, (_, __) {});
    await container.read(accountStoreProvider.future);
  });
  tearDown(() async {
    container.dispose();
    if (original != null) FilePicker.platform = original!;
    await root.delete(recursive: true);
  });

  Future<void> pump(WidgetTester tester,
      {ValueChanged<CustomSticker>? onSelected}) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
            locale: const Locale('en'),
            supportedLocales: AppL10n.supportedLocales,
            localizationsDelegates: AppL10n.localizationsDelegates,
            home: Scaffold(
                body: ComposerEmojiPicker(
                    accountId: 'server::7',
                    onSelected: (_) {},
                    onStickerSelected: onSelected)))));
    // Initialize filesystem work in the real async zone before the tab's
    // sync callback first accesses the provider.
    await tester.runAsync(
        () => container.read(customStickersProvider('server::7').future));
    await tester.tap(find.text('Saved stickers'));
    await tester.pumpAndSettle();
  }

  Future<void> flushIo(WidgetTester tester, bool Function() finished) async {
    for (var i = 0; i < 100 && !finished(); i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pump(const Duration(milliseconds: 10));
    }
    expect(finished(), isTrue,
        reason: 'asynchronous sticker operation finished');
    await tester.pumpAndSettle();
  }

  testWidgets('empty library imports, deduplicates, selects and deletes',
      (tester) async {
    CustomSticker? selected;
    await pump(tester, onSelected: (sticker) => selected = sticker);
    expect(find.text('No saved stickers yet'), findsOneWidget);
    expect(find.text('Import image / GIF'), findsNothing);
    await tester.tap(find.text('Manage'));
    await tester.pump();
    final path = File('test/fixtures/stickers/red.png').absolute.path;
    picker.result = FilePickerResult([
      PlatformFile(name: 'red.png', path: path, size: File(path).lengthSync())
    ]);
    await tester.tap(find.text('Import image / GIF'));
    await flushIo(
        tester,
        () =>
            find.text('Added 1, duplicates 0, failed 0').evaluate().isNotEmpty);
    expect(find.text('Added 1, duplicates 0, failed 0'), findsOneWidget);
    final sticker =
        container.read(customStickersProvider('server::7')).requireValue.single;
    await tester.tap(find.text('Import image / GIF'));
    await flushIo(
        tester,
        () =>
            find.text('Added 0, duplicates 1, failed 0').evaluate().isNotEmpty);
    expect(container.read(customStickersProvider('server::7')).requireValue,
        hasLength(1));
    final tile = find.byKey(ValueKey('sticker-${sticker.id}'));
    await tester.tap(find.text('Done'));
    await tester.pump();
    expect(find.text('Import image / GIF'), findsNothing);
    await tester.tap(tile);
    expect(selected?.id, sticker.id);
    await tester.tap(find.text('Manage'));
    await tester.pump();
    await tester.tap(tile);
    await tester.pumpAndSettle();
    expect(find.text('Remove this sticker?'), findsOneWidget);
    await tester.tap(find.text('Delete'));
    await flushIo(
        tester,
        () =>
            container
                .read(customStickersProvider('server::7'))
                .valueOrNull
                ?.isEmpty ==
            true);
    expect(find.text('No saved stickers yet'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'reopening remembers either tab, including after recreating app UI',
      (tester) async {
    await tester.runAsync(() async {
      await SharedPreferences.getInstance();
      await container.read(customStickersProvider('server::7').future);
    });
    Widget app() => UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
            locale: const Locale('en'),
            supportedLocales: AppL10n.supportedLocales,
            localizationsDelegates: AppL10n.localizationsDelegates,
            home: Scaffold(
                body: Builder(
                    builder: (context) => TextButton(
                        onPressed: () => showComposerEmojiPicker(context,
                            accountId: 'server::7'),
                        child: const Text('Open'))))));
    await tester.pumpWidget(app());
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('😀'), findsOneWidget);
    await tester.tap(find.text('Saved stickers'));
    await tester.pumpAndSettle();
    expect(find.text('Manage'), findsOneWidget);
    expect(find.text('Import image / GIF'), findsNothing);
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    // No picker State survives this; restoration comes from preferences.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(app());
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Manage'), findsOneWidget);
    expect(find.text('😀'), findsNothing);
    await tester.tap(find.text('Emoji'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('😀'), findsOneWidget);
    expect(find.text('Manage'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('management imports multiple images and GIFs in one selection',
      (tester) async {
    await pump(tester);
    expect(find.text('Import image / GIF'), findsNothing);
    await tester.tap(find.text('Manage'));
    await tester.pump();
    picker.result = FilePickerResult([
      for (final name in ['red.png', 'blue.png', 'animated.gif'])
        PlatformFile(
            name: name,
            path: File('test/fixtures/stickers/$name').absolute.path,
            size: File('test/fixtures/stickers/$name').lengthSync()),
    ]);
    await tester.tap(find.text('Import image / GIF'));
    await flushIo(
        tester,
        () =>
            container
                .read(customStickersProvider('server::7'))
                .valueOrNull
                ?.length ==
            3);
    expect(picker.calls, 1);
    expect(
        container
            .read(customStickersProvider('server::7'))
            .requireValue
            .where((sticker) => sticker.extension == 'gif'),
        hasLength(1));
    await tester.tap(find.text('Done'));
    await tester.pump();
    expect(find.text('Import image / GIF'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sync uses cloud icons without a visible status paragraph',
      (tester) async {
    await pump(tester);
    final status =
        container.read(stickerSyncStatusProvider('server::7').notifier);
    status.state = StickerSyncStatus.synced;
    await tester.pump();
    expect(find.byIcon(Icons.cloud_done_outlined), findsOneWidget);
    expect(find.text('Synced with server'), findsNothing);
    for (final value in [
      StickerSyncStatus.local,
      StickerSyncStatus.unavailable
    ]) {
      status.state = value;
      await tester.pump();
      expect(find.byIcon(Icons.cloud_outlined), findsOneWidget);
      expect(find.byIcon(Icons.priority_high_rounded), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'management drag sorting persists without adding sticker categories',
      (tester) async {
    await pump(tester);
    final store = container.read(customStickersProvider('server::7').notifier);
    await tester.runAsync(() async {
      for (final name in ['red.png', 'blue.png', 'animated.gif']) {
        await store.add(File('test/fixtures/stickers/$name').readAsBytesSync());
      }
    });
    await tester.pumpAndSettle();
    final before = container
        .read(customStickersProvider('server::7'))
        .requireValue
        .map((s) => s.id)
        .toList();
    expect(find.byTooltip('Reorder'), findsNothing);
    await tester.tap(find.text('Manage'));
    await tester.pump();
    await tester.tap(find.byTooltip('Reorder'));
    await tester.pumpAndSettle();
    expect(find.text('Reorder stickers'), findsOneWidget);
    final handles = find.byType(ReorderableDragStartListener);
    final gesture = await tester.startGesture(tester.getCenter(handles.last));
    await tester.pump();
    for (var i = 0; i < 6; i++) {
      await gesture.moveBy(const Offset(0, -35));
      await tester.pump(const Duration(milliseconds: 80));
    }
    await tester.pump(const Duration(milliseconds: 500));
    await gesture.up();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done').last);
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump();
    await flushIo(
        tester,
        () =>
            container
                .read(customStickersProvider('server::7'))
                .requireValue
                .first
                .id ==
            before.last);
    final order = container
        .read(customStickersProvider('server::7'))
        .requireValue
        .map((s) => s.id)
        .toList();
    expect(order, [before.last, before.first, before[1]]);
    await tester.runAsync(() async {
      final reopened = CustomStickerStore(root, 'server::7');
      expect((await reopened.list()).map((s) => s.id), order);
    });
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'oversized import reports an error and an account switch blocks import',
      (tester) async {
    await pump(tester);
    await tester.tap(find.text('Manage'));
    await tester.pump();
    picker.result = FilePickerResult(
        [PlatformFile(name: 'large.gif', size: maxStickerBytes + 1)]);
    await tester.tap(find.text('Import image / GIF'));
    await tester.pumpAndSettle();
    expect(
        find.text('Sticker images must be 10 MB or smaller'), findsOneWidget);
    (container.read(accountStoreProvider.notifier) as _Accounts)
        .switchAccount();
    await tester.tap(find.text('Import image / GIF'));
    await tester.pump();
    expect(picker.calls, 1);
    expect(container.read(customStickersProvider('server::7')).requireValue,
        isEmpty);
    expect(tester.takeException(), isNull);
  });
}
