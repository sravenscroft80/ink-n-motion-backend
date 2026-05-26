import 'package:ink_n_motion/models/tattoo_discovery_summary.dart';
import 'package:ink_n_motion/widgets/capture/studio_style_picker.dart';

/// Maps AI Coach blueprint hints to Studio motion template ids.
abstract final class StudioStyleMapper {
  static String? templateIdForSummary(TattooDiscoverySummary? summary) {
    final hint = summary?.style?.toLowerCase() ?? '';
    if (hint.isEmpty) return null;

    if (hint.contains('neon') ||
        hint.contains('cyber') ||
        hint.contains('electric')) {
      return 'cyberpunk_neon_glow';
    }
    if (hint.contains('sparkle') ||
        hint.contains('particle') ||
        hint.contains('burst')) {
      return 'animated_pop_3d';
    }
    if (hint.contains('fluid') ||
        hint.contains('fine line') ||
        hint.contains('minimal') ||
        hint.contains('organic') ||
        hint.contains('irezumi') ||
        hint.contains('japanese')) {
      return 'traditional_japanese_ink_flow';
    }

    for (final option in StudioStylePicker.defaultOptions) {
      if (hint.contains(option.label.toLowerCase())) {
        return option.templateId;
      }
    }

    return null;
  }
}
