import 'package:ink_n_motion/constants/discover_assets.dart';

/// Resolves style archive gallery and hero assets — blocks generic Discover art.
abstract final class StyleReferenceResolver {
  static bool isGenericAssetPath(String assetPath) {
    final lower = assetPath.trim().toLowerCase();
    if (lower.isEmpty) return true;
    return lower.contains('workflow') ||
        lower.contains('pillar') ||
        lower.contains('discover');
  }

  /// Gallery tile source — generic paths become the museum plate silhouette.
  static String resolveGalleryImage(String assetPath) {
    final trimmed = assetPath.trim();
    if (isGenericAssetPath(trimmed)) {
      return DiscoverAssets.museumPlaceholder;
    }
    return trimmed;
  }

  /// Hero source — generic paths become the abstract ink hero.
  static String resolveHeroImage(String assetPath) {
    final trimmed = assetPath.trim();
    if (isGenericAssetPath(trimmed)) {
      return DiscoverAssets.spotlightAbstractHero;
    }
    return trimmed;
  }
}
