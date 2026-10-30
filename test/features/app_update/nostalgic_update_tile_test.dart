import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:vocechat_client/features/app_update/data/nostalgic_github_update.dart';
import 'package:vocechat_client/features/app_update/presentation/nostalgic_update_tile.dart';
import 'package:vocechat_client/features/settings/application/app_info_provider.dart';
import 'package:vocechat_client/l10n/generated/app_localizations.dart';

class _Api extends NostalgicGithubUpdate {
  _Api(this.action) : super(Dio());
  final Future<NostalgicGithubRelease?> Function(CancelToken) action;
  @override
  Future<NostalgicGithubRelease?> latest(CancelToken cancel) => action(cancel);
}

Widget host(_Api api, {Future<bool> Function(Uri)? open}) => ProviderScope(
        overrides: [
          nostalgicGithubUpdateProvider.overrideWithValue(api),
          appPackageInfoProvider.overrideWith((ref) async => PackageInfo(
              appName: 'vocechat怀旧版',
              packageName: 'com.privoce.vocechatclient.legacyui',
              version: '0.3.35-r9',
              buildNumber: '3130')),
          if (open != null) aboutLinkLauncherProvider.overrideWithValue(open),
        ],
        child: MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: AppL10n.localizationsDelegates,
            supportedLocales: AppL10n.supportedLocales,
            home: const Scaffold(body: NostalgicUpdateTile())));
void main() {
  testWidgets(
      'checks only on tap and reports newer local version without downgrading',
      (tester) async {
    var calls = 0;
    await tester.pumpWidget(host(_Api((_) async {
      calls++;
      return NostalgicGithubRelease(
          version: '0.3.33-r6',
          page: nostalgicProjectUrl,
          notes: 'old',
          build: 3127);
    })));
    await tester.pump();
    expect(calls, 0);
    await tester.tap(find.text('Check for updates'));
    await tester.pumpAndSettle();
    expect(calls, 1);
    expect(find.textContaining('Your version is up to date'), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
  });
  testWidgets('failure stops spinner and retry succeeds', (tester) async {
    var calls = 0;
    await tester.pumpWidget(host(_Api((_) async {
      if (++calls == 1) throw StateError('offline');
      return null;
    })));
    await tester.tap(find.text('Check for updates'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Could not check'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await tester.tap(find.text('Check for updates'));
    await tester.pumpAndSettle();
    expect(find.text('No published releases yet.'), findsOneWidget);
  });
  testWidgets('closing page cancels an outstanding request', (tester) async {
    final gate = Completer<NostalgicGithubRelease?>();
    late CancelToken cancel;
    await tester.pumpWidget(host(_Api((c) {
      cancel = c;
      return gate.future;
    })));
    await tester.tap(find.text('Check for updates'));
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    expect(cancel.isCancelled, isTrue);
    gate.complete(null);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
  testWidgets('new release shows notes and uses the owned GitHub page',
      (tester) async {
    Uri? opened;
    await tester.pumpWidget(host(
        _Api((_) async => NostalgicGithubRelease(
            version: '0.3.35-r10',
            page: nostalgicProjectUrl,
            notes: 'Release details',
            build: 3131)), open: (uri) async {
      opened = uri;
      return true;
    }));
    await tester.tap(find.text('Check for updates'));
    await tester.pumpAndSettle();
    expect(find.text('Release details'), findsOneWidget);
    await tester.tap(find.text('View on GitHub'));
    await tester.pump();
    expect(opened, nostalgicProjectUrl);
  });
}
