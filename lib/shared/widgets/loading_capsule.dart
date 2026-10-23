import 'dart:async';

import 'package:flutter/material.dart';

/// A translucent pill-shaped loading indicator.
///
/// Used to signal background refreshes WITHOUT covering the underlying content
/// — the cached UI stays visible and the capsule sits in a corner where it
/// can be ignored. Replaces the full-screen [CircularProgressIndicator] for
/// first-paint scenarios where we already have a cached snapshot to render.
class LoadingCapsule extends StatelessWidget {
  const LoadingCapsule({
    super.key,
    required this.label,
    this.compact = false,
    this.subtle = false,
  });

  final String label;
  final bool compact;

  /// When true, show only small, muted text for a corner status indicator.
  final bool subtle;

  @override
  Widget build(BuildContext context) {
    if (subtle) {
      final foreground = Theme.of(context).colorScheme.onSurfaceVariant;
      return IgnorePointer(
        child: Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 10,
            color: foreground.withValues(alpha: .65),
            height: 1.4,
          ),
        ),
      );
    }

    final pad = compact
        ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
        : const EdgeInsets.symmetric(horizontal: 14, vertical: 8);
    final spinnerSize = compact ? 12.0 : 14.0;
    final fontSize = compact ? 11.0 : 12.0;

    const bg = Color(0xCC1F2937);
    const fg = Colors.white;

    return IgnorePointer(
      ignoring: true,
      child: Container(
        padding: pad,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: spinnerSize,
              height: spinnerSize,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(fg),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w500,
                color: fg,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Convenience overlay positioning the capsule discreetly at the bottom-right
/// of its parent. Uses small, muted text without a pill or spinner.
///
/// Failsafe: if [visible] stays true past [maxVisibleDuration] the capsule
/// fades out anyway. A background refresh that genuinely runs that long has
/// stopped being useful signal, and a latched refreshing flag (provider torn
/// down mid-refresh, unawaited error path) must not read as "stuck updating".
class LoadingCapsuleOverlay extends StatefulWidget {
  const LoadingCapsuleOverlay({
    super.key,
    required this.visible,
    required this.label,
    this.bottomPadding = 10,
    this.rightPadding = 12,
    this.maxVisibleDuration = const Duration(seconds: 25),
  });

  final bool visible;
  final String label;
  final double bottomPadding;
  final double rightPadding;
  final Duration maxVisibleDuration;

  @override
  State<LoadingCapsuleOverlay> createState() => _LoadingCapsuleOverlayState();
}

class _LoadingCapsuleOverlayState extends State<LoadingCapsuleOverlay> {
  Timer? _failsafe;
  bool _expired = false;

  @override
  void initState() {
    super.initState();
    if (widget.visible) _armFailsafe();
  }

  @override
  void didUpdateWidget(covariant LoadingCapsuleOverlay old) {
    super.didUpdateWidget(old);
    if (widget.visible != old.visible) {
      if (widget.visible) {
        // A new refresh cycle starts a fresh timeout window.
        _expired = false;
        _armFailsafe();
      } else {
        _failsafe?.cancel();
        _failsafe = null;
        _expired = false;
      }
    }
  }

  void _armFailsafe() {
    _failsafe?.cancel();
    _failsafe = Timer(widget.maxVisibleDuration, () {
      if (mounted) setState(() => _expired = true);
    });
  }

  @override
  void dispose() {
    _failsafe?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final show = widget.visible && !_expired;
    return Positioned(
      right: widget.rightPadding,
      bottom: widget.bottomPadding,
      child: IgnorePointer(
        ignoring: true,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 220),
          opacity: show ? 1 : 0,
          child: TickerMode(
            enabled: show,
            child: LoadingCapsule(label: widget.label, subtle: true),
          ),
        ),
      ),
    );
  }
}
