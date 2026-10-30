import 'dart:typed_data';

/// Flutter loads face zero from a collection. Extract the face Android selected
/// so a Chinese/Korean TTC cannot silently turn into its Japanese first face.
Uint8List standaloneSystemFont((Uint8List, int) input) {
  final (bytes, index) = input;
  if (bytes.length < 12 || bytes.length > 48 * 1024 * 1024 || index < 0) {
    throw const FormatException('Invalid system font');
  }
  final data = ByteData.sublistView(bytes);
  const collectionTag = 0x74746366;
  const ottoTag = 0x4f54544f;
  const headTag = 0x68656164;
  final collection = data.getUint32(0) == collectionTag;
  var face = 0;
  if (collection) {
    final count = data.getUint32(8);
    if (count == 0 ||
        count > 1024 ||
        index >= count ||
        12 + count * 4 > bytes.length) {
      throw const FormatException('Invalid font collection');
    }
    face = data.getUint32(12 + index * 4);
  } else if (index != 0) {
    throw const FormatException('Invalid font face');
  }
  if (face + 12 > bytes.length ||
      (data.getUint32(face) != 0x00010000 && data.getUint32(face) != ottoTag)) {
    throw const FormatException('Unsupported system font');
  }
  final count = data.getUint16(face + 4);
  if (count == 0 || count > 4096 || face + 12 + count * 16 > bytes.length) {
    throw const FormatException('Invalid font tables');
  }
  var size = 12 + count * 16;
  for (var i = 0; i < count; i++) {
    final entry = face + 12 + i * 16;
    final offset = data.getUint32(entry + 8);
    final length = data.getUint32(entry + 12);
    if (offset + length > bytes.length) {
      throw const FormatException('Invalid font table bounds');
    }
    size += (length + 3) & ~3;
    if (size > 48 * 1024 * 1024) {
      throw const FormatException('System font too large');
    }
  }
  if (!collection) return bytes;
  final output = Uint8List(size);
  final result = ByteData.sublistView(output);
  output.setRange(0, 12 + count * 16, bytes, face);
  var cursor = 12 + count * 16;
  int? head;
  for (var i = 0; i < count; i++) {
    final sourceEntry = face + 12 + i * 16;
    final entry = 12 + i * 16;
    final offset = data.getUint32(sourceEntry + 8);
    final length = data.getUint32(sourceEntry + 12);
    output.setRange(cursor, cursor + length, bytes, offset);
    result.setUint32(entry + 8, cursor);
    if (data.getUint32(sourceEntry) == headTag && length >= 12) {
      head = cursor;
      result.setUint32(cursor + 8, 0);
    }
    var checksum = 0;
    for (var p = cursor; p < cursor + length; p += 4) {
      checksum = (checksum + result.getUint32(p)) & 0xffffffff;
    }
    result.setUint32(entry + 4, checksum);
    cursor += (length + 3) & ~3;
  }
  if (head != null) {
    var checksum = 0;
    for (var p = 0; p < output.length; p += 4) {
      checksum = (checksum + result.getUint32(p)) & 0xffffffff;
    }
    result.setUint32(head + 8, (0xb1b0afba - checksum) & 0xffffffff);
  }
  return output;
}
