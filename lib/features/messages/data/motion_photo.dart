import 'dart:convert';
import 'dart:typed_data';
import 'package:xml/xml.dart';

class MotionPhotoClip {
  const MotionPhotoClip(this.offset, this.length, this.stillLength);
  final int offset, length, stillLength;
}

typedef PhotoRangeReader = Uint8List Function(int offset, int count);

/// Read-only Motion Photo parser. Never trusts an XMP offset without validating
/// the complete, bounded ISO-BMFF movie. No filenames or network references.
class MotionPhoto {
  static const maxBytes = 64 * 1024 * 1024;
  static MotionPhotoClip? inspectBytes(Uint8List bytes) => inspect(bytes.length,
      (offset, count) => Uint8List.sublistView(bytes, offset, offset + count));

  static MotionPhotoClip? inspect(int size, PhotoRangeReader read) {
    if (size < 24 || size > maxBytes) return null;
    try {
      final head = read(0, size.clamp(0, 2 * 1024 * 1024));
      final jpeg = head[0] == 255 && head[1] == 216;
      final isoImage = _text(head, 4, 4) == 'ftyp';
      if (!jpeg && !isoImage) return null;
      final text = latin1.decode(head);
      final flag = _number(text, 'MotionPhoto');
      if (flag == 0) return null;
      final length = _xmpLength(text);
      if (jpeg &&
          length != null &&
          length > 0 &&
          length < size &&
          validVideo(size - length, length, size, read)) {
        return MotionPhotoClip(size - length, length, size - length);
      }
      if (isoImage) {
        var pos = 0;
        for (var i = 0; i < 4096 && pos + 8 <= size; i++) {
          final box = _box(pos, size, read);
          if (box == null) break;
          if (box.type == 'mpvd' &&
              pos + box.size == size &&
              validVideo(pos + box.header, box.size - box.header, size, read)) {
            return MotionPhotoClip(
                pos + box.header, box.size - box.header, pos);
          }
          pos += box.size;
        }
        return null;
      }
      // Most ordinary JPEGs terminate at EOI: no entropy scan is needed.
      final tail = read(size - 2, 2);
      if (tail[0] == 255 && tail[1] == 217) return null;
      final end = _jpegEnd(size, read);
      if (end == null || end >= size) return null;
      final trailer = read(end, (size - end).clamp(0, 65536 + 8));
      for (var i = 0; i + 8 <= trailer.length; i++) {
        if (_text(trailer, i + 4, 4) == 'ftyp' &&
            validVideo(end + i, size - end - i, size, read)) {
          return MotionPhotoClip(end + i, size - end - i, end);
        }
      }
    } catch (_) {/* Malformed media remains a still image. */}
    return null;
  }

  static int? _number(String text, String local) {
    final attr = RegExp('(?:[\\w.-]+:)?$local\\s*=\\s*["\u0027](\\d+)["\u0027]')
        .firstMatch(text);
    final node = RegExp('<(?:[\\w.-]+:)?$local(?:\\s[^>]*)?>\\s*(\\d+)\\s*</')
        .firstMatch(text);
    return int.tryParse(attr?.group(1) ?? node?.group(1) ?? '');
  }

  static int? _xmpLength(String text) {
    final start = RegExp(r'<(?:[\w.-]+:)?xmpmeta\b').firstMatch(text);
    if (start != null) {
      final close = RegExp(r'</(?:[\w.-]+:)?xmpmeta\s*>')
          .firstMatch(text.substring(start.start));
      if (close != null) {
        final packet = text.substring(start.start, start.start + close.end);
        if (packet.contains('<!DOCTYPE') || packet.contains('<!ENTITY')) {
          return null;
        }
        try {
          final document = XmlDocument.parse(packet);
          int? length;
          var count = 0, after = false;
          for (final element in document.descendants.whereType<XmlElement>()) {
            if (++count > 4096) return null;
            String? attr(String key) => element.attributes
                .where((a) => a.name.local == key)
                .firstOrNull
                ?.value;
            final semantic = attr('Semantic');
            if (semantic == 'MotionPhoto' &&
                const ['video/mp4', 'video/quicktime'].contains(attr('Mime'))) {
              if (length != null) return null;
              length = int.tryParse(attr('Length') ?? '');
              after = true;
            } else if (after && semantic != null) {
              return null;
            }
          }
          if (length != null) return length;
        } catch (_) {
          return null;
        }
      }
    }
    return _number(text, 'MicroVideoOffset') ??
        _number(text, 'MotionPhotoVideoOffset');
  }

  static ({int size, int header, String type})? _box(
      int offset, int end, PhotoRangeReader read) {
    if (offset < 0 || offset + 8 > end) return null;
    final head = read(offset, (end - offset).clamp(0, 16));
    var size = ByteData.sublistView(head).getUint32(0);
    var header = 8;
    if (size == 1) {
      if (head.length < 16) return null;
      size = ByteData.sublistView(head).getUint64(8);
      header = 16;
    } else if (size == 0) {
      size = end - offset;
    }
    if (size < header || size > end - offset) return null;
    return (size: size, header: header, type: _text(head, 4, 4));
  }

  static bool validVideo(
      int start, int length, int total, PhotoRangeReader read) {
    if (start < 0 || length < 32 || length > maxBytes || length > total - start) {
      return false;
    }
    var pos = start, moov = false, mdat = false;
    final end = start + length;
    for (var i = 0; pos < end && i < 4096; i++) {
      final box = _box(pos, end, read);
      if (box == null) return false;
      if (pos == start &&
          (box.type != 'ftyp' || box.size < 16 || box.size > 4096)) {
        return false;
      }
      if (box.type == 'moov') moov = true;
      if (box.type == 'mdat') mdat = true;
      pos += box.size;
    }
    return pos == end && moov && mdat;
  }

  static int? _jpegEnd(int size, PhotoRangeReader read) {
    var pos = 2, entropy = false, bufferStart = -1;
    var buffer = Uint8List(0);
    int byte() {
      if (pos >= size) throw const FormatException();
      if (pos < bufferStart || pos >= bufferStart + buffer.length) {
        bufferStart = pos;
        buffer = read(pos, (size - pos).clamp(0, 65536));
      }
      return buffer[pos++ - bufferStart];
    }

    while (pos < size) {
      if (byte() != 255) {
        if (entropy) continue;
        return null;
      }
      var marker = byte();
      while (marker == 255) {
        marker = byte();
      }
      if (entropy && (marker == 0 || marker >= 208 && marker <= 215)) continue;
      if (marker == 217) return pos;
      if (marker == 216 || marker == 1) continue;
      entropy = false;
      final segment = (byte() << 8) | byte();
      if (segment < 2 || segment - 2 > size - pos) return null;
      pos += segment - 2;
      if (marker == 218) entropy = true;
    }
    return null;
  }

  static String _text(Uint8List bytes, int start, int count) =>
      start < 0 || start + count > bytes.length
          ? ''
          : latin1.decode(Uint8List.sublistView(bytes, start, start + count));

  /// Standard JPEG Motion Photo envelope for an explicitly selected still/MOV
  /// pair. Other clients can continue displaying the primary JPEG.
  static Uint8List combineJpeg(Uint8List jpeg, Uint8List movie) {
    if (jpeg.length < 4 ||
        jpeg[0] != 255 ||
        jpeg[1] != 216 ||
        jpeg.length + movie.length + 4096 > maxBytes ||
        !validVideo(
            0,
            movie.length,
            movie.length,
            (offset, count) =>
                Uint8List.sublistView(movie, offset, offset + count))) {
      throw const FormatException('Invalid live photo resources');
    }
    final xmp = utf8.encode('http://ns.adobe.com/xap/1.0/\u0000'
        '<x:xmpmeta xmlns:x="adobe:ns:meta/"><rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">'
        '<rdf:Description xmlns:Camera="http://ns.google.com/photos/1.0/camera/" Camera:MotionPhoto="1" Camera:MotionPhotoVersion="1" '
        'xmlns:Container="http://ns.google.com/photos/1.0/container/" xmlns:Item="http://ns.google.com/photos/1.0/container/item/">'
        '<Container:Directory><rdf:Seq><rdf:li rdf:parseType="Resource"><Container:Item Item:Mime="image/jpeg" Item:Semantic="Primary" Item:Padding="0"/></rdf:li>'
        '<rdf:li rdf:parseType="Resource"><Container:Item Item:Mime="video/quicktime" Item:Semantic="MotionPhoto" Item:Length="${movie.length}"/></rdf:li>'
        '</rdf:Seq></Container:Directory></rdf:Description></rdf:RDF></x:xmpmeta>');
    final output = BytesBuilder(copy: false)
      ..add(jpeg.sublist(0, 2))
      ..add([255, 225, (xmp.length + 2) >> 8, (xmp.length + 2) & 255])
      ..add(xmp)
      ..add(Uint8List.sublistView(jpeg, 2))
      ..add(movie);
    return output.takeBytes();
  }
}
