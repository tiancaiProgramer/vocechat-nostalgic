import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vocechat_client/main.dart';
import 'package:vocechat_client/core/theme/system_font_provider.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(ProviderScope(overrides: [
      systemFontResolverProvider.overrideWithValue(_NoDeviceFonts()),
    ], child: const VoceChatApp()));
    expect(find.byType(VoceChatApp), findsOneWidget);
  });
}

// Native font data is covered by system_font_test; this test runs without Android.
class _NoDeviceFonts extends SystemFontResolver {
  @override
  Future<SystemFontSelection> resolve() async => const SystemFontSelection();
}
