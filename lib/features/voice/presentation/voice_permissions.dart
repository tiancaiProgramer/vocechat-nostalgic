import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

final voicePermissionRequestProvider =
    Provider<Future<bool> Function(Permission)>((ref) => (permission) async {
          if (!kIsWeb &&
              (defaultTargetPlatform == TargetPlatform.windows ||
                  defaultTargetPlatform == TargetPlatform.linux)) return true;
          return permission.request().isGranted;
        });
