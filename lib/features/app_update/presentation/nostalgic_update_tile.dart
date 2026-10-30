import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/config/distribution.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../settings/application/app_info_provider.dart';
import '../application/app_update_provider.dart';
import '../data/nostalgic_github_update.dart';
import 'apk_download_panel.dart';

final aboutLinkLauncherProvider = Provider<Future<bool> Function(Uri)>(
    (ref) => (uri) => launchUrl(uri, mode: LaunchMode.externalApplication));

Future<void> openAboutLink(BuildContext context, WidgetRef ref, Uri uri) async {
  try {
    if (!await ref.read(aboutLinkLauncherProvider)(uri))
      throw StateError('open failed');
  } catch (_) {
    if (context.mounted)
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppL10n.of(context).appUpdateOpenFailed)));
  }
}

class NostalgicUpdateTile extends ConsumerStatefulWidget {
  const NostalgicUpdateTile({super.key});
  @override
  ConsumerState<NostalgicUpdateTile> createState() =>
      _NostalgicUpdateTileState();
}

class _NostalgicUpdateTileState extends ConsumerState<NostalgicUpdateTile> {
  bool _busy = false;
  String? _message;
  CancelToken? _cancel;
  @override
  void dispose() {
    _cancel?.cancel('Page closed');
    super.dispose();
  }

  Future<void> _check() async {
    if (_busy) return;
    final l = AppL10n.of(context);
    final cancel = _cancel = CancelToken();
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final latest = await (() async {
        final installed = await ref.read(appPackageInfoProvider.future);
        final build = int.tryParse(installed.buildNumber);
        if (build == null || build <= 0)
          throw const FormatException('Invalid installed build');
        final release =
            await ref.read(nostalgicGithubUpdateProvider).latest(cancel);
        return (build: build, release: release);
      })()
          .timeout(const Duration(seconds: 20), onTimeout: () {
        cancel.cancel('Update check timed out');
        throw TimeoutException('Update check timed out');
      });
      if (!mounted) return;
      final release = latest.release;
      if (release == null) {
        setState(() => _message = l.aboutNoRelease);
        return;
      }
      if (release.build <= latest.build) {
        setState(() => _message = l.aboutUpToDate(release.version));
        return;
      }
      setState(() => _busy = false);
      await showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
                title: Text(l.appUpdateTitle(release.version)),
                content: SingleChildScrollView(
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      if (release.notes.trim().isNotEmpty) ...[
                        SelectableText(release.notes),
                        const SizedBox(height: 16),
                      ],
                      if (ref.read(androidUpdateSupportedProvider) &&
                          release.android != null)
                        ApkDownloadPanel(release: release.android!),
                    ])),
                actions: [
                  TextButton(
                      onPressed: () =>
                          openAboutLink(dialogContext, ref, release.page),
                      child: Text(l.aboutViewRelease)),
                  TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: Text(l.actionClose)),
                ],
              ));
    } catch (_) {
      if (mounted) setState(() => _message = l.aboutUpdateCheckFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!supportsDirectDistributionFeatures) return const SizedBox.shrink();
    final l = AppL10n.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Divider(),
      ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(l.aboutCheckUpdates),
        subtitle: Text(l.aboutGithubUpdateSource),
        trailing: _busy
            ? const SizedBox.square(
                dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.chevron_right),
        onTap: _busy ? null : _check,
      ),
      if (_message != null)
        Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(_message!,
                style: TextStyle(fontSize: 13, color: AppTokens.textMuted))),
    ]);
  }
}
