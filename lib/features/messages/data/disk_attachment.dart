import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'attachment_preparer.dart';
import 'message_api.dart';
import 'motion_photo.dart';
import 'motion_photo_io.dart';

/// Detach a shared cache file from the native share lease before acknowledging
/// it. Renaming within app cache avoids a second whole-file copy.
Future<File> retainSharedAttachment(File source) async {
  final cache = await getTemporaryDirectory();
  final directory = await Directory(cache.path).createTemp('voce-shared-');
  final path = '${directory.path}/attachment';
  try {
    final nativeRoot = Directory('${cache.path}/incoming-shares').absolute.path;
    if (source.absolute.path.startsWith(
      '$nativeRoot${Platform.pathSeparator}',
    )) {
      try {
        return await source.rename(path);
      } on FileSystemException {
        /* Copy below. */
      }
    }
    return await source.copy(path);
  } catch (_) {
    await directory.delete(recursive: true);
    rethrow;
  }
}

/// Only call for files explicitly owned by this client's attachment staging.
Future<void> discardOwnedAttachment(File file) async {
  try {
    if (await file.exists()) await file.delete();
  } catch (_) {}
  try {
    await file.parent.delete();
  } catch (_) {} // Never remove nonempty folders.
}

class PreparedDiskAttachment {
  const PreparedDiskAttachment(
    this.file,
    this.filename,
    this.contentType, {
    this.temporary = false,
    this.isMotionPhoto = false,
  });
  final File file;
  final String filename, contentType;
  final bool temporary, isMotionPhoto;
}

Future<PreparedDiskAttachment> prepareDiskAttachment(
  File file,
  String filename, {
  String? contentType,
}) async {
  final reader = await file.open();
  late final Uint8List prefix;
  try {
    prefix = await reader.read(512);
  } finally {
    await reader.close();
  }
  final type =
      contentType ?? MessageApi.inferContentType(filename, bytes: prefix);
  final name = MessageApi.resolveFilename(
    filename,
    bytes: prefix,
    contentType: type,
  );
  if (AttachmentPreparer.requiresConversion(prefix, name, type)) {
    if (await file.length() > MotionPhoto.maxBytes) {
      throw const FormatException(
        'HEIF conversion exceeds the image processing limit',
      );
    }
    final prepared = await AttachmentPreparer.prepare(
      bytes: await file.readAsBytes(),
      filename: name,
      contentType: type,
    );
    final cache = await getTemporaryDirectory();
    final directory = await Directory(cache.path).createTemp('voce-converted-');
    final result = File(
      '${directory.path}/image.${prepared.filename.split('.').last}',
    );
    try {
      await result.writeAsBytes(prepared.bytes, flush: true);
    } catch (_) {
      await directory.delete(recursive: true);
      rethrow;
    }
    return PreparedDiskAttachment(
      result,
      prepared.filename,
      prepared.contentType ?? type,
      temporary: true,
      isMotionPhoto: prepared.isMotionPhoto,
    );
  }
  return PreparedDiskAttachment(
    file,
    name,
    type,
    isMotionPhoto:
        type.startsWith('image/') && await inspectMotionFile(file) != null,
  );
}
