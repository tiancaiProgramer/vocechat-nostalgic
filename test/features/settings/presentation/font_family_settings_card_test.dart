import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vocechat_client/core/theme/app_text_scale.dart';
import 'package:vocechat_client/core/theme/app_theme.dart';
import 'package:vocechat_client/core/theme/font_family_provider.dart';
import 'package:vocechat_client/core/theme/font_size_provider.dart';
import 'package:vocechat_client/features/settings/presentation/font_family_settings_card.dart';
import 'package:vocechat_client/l10n/generated/app_localizations.dart';
import 'package:vocechat_client/shared/widgets/voce_avatar.dart';

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

  Future<ProviderContainer> mount(WidgetTester tester,
      {double width = 390,
      Brightness brightness = Brightness.light,
      Locale locale = const Locale('en')}) async {
    tester.view.physicalSize = Size(width, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: Consumer(builder: (context, ref, _) {
        final system = ref.watch(fontFamilyProvider) == AppFontFamily.system;
        return MaterialApp(
          theme: brightness == Brightness.dark
              ? AppTheme.dark(useSystemFont: system)
              : AppTheme.light(useSystemFont: system),
          locale: locale,
          localizationsDelegates: AppL10n.localizationsDelegates,
          supportedLocales: AppL10n.supportedLocales,
          builder: (context, child) => AppTextScale(child: child!),
          home: Scaffold(
            appBar: AppBar(title: const Text('Chat title')),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                const FontFamilySettingsCard(),
                const Text('Message 文字',
                    key: Key('message'), style: TextStyle(fontSize: 16)),
                const VoceAvatar(name: 'Alan Bob'),
                const TextField(),
                Builder(
                    builder: (context) => TextButton(
                          onPressed: () => showDialog<void>(
                            context: context,
                            builder: (_) =>
                                const AlertDialog(content: Text('Dialog text')),
                          ),
                          child: const Text('Open dialog'),
                        )),
              ]),
            ),
          ),
        );
      }),
    ));
    await tester.pumpAndSettle();
    return container;
  }

  String? renderedFamily(WidgetTester tester, Finder finder) =>
      tester.renderObject<RenderParagraph>(finder).text.style?.fontFamily;

  testWidgets('switch updates messages, title, avatar, input and dialogs live',
      (tester) async {
    SharedPreferences.setMockInitialValues({'app.fontSize.step': 6});
    final container = await mount(tester);
    final message = find.byKey(const Key('message'));
    expect(renderedFamily(tester, message), 'sans-serif');
    await tester.tap(find.byKey(const Key('font-family-bundled')));
    await tester.pumpAndSettle();
    expect(renderedFamily(tester, message), 'Inter');
    expect(renderedFamily(tester, find.text('Chat title')), 'Inter');
    expect(renderedFamily(tester, find.text('AB')), 'Inter');
    expect(
        tester.widget<EditableText>(find.byType(EditableText)).style.fontFamily,
        'Inter');
    expect(renderedFamily(tester, find.text('Open dialog')), 'Inter');
    await tester.tap(find.byKey(const Key('font-family-system')));
    await tester.pumpAndSettle();
    for (final text in ['Chat title', 'AB', 'Open dialog']) {
      expect(renderedFamily(tester, find.text(text)), 'sans-serif');
    }
    expect(container.read(fontSizeProvider), 6);
    final paragraph = tester.renderObject<RenderParagraph>(message);
    expect(paragraph.textScaler.scale(16), closeTo(20.8, .001));
    expect(
        tester.widget<EditableText>(find.byType(EditableText)).style.fontFamily,
        'sans-serif');
    final context = tester.element(message);
    expect(CupertinoTheme.of(context).textTheme.textStyle.fontFamily,
        'sans-serif');
    expect(Theme.of(context).textTheme.bodyMedium!.fontFamilyFallback,
        isNot(contains('Noto Sans CJK SC')));
    await tester.tap(find.text('Open dialog'));
    await tester.pumpAndSettle();
    expect(renderedFamily(tester, find.text('Dialog text')), 'sans-serif');
    expect(tester.takeException(), isNull);
  });

  for (final brightness in Brightness.values) {
    testWidgets('Chinese options fit at 320px and 130% in $brightness',
        (tester) async {
      SharedPreferences.setMockInitialValues({'app.fontSize.step': 6});
      await mount(tester,
          width: 320, brightness: brightness, locale: const Locale('zh'));
      expect(find.text('跟随系统字体'), findsOneWidget);
      expect(find.text('应用默认字体'), findsOneWidget);
      await tester.tap(find.byKey(const Key('font-family-bundled')));
      await tester.pumpAndSettle();
      expect(
          (await SharedPreferences.getInstance()).getString('app.fontFamily'),
          'bundled');
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Apple system typography uses the platform font', (tester) async {
    await mount(tester);
    expect(renderedFamily(tester, find.byKey(const Key('message'))),
        'CupertinoSystemText');
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));
}
