import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'preference_write.dart';

/// A stable login device for this installation. The server associates event
/// subscriptions and logout with this ID, so sharing "flutter" with other
/// phones or VoceChat variants lets one session invalidate another's stream.
final loginDeviceIdProvider = FutureProvider<String>((ref) async {
  final preferences = await SharedPreferences.getInstance();
  const key = 'legacy_login_device_id_v1';
  final saved = preferences.getString(key);
  if (saved != null &&
      RegExp(r'^vocechat-legacy-[0-9a-f]{32}$').hasMatch(saved)) {
    return saved;
  }

  final random = Random.secure();
  final suffix = List.generate(16, (_) => random.nextInt(256))
      .map((value) => value.toRadixString(16).padLeft(2, '0'))
      .join();
  final device = 'vocechat-legacy-$suffix';
  await requirePreferenceWrite(preferences, preferences.setString(key, device));
  return device;
});
