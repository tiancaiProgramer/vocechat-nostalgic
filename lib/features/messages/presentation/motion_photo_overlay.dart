import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/account_store.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../data/motion_photo.dart';
import '../data/motion_photo_io.dart';

/// Probes only when the user opens an image. Temporary extracted movies are
/// removed on close; ephemeral messages never enter the persistent file cache.
class MotionPhotoOverlay extends ConsumerStatefulWidget {
  const MotionPhotoOverlay(
      {super.key,
      required this.originUrl,
      required this.headers,
      required this.cacheMedia,
      this.cacheKey,
      this.hint = false});
  final String originUrl;
  final Map<String, String> headers;
  final bool cacheMedia, hint;
  final String? cacheKey;
  @override
  ConsumerState<MotionPhotoOverlay> createState() => _MotionPhotoOverlayState();
}

class _MotionPhotoOverlayState extends ConsumerState<MotionPhotoOverlay>
    with WidgetsBindingObserver {
  VideoPlayerController? _controller;
  Directory? _temporary;
  CancelToken? _cancel;
  bool _loading = false, _failed = false, _playing = false, _muted = true;
  int _generation = 0;
  bool _knownMotion = false;

  @override
  void initState() {
    super.initState();
    _knownMotion = widget.hint;
    WidgetsBinding.instance.addObserver(this);
    unawaited(_load());
  }

  Future<void> _load() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _failed = false;
    });
    final generation = ++_generation;
    final cancel = _cancel = CancelToken();
    Directory? temporary;
    VideoPlayerController? candidate;
    bool current() => mounted && generation == _generation;
    try {
      final dio = ref.read(dioProvider);
      final root = await getTemporaryDirectory();
      temporary = await Directory(root.path).createTemp('voce-live-');
      if (!current()) return;
      File source;
      if (widget.cacheMedia) {
        source = await DefaultCacheManager().getSingleFile(widget.originUrl,
            key: widget.cacheKey ?? widget.originUrl, headers: widget.headers);
      } else {
        source = File('${temporary.path}/original');
        await dio.download(widget.originUrl, source.path,
            cancelToken: cancel,
            options: Options(headers: widget.headers, followRedirects: false),
            onReceiveProgress: (received, total) {
          if (received > MotionPhoto.maxBytes || total > MotionPhoto.maxBytes) {
            cancel.cancel();
          }
        });
      }
      if (!current()) return;
      final movie = File('${temporary.path}/live.mov');
      final extracted = await extractMotionMovie(source, movie);
      if (!current() || !extracted) {
        if (current() && _knownMotion) _failed = true;
        return;
      }
      _knownMotion = true;
      candidate = VideoPlayerController.file(movie);
      await candidate.initialize().timeout(const Duration(seconds: 15));
      if (!current()) return;
      await candidate.setVolume(0);
      _controller = candidate;
      _temporary = temporary;
      temporary = null;
      candidate = null;
      _controller!.addListener(_videoChanged);
      if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
        _playing = true;
        await _controller!.play();
      }
    } catch (_) {
      if (current()) {
        _failed = _knownMotion;
        _playing = false;
      }
    } finally {
      await candidate?.dispose();
      if (temporary != null) await _remove(temporary);
      if (current()) setState(() => _loading = false);
    }
  }

  void _videoChanged() {
    final controller = _controller;
    if (!mounted || controller == null) return;
    if (controller.value.hasError) {
      setState(() {
        _playing = false;
        _failed = true;
      });
    } else if (_playing &&
        controller.value.duration > Duration.zero &&
        controller.value.position >= controller.value.duration) {
      setState(() => _playing = false);
    }
  }

  Future<void> _toggle() async {
    try {
      if (_failed) {
        final previous = _controller, temporary = _temporary;
        _controller = null;
        _temporary = null;
        previous?.removeListener(_videoChanged);
        await previous?.dispose();
        if (temporary != null) await _remove(temporary);
        if (!mounted) return;
        await _load();
        return;
      }
      final controller = _controller;
      if (controller == null) {
        setState(() {});
        await _load();
        return;
      }
      if (_playing) {
        await controller.pause();
        if (mounted) setState(() => _playing = false);
      } else {
        await controller.seekTo(Duration.zero);
        await controller.play();
        if (mounted) setState(() => _playing = true);
      }
    } catch (_) {
      if (mounted)
        setState(() {
          _failed = _knownMotion;
          _playing = false;
        });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      unawaited(_controller?.pause() ?? Future.value());
      if (mounted) setState(() => _playing = false);
    }
  }

  static Future<void> _remove(Directory directory) async {
    try {
      if (await directory.exists()) await directory.delete(recursive: true);
    } catch (_) {}
  }

  @override
  void dispose() {
    ++_generation;
    _cancel?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    final controller = _controller, temporary = _temporary;
    controller?.removeListener(_videoChanged);
    unawaited(
        (controller?.dispose() ?? Future<void>.value()).whenComplete(() async {
      if (temporary != null) await _remove(temporary);
    }));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(accountStoreProvider, (before, after) {
      if (before?.valueOrNull?.currentAccountId !=
          after.valueOrNull?.currentAccountId) {
        ++_generation;
        _cancel?.cancel();
        unawaited(_controller?.pause() ?? Future.value());
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) Navigator.of(context).maybePop();
        });
      }
    });
    final l = AppL10n.of(context), controller = _controller;
    return Stack(children: [
      if (_playing && controller != null)
        Positioned.fill(
            child: ColoredBox(
                color: Colors.black,
                child: Center(
                    child: AspectRatio(
                        aspectRatio: controller.value.aspectRatio,
                        child: VideoPlayer(controller))))),
      if (controller != null || _knownMotion && (_loading || _failed))
        Positioned(
          left: 16,
          bottom: 24,
          child: SafeArea(
              child: Material(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(24),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    TextButton.icon(
                        onPressed: _loading ? null : _toggle,
                        icon: _loading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : Icon(
                                _failed
                                    ? Icons.refresh
                                    : _playing
                                        ? Icons.pause
                                        : Icons.motion_photos_on_outlined,
                                color: Colors.white),
                        label: Text(
                            _failed ? l.livePhotoRetry : l.livePhotoLabel,
                            style: const TextStyle(color: Colors.white))),
                    if (controller != null && !_failed)
                      IconButton(
                          tooltip: l.livePhotoSound,
                          onPressed: () async {
                            await controller.setVolume(_muted ? 1 : 0);
                            if (mounted) setState(() => _muted = !_muted);
                          },
                          icon: Icon(
                              _muted
                                  ? Icons.volume_off_outlined
                                  : Icons.volume_up_outlined,
                              color: Colors.white)),
                  ]))),
        ),
    ]);
  }
}
