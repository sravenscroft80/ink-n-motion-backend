import 'package:flutter/cupertino.dart';
import 'package:ink_n_motion/models/style_template.dart';
import 'package:ink_n_motion/utils/design_tokens.dart';

/// Maps [StyleTemplate.thumbnailPlaceholder] keys to Cupertino visual placeholders.
class StyleTemplateThumbnail extends StatelessWidget {
  const StyleTemplateThumbnail({
    super.key,
    required this.template,
    this.size = 40,
  });

  final StyleTemplate template;
  final double size;

  @override
  Widget build(BuildContext context) {
    final visual = _visualForPlaceholder(template.thumbnailPlaceholder);
    final accent = template.isPremium
        ? InkColors.accentNeonMagenta
        : InkColors.accentNeonCyan;

    return Container(
      width: size + 16,
      height: size + 16,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(InkRadius.sm),
        border: Border.all(color: accent.withValues(alpha: 0.45)),
      ),
      child: Icon(visual.icon, size: size, color: visual.color),
    );
  }
}

class _ThumbnailVisual {
  const _ThumbnailVisual({required this.icon, required this.color});

  final IconData icon;
  final Color color;
}

_ThumbnailVisual _visualForPlaceholder(String key) {
  switch (key) {
    case 'cyberpunk_neon':
      return const _ThumbnailVisual(
        icon: CupertinoIcons.bolt_fill,
        color: InkColors.accentNeonMagenta,
      );
    case 'japanese_ink':
      return const _ThumbnailVisual(
        icon: CupertinoIcons.drop_fill,
        color: InkColors.accentNeonViolet,
      );
    case 'animated_pop_3d':
      return const _ThumbnailVisual(
        icon: CupertinoIcons.cube_fill,
        color: InkColors.accentNeonCyan,
      );
    case 'monochrome_shadow':
      return const _ThumbnailVisual(
        icon: CupertinoIcons.circle_lefthalf_fill,
        color: InkColors.textSecondary,
      );
    default:
      return const _ThumbnailVisual(
        icon: CupertinoIcons.photo,
        color: InkColors.textTertiary,
      );
  }
}
