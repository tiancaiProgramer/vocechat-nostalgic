import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vocechat_client/core/theme/font_family_provider.dart';
import 'package:vocechat_client/core/theme/system_font_data.dart';
import 'package:vocechat_client/core/theme/system_font_provider.dart';

Uint8List collection() {
  final bytes = Uint8List(140);
  final data = ByteData.sublistView(bytes);
  data.setUint32(0, 0x74746366);
  data.setUint32(4, 0x00010000);
  data.setUint32(8, 2);
  data.setUint32(12, 20);
  data.setUint32(16, 64);
  for (var i = 0; i < 2; i++) {
    final offset = 20 + i * 44;
    data.setUint32(offset, 0x00010000);
    data.setUint16(offset + 4, 2);
    data.setUint16(offset + 6, 32);
    data.setUint16(offset + 8, 1);
    data.setUint32(offset + 12, 0x68656164);
    data.setUint32(offset + 20, 108 + i * 12);
    data.setUint32(offset + 24, 12);
    data.setUint32(offset + 28, 0x6e616d65);
    data.setUint32(offset + 36, 132 + i * 4);
    data.setUint32(offset + 40, 4);
    data.setUint32(132 + i * 4, i + 1);
  }
  return bytes;
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('vocechat/system_font');
  const idA =
      'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
  const idB =
      'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() =>
      binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null));

  test('TTC extraction keeps the selected face and recalculates checksums', () {
    final bytes = standaloneSystemFont((collection(), 1));
    final data = ByteData.sublistView(bytes);
    expect(data.getUint32(0), 0x00010000);
    expect(data.getUint16(4), 2);
    expect(data.getUint32(data.getUint32(36)), 2);
    var sum = 0;
    for (var p = 0; p < bytes.length; p += 4) {
      sum = (sum + data.getUint32(p)) & 0xffffffff;
    }
    expect(sum, 0xb1b0afba);
    expect(standaloneSystemFont((bytes, 0)), same(bytes));
  });

  test('invalid face and truncated table bounds are rejected', () {
    expect(
        () => standaloneSystemFont((collection(), 2)), throwsFormatException);
    final broken = collection();
    ByteData.sublistView(broken).setUint32(40, 999999);
    expect(() => standaloneSystemFont((broken, 0)), throwsFormatException);
    expect(
        () => standaloneSystemFont((Uint8List(8), 0)), throwsFormatException);
    final font = standaloneSystemFont((collection(), 0));
    expect(() => standaloneSystemFont((font, 1)), throwsFormatException);
    ByteData.sublistView(font).setUint32(0, 0x12345678);
    expect(() => standaloneSystemFont((font, 0)), throwsFormatException);
  });

  test(
      'loads font bytes once, changes alias on replacement, and clears on removal',
      () async {
    var id = idA;
    var present = true;
    var reads = 0;
    final registered = <String>[];
    final font = standaloneSystemFont((collection(), 0));
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel,
        (call) async {
      switch (call.method) {
        case 'describe':
          return present
              ? [
                  {'id': id, 'size': font.length, 'index': 0}
                ]
              : [];
        case 'read':
          reads++;
          return font;
        case 'loaded':
          return null;
      }
      throw MissingPluginException();
    });
    final resolver = SystemFontResolver(
      prepare: (input) async => standaloneSystemFont(input),
      register: (family, data) async {
        registered.add(family);
        expect(data, font);
      },
    );
    final first = await resolver.resolve();
    expect(first.family, startsWith('VoceSystem_'));
    expect((await resolver.resolve()).family, first.family);
    expect(reads, 1);
    id = idB;
    expect((await resolver.resolve()).family, isNot(first.family));
    expect(registered.length, 2);
    present = false;
    expect((await resolver.resolve()).family, isNull);
  });

  test('keeps CJK as a separate fallback instead of losing it', () async {
    final bytes = standaloneSystemFont((collection(), 0));
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel,
        (call) async {
      if (call.method == 'describe') {
        return [
          {'id': idA, 'size': bytes.length, 'index': 0},
          {'id': idB, 'size': bytes.length, 'index': 0},
        ];
      }
      if (call.method == 'read') return bytes;
      return null;
    });
    final result = await SystemFontResolver(
            prepare: (input) async => input.$1, register: (_, __) async {})
        .resolve();
    expect(result.fallback.length, 2);
    expect(result.fallback.first, startsWith('VoceSystem_'));
    expect(result.fallback.first, isNot(result.family));
    expect(result.fallback.last, 'sans-serif');
  });

  test('truncated native bytes fail, and a later attempt can recover',
      () async {
    final bytes = standaloneSystemFont((collection(), 0));
    var broken = true;
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel,
        (call) async {
      if (call.method == 'describe') {
        return [
          {'id': idA, 'size': bytes.length, 'index': 0}
        ];
      }
      if (call.method == 'read') return broken ? Uint8List(8) : bytes;
      return null;
    });
    final resolver = SystemFontResolver(
        prepare: (input) async => input.$1, register: (_, __) async {});
    await expectLater(resolver.resolve(), throwsFormatException);
    broken = false;
    expect((await resolver.resolve()).family, isNotNull);
  });

  testWidgets('registered bytes actually change rendered glyph metrics',
      (tester) async {
    final asset = await rootBundle.load('assets/fonts/Inter-Variable.ttf');
    final bytes =
        asset.buffer.asUint8List(asset.offsetInBytes, asset.lengthInBytes);
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel,
        (call) async {
      if (call.method == 'describe') {
        return [
          {'id': idA, 'size': bytes.length, 'index': 0}
        ];
      }
      if (call.method == 'read') return bytes;
      return null;
    });
    late SystemFontSelection selection;
    await tester.runAsync(() async {
      selection = await SystemFontResolver().resolve();
    });
    double width(String family) {
      final painter = TextPainter(
          text: TextSpan(
              text: 'iiiiiiii',
              style: TextStyle(fontFamily: family, fontSize: 20)),
          textDirection: TextDirection.ltr)
        ..layout();
      final value = painter.width;
      painter.dispose();
      return value;
    }

    expect(selection.family, isNotNull);
    expect(width(selection.family!), lessThan(width('Ahem') * .75));
  });

  testWidgets(
      'refreshes on resume and switching back to system, but not bundled mode',
      (tester) async {
    final resolver = _FakeResolver();
    final container = ProviderContainer(
        overrides: [systemFontResolverProvider.overrideWithValue(resolver)]);
    addTearDown(container.dispose);
    container.read(systemFontProvider);
    await tester.pump();
    await container.read(systemFontProvider.notifier).refresh();
    final initial = resolver.calls;
    for (final state in [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed
    ]) {
      binding.handleAppLifecycleStateChanged(state);
    }
    await tester.pump();
    expect(resolver.calls, initial + 1);
    await tester.runAsync(() => container
        .read(fontFamilyProvider.notifier)
        .select(AppFontFamily.bundled));
    for (final state in [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed
    ]) {
      binding.handleAppLifecycleStateChanged(state);
    }
    await tester.pump();
    expect(resolver.calls, initial + 1);
    await tester.runAsync(() => container
        .read(fontFamilyProvider.notifier)
        .select(AppFontFamily.system));
    await tester.pump();
    expect(resolver.calls, initial + 2);
  });

  testWidgets('permission failure falls back without blocking and can retry',
      (tester) async {
    final resolver = _FakeResolver()..fail = true;
    final container = ProviderContainer(
        overrides: [systemFontResolverProvider.overrideWithValue(resolver)]);
    addTearDown(container.dispose);
    expect(container.read(systemFontProvider).family, isNull);
    await tester.pump();
    await container.read(systemFontProvider.notifier).refresh();
    expect(container.read(systemFontProvider).failed, isTrue);
    resolver.fail = false;
    await container.read(systemFontProvider.notifier).refresh();
    expect(container.read(systemFontProvider).family, 'native-family');
    expect(container.read(systemFontProvider).failed, isFalse);
  });

  testWidgets('an in-flight load can finish after disposal safely',
      (tester) async {
    final resolver = _FakeResolver()
      ..pending = Completer<SystemFontSelection>();
    final container = ProviderContainer(
        overrides: [systemFontResolverProvider.overrideWithValue(resolver)]);
    container.read(systemFontProvider);
    final pending = container.read(systemFontProvider.notifier).refresh();
    container.dispose();
    resolver.pending!.complete(const SystemFontSelection(family: 'late-font'));
    await pending;
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}

class _FakeResolver extends SystemFontResolver {
  int calls = 0;
  bool fail = false;
  Completer<SystemFontSelection>? pending;
  @override
  Future<SystemFontSelection> resolve() async {
    calls++;
    if (fail) throw PlatformException(code: 'font_unavailable');
    return pending?.future ??
        const SystemFontSelection(family: 'native-family');
  }
}
