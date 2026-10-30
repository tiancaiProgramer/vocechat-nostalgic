import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// A circular avatar that shows [imageUrl] if provided, otherwise falls back
/// to the first character of [name] on a deterministic background color.
///
/// Uses [CachedNetworkImage] so the same avatar isn't re-downloaded on every
/// rebuild / scroll / screen-transition. When the image has transparent
/// regions (PNG / WebP), they render as TRUE transparency over the parent
/// surface — no colored disc bleeds through behind alpha pixels.
class VoceAvatar extends StatelessWidget {
  const VoceAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.size = 40,
    this.cacheImage = true,
  });

  final String name;
  final String? imageUrl;
  final double size;

  /// Disabled for ephemeral archive attachments that must not persist on disk.
  final bool cacheImage;

  static Color _colorFromName(String name) {
    return const Color(0xFFE4E7EC);
  }

  /// First grapheme of [name] — preserves emoji and other multi-codepoint
  /// glyphs intact instead of slicing them across UTF-16 code units (which
  /// `name[0]` would do, producing a tofu replacement char).
  static String _firstGlyph(String name) {
    final words = name.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty);
    return words.isEmpty
        ? '?'
        : words.take(4).map((s) => s.characters.first).join().toUpperCase();
  }

  Widget _initials() {
    final letter = _firstGlyph(name);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _colorFromName(name),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: TextStyle(
          color: const Color(0xFF52525B),
          fontSize: letter.characters.length > 3 ? size / 3.5 : size * .4,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _initials();
    }
    // ClipOval over the image keeps real transparency intact.
    // We deliberately do NOT set a backgroundColor on the clipped area,
    // so transparent PNGs let the surface behind show through.
    return SizedBox(
      width: size,
      height: size,
      child: ClipOval(
        child: cacheImage
            ? CachedNetworkImage(
                imageUrl: imageUrl!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                fadeInDuration: const Duration(milliseconds: 120),
                fadeOutDuration: Duration.zero,
                placeholder: (_, __) => _initials(),
                errorWidget: (_, __, ___) => _initials(),
              )
            : Image.network(
                imageUrl!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                loadingBuilder: (_, child, progress) =>
                    progress == null ? child : _initials(),
                errorBuilder: (_, __, ___) => _initials(),
              ),
      ),
    );
  }
}
