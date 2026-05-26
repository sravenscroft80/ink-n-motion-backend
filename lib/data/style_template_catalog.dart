import 'package:ink_n_motion/models/style_template.dart';

/// Static style template matrix for the picker grid.
abstract final class StyleTemplateCatalog {
  static const List<StyleTemplate> templates = [
    StyleTemplate(
      id: 'cyberpunk_neon_glow',
      name: 'Cyberpunk Neon Glow',
      renderingType: StyleRenderingType.premium,
      thumbnailPlaceholder: 'cyberpunk_neon',
    ),
    StyleTemplate(
      id: 'traditional_japanese_ink_flow',
      name: 'Traditional Japanese Ink Flow',
      renderingType: StyleRenderingType.premium,
      thumbnailPlaceholder: 'japanese_ink',
    ),
    StyleTemplate(
      id: 'animated_pop_3d',
      name: '3D Animated Pop',
      renderingType: StyleRenderingType.easy,
      thumbnailPlaceholder: 'animated_pop_3d',
    ),
    StyleTemplate(
      id: 'monochrome_shadow',
      name: 'Monochrome Shadow',
      renderingType: StyleRenderingType.easy,
      thumbnailPlaceholder: 'monochrome_shadow',
    ),
    StyleTemplate(
      id: 'alex_grey_visionary',
      name: 'Alex Grey Visionary',
      renderingType: StyleRenderingType.premium,
      thumbnailPlaceholder: 'alex_grey_visionary',
    ),
    StyleTemplate(
      id: 'steampunk_clockwork',
      name: 'Steampunk Clockwork',
      renderingType: StyleRenderingType.premium,
      thumbnailPlaceholder: 'steampunk_clockwork',
    ),
    StyleTemplate(
      id: 'anime_cel_shaded',
      name: 'Anime Cel-Shaded',
      renderingType: StyleRenderingType.premium,
      thumbnailPlaceholder: 'anime_cel_shaded',
    ),
    StyleTemplate(
      id: 'gothic_horror',
      name: 'Gothic Horror',
      renderingType: StyleRenderingType.premium,
      thumbnailPlaceholder: 'gothic_horror',
    ),
  ];

  static StyleTemplate? findById(String? id) {
    if (id == null) return null;
    for (final template in templates) {
      if (template.id == id) return template;
    }
    return null;
  }
}
