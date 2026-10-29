import 'dart:io';
import 'package:flutter/foundation.dart';
import 'motion_photo.dart';

Future<MotionPhotoClip?> inspectMotionFile(File file) =>
    compute(_inspect, file.path);

MotionPhotoClip? _inspect(String path) {
  final input = File(path).openSync();
  try {
    return MotionPhoto.inspect(input.lengthSync(), (offset, count) {
      input.setPositionSync(offset);
      return input.readSync(count);
    });
  } finally {
    input.closeSync();
  }
}

/// Only writes the validated movie into the caller's private temporary folder.
/// Parsing and disk work run away from the Flutter UI isolate.
Future<bool> extractMotionMovie(File source, File target) =>
    compute(_extract, [source.path, target.path]);

bool _extract(List<String> paths) {
  final input = File(paths[0]).openSync();
  RandomAccessFile? output;
  try {
    final clip = MotionPhoto.inspect(input.lengthSync(), (offset, count) {
      input.setPositionSync(offset);
      return input.readSync(count);
    });
    if (clip == null) return false;
    output = File(paths[1]).openSync(mode: FileMode.write);
    input.setPositionSync(clip.offset);
    var left = clip.length;
    while (left > 0) {
      final Uint8List chunk = input.readSync(left.clamp(0, 65536));
      if (chunk.isEmpty) {
        throw const FileSystemException('Incomplete motion photo');
      }
      output.writeFromSync(chunk);
      left -= chunk.length;
    }
    return true;
  } catch (_) {
    output?.closeSync();
    output = null;
    final file = File(paths[1]);
    if (file.existsSync()) file.deleteSync();
    rethrow;
  } finally {
    output?.closeSync();
    input.closeSync();
  }
}
