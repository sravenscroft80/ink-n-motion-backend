/// Bundled Discover media paths.
abstract final class DiscoverAssets {
  /// Default hero when a live article has no valid image URL.
  static const String fallbackArticleImage =
      'assets/images/fallback_article_image.png';

  /// Default artist profile when [profile_photo_url] is missing or fails.
  static const String defaultArtistAvatar =
      'assets/images/default_artist_avatar.png';

  /// Museum-grade abstract hero for Artist Spotlight (not the artist photo).
  static const String spotlightAbstractHero =
      'assets/images/discover_hero.png';

  /// Empty museum plate silhouette for blocked or missing gallery references.
  static const String museumPlaceholder =
      'assets/images/empty_museum_plate.png';

  static const String inkChroniclesHero =
      'assets/images/ink_chronicles.png';

  static const String styleArchiveHero =
      'assets/images/style_archive.png';

  static const String aiCoachHero = 'assets/images/ai_coach.png';

  static const String artistSpotlightHero =
      'assets/images/artist_spotlight.png';

  /// Museum-grade static heroes when remote URLs fail quality checks.
  static const List<String> abstractInkAssets = [
    spotlightAbstractHero,
    inkChroniclesHero,
    styleArchiveHero,
    aiCoachHero,
    artistSpotlightHero,
    spotlightAbstractHero,
    inkChroniclesHero,
    styleArchiveHero,
    aiCoachHero,
    artistSpotlightHero,
    spotlightAbstractHero,
    inkChroniclesHero,
  ];

  /// Deterministic museum-grade hero from [seed] (title, id, caption).
  static String museumAssetForSeed(String seed) {
    if (abstractInkAssets.isEmpty) return spotlightAbstractHero;
    final normalized = seed.trim().isEmpty ? 'ink-n-motion' : seed.trim();
    final index = normalized.hashCode.abs() % abstractInkAssets.length;
    return abstractInkAssets[index];
  }
}
