import 'dart:async';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'font_family_provider.dart';
import 'system_font_data.dart';

class SystemFontSelection {
  const SystemFontSelection(
      {this.family, this.fallback = const [], this.failed = false});
  final String? family;
  final List<String> fallback;
  final bool failed;
}

typedef SystemFontRegistrar = Future<void> Function(
    String family, Uint8List data);

/// Separate bridge and registrar make actual byte loading independently testable.
class SystemFontResolver {
  SystemFontResolver({
    MethodChannel? channel,
    SystemFontRegistrar? register,
    Future<Uint8List> Function((Uint8List, int))? prepare,
  })  : channel = channel ?? const MethodChannel('vocechat/system_font'),
        register = register ?? _register,
        prepare = prepare ?? ((input) => compute(standaloneSystemFont, input));

  final MethodChannel channel;
  final SystemFontRegistrar register;
  final Future<Uint8List> Function((Uint8List, int)) prepare;
  final _loaded = <String, String>{};

  static Future<void> _register(String family, Uint8List data) {
    final loader = FontLoader(family)
      ..addFont(Future.value(ByteData.sublistView(data)));
    return loader.load();
  }

  Future<SystemFontSelection> resolve() async {
    final values = await channel
        .invokeListMethod<dynamic>('describe')
        .timeout(const Duration(seconds: 4));
    if (values == null || values.length > 2) {
      throw const FormatException('Invalid system font descriptors');
    }
    final families = <String>[];
    var total = 0;
    for (final value in values) {
      if (value is! Map) {
        throw const FormatException('Invalid system font');
      }
      final id = value['id'];
      final size = value['size'];
      final index = value['index'];
      if (id is! String ||
          !RegExp(r'^[a-f0-9]{64}$').hasMatch(id) ||
          size is! int ||
          size < 12 ||
          size > 48 * 1024 * 1024 ||
          index is! int ||
          index < 0 ||
          index > 1023) {
        throw const FormatException('Invalid system font descriptor');
      }
      total += size;
      if (total > 64 * 1024 * 1024) {
        throw const FormatException('System fonts too large');
      }
      var family = _loaded[id];
      if (family == null) {
        final bytes = await channel.invokeMethod<Uint8List>(
            'read', {'id': id}).timeout(const Duration(seconds: 8));
        if (bytes == null || bytes.length != size) {
          throw const FormatException('Incomplete system font');
        }
        final font = await prepare((bytes, index));
        // A new alias forces existing paragraphs to lay out with new font data.
        family = 'VoceSystem_${sha256.convert(id.codeUnits)}';
        await register(family, font).timeout(const Duration(seconds: 8));
        _loaded[id] = family;
        try {
          await channel.invokeMethod<void>(
              'loaded', {'id': id}).timeout(const Duration(seconds: 1));
        } catch (_) {
          // Optional native diagnostic acknowledgement must not undo loading.
        }
      }
      if (!families.contains(family)) families.add(family);
    }
    return families.isEmpty
        ? const SystemFontSelection()
        : SystemFontSelection(
            family: families.first,
            fallback: [...families.skip(1), 'sans-serif']);
  }
}

final systemFontResolverProvider = Provider((ref) => SystemFontResolver());
final systemFontProvider =
    NotifierProvider<SystemFontNotifier, SystemFontSelection>(
        SystemFontNotifier.new);

class SystemFontNotifier extends Notifier<SystemFontSelection> {
  bool _disposed = false;
  Future<void>? _pending;

  @override
  SystemFontSelection build() {
    final lifecycle = AppLifecycleListener(onResume: _refreshIfSystem);
    ref.onDispose(() {
      _disposed = true;
      lifecycle.dispose();
    });
    ref.listen(fontFamilyProvider, (_, next) {
      if (next == AppFontFamily.system) _refreshIfSystem();
    });
    scheduleMicrotask(_refreshIfSystem);
    return const SystemFontSelection();
  }

  void _refreshIfSystem() {
    if (!_disposed &&
        !kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android &&
        ref.read(fontFamilyProvider) == AppFontFamily.system) {
      unawaited(refresh());
    }
  }

  Future<void> refresh() =>
      _pending ??= _refresh().whenComplete(() => _pending = null);

  Future<void> _refresh() async {
    try {
      final selected = await ref.read(systemFontResolverProvider).resolve();
      if (!_disposed) state = selected;
    } catch (_) {
      // Do not hold startup or render an empty screen if OEM font access fails.
      if (!_disposed) state = const SystemFontSelection(failed: true);
    }
  }
}
