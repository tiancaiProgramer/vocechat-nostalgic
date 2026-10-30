import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocechat_client/features/messages/presentation/file_download_button.dart';
import 'package:vocechat_client/l10n/generated/app_localizations.dart';

Widget host(DownloadAction action) => MaterialApp(
      localizationsDelegates: AppL10n.localizationsDelegates,
      supportedLocales: AppL10n.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(body: FileDownloadButton(onDownload: action)),
    );

void main() {
  testWidgets('shows progress immediately and stays busy until saving finishes',
      (tester) async {
    final result = Completer<bool>();
    late void Function(int, int) progress;
    late VoidCallback saving;
    var calls = 0;
    await tester.pumpWidget(host((onProgress, onSaving) {
      calls++;
      progress = onProgress;
      saving = onSaving;
      return result.future;
    }));
    await tester.tap(find.byType(IconButton));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(
        tester.widget<IconButton>(find.byType(IconButton)).onPressed, isNull);
    progress(25, 100);
    await tester.pump();
    expect(find.text('25%'), findsOneWidget);
    saving();
    await tester.pump();
    expect(find.text('Saving…'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_outline), findsNothing);
    expect(calls, 1);
    result.complete(true);
    await tester.pump();
    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('unknown size shows received bytes and failure allows retry',
      (tester) async {
    final result = Completer<bool>();
    late void Function(int, int) progress;
    var calls = 0;
    await tester.pumpWidget(host((onProgress, _) {
      calls++;
      progress = onProgress;
      return calls == 1 ? result.future : Future.value(true);
    }));
    await tester.tap(find.byType(IconButton));
    progress(2097152, -1);
    await tester.pump();
    expect(find.text('2.0 MB'), findsOneWidget);
    expect(
        tester
            .widget<CircularProgressIndicator>(
                find.byType(CircularProgressIndicator))
            .value,
        isNull);
    result.complete(false);
    await tester.pump();
    expect(find.byIcon(Icons.download_outlined), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_outline), findsNothing);
    await tester.tap(find.byType(IconButton));
    await tester.pump();
    expect(calls, 2);
    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
  });

  testWidgets(
      'completion after leaving the chat does not update disposed state',
      (tester) async {
    final result = Completer<bool>();
    late void Function(int, int) progress;
    late VoidCallback saving;
    await tester.pumpWidget(host((p, s) {
      progress = p;
      saving = s;
      return result.future;
    }));
    await tester.tap(find.byType(IconButton));
    await tester.pumpWidget(const SizedBox());
    progress(50, 100);
    saving();
    result.complete(true);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
