import 'package:ink_n_motion/constants/discover_assets.dart';

/// Validates remote image URLs before they appear in Discover UI.
abstract final class ContentQualityGate {
  static const _placeholderFragments = [
    'pixel.gif',
    'spacer.gif',
    'placeholder',
    'default-image',
    'no-image',
    'noimage',
    '1x1',
    'blank.gif',
    'transparent.png',
    'gravatar.com/avatar',
    'via.placeholder.com',
    'placehold.it',
    'placekitten',
    'dummyimage',
  ];

  static const _lowResFragments = [
    '/thumb/',
    '/thumbnail/',
    '_thumb.',
    '-150x',
    '-150.',
    'w=50',
    'w=64',
    'w=80',
    'w=100',
    'h=50',
    'h=64',
    'h=80',
    'h=100',
    'size=xs',
    'size=small',
    'icon-',
    '/icons/',
    'favicon',
    'logo.',
    '/logo/',
    'avatar',
    'emoji',
  ];

  /// True when [url] is a usable, high-quality network image candidate.
  static bool isHighQualityNetworkImage(String? url) {
    if (url == null || url.trim().isEmpty) return false;

    final trimmed = url.trim();
    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasScheme) return false;
    if (uri.scheme != 'http' && uri.scheme != 'https') return false;
    if (uri.host.isEmpty) return false;

    final lower = trimmed.toLowerCase();
    for (final fragment in _placeholderFragments) {
      if (lower.contains(fragment)) return false;
    }
    for (final fragment in _lowResFragments) {
      if (lower.contains(fragment)) return false;
    }

    final path = uri.path.toLowerCase();
    if (path.endsWith('.svg') || path.endsWith('.ico')) return false;

    return true;
  }
}

/// Resolves chronicle and Discover hero imagery — museum art over blog thumbs.
abstract final class ChronicleImageResolver {
  /// Article hero from GNews or similar — network URL or museum asset.
  static String resolveArticleHero(String? imageUrl, {required String seed}) {
    if (ContentQualityGate.isHighQualityNetworkImage(imageUrl)) {
      return imageUrl!.trim();
    }
    return DiscoverAssets.museumAssetForSeed(seed);
  }

  /// Any display source (network URL or bundled asset path).
  static String resolveForDisplay(
    String source, {
    required String seed,
  }) {
    final trimmed = source.trim();
    if (trimmed.isEmpty) {
      return DiscoverAssets.museumAssetForSeed(seed);
    }

    if (_isNetwork(trimmed)) {
      return resolveArticleHero(trimmed, seed: seed);
    }

    if (_isBlockedBundledAsset(trimmed)) {
      return DiscoverAssets.museumAssetForSeed(seed);
    }

    return trimmed;
  }

  static String museumFallbackForSeed(String seed) =>
      DiscoverAssets.museumAssetForSeed(seed);

  static bool isNetworkSource(String source) => _isNetwork(source.trim());

  static bool _isNetwork(String value) =>
      value.startsWith('http://') || value.startsWith('https://');

  static bool _isBlockedBundledAsset(String path) {
    final lower = path.toLowerCase();
    return lower.contains('workflow') ||
        lower.contains('pillar') ||
        lower.contains('pixel.gif') ||
        lower.contains('fallback_article') ||
        lower.contains('default_artist_avatar') ||
        lower.contains('empty_museum_plate');
  }
}
