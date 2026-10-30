import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/generated/app_localizations.dart';

typedef DownloadAction = Future<bool> Function(
  void Function(int received, int total) onProgress,
  VoidCallback onSaving,
);

/// Keeps download feedback visible until saving to shared storage completes.
class FileDownloadButton extends StatefulWidget {
  const FileDownloadButton({super.key, required this.onDownload});

  final DownloadAction onDownload;

  @override
  State<FileDownloadButton> createState() => _FileDownloadButtonState();
}

class _FileDownloadButtonState extends State<FileDownloadButton> {
  bool _busy = false;
  bool _saving = false;
  bool _saved = false;
  int _received = 0;
  int _total = 0;

  Future<void> _download() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _saving = false;
      _saved = false;
      _received = 0;
      _total = 0;
    });
    var saved = false;
    try {
      saved = await widget.onDownload((received, total) {
        if (!mounted) return;
        setState(() {
          _received = received;
          _total = total;
        });
      }, () {
        if (mounted) setState(() => _saving = true);
      });
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _saved = saved;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final fraction = _total > 0 ? (_received / _total).clamp(0.0, 1.0) : null;
    final status = _saving
        ? l.downloadSaving
        : '${l.downloadInProgress} ${fraction == null ? '${(_received / 1048576).toStringAsFixed(1)} MB' : '${(fraction * 100).floor()}%'}';
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip:
              _busy ? status : (_saved ? l.downloadSaved : l.tooltipDownload),
          onPressed: _busy ? null : _download,
          icon: _busy
              ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    value: _saving ? null : fraction,
                  ),
                )
              : Icon(
                  _saved ? Icons.check_circle_outline : Icons.download_outlined,
                  color: _saved ? AppTokens.primary500 : AppTokens.gray500,
                  size: 22,
                ),
        ),
        if (_busy)
          Text(
            _saving
                ? l.downloadSaving
                : (fraction == null
                    ? '${(_received / 1048576).toStringAsFixed(1)} MB'
                    : '${(fraction * 100).floor()}%'),
            style: TextStyle(fontSize: 10, color: AppTokens.gray500),
          ),
      ],
    );
  }
}
