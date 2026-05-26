import 'package:ink_n_motion/constants/discover_assets.dart';

/// Resolves artist profile images — blocks workflow/pillar placeholders.
abstract final class ArtistImageResolver {
  static const String _workflowPrefix = 'assets/images/workflow';
  static const String _pillarPrefix = 'assets/images/pillar';

  /// Returns a network URL, a bundled asset path, or [DiscoverAssets.defaultArtistAvatar].
  static String resolve(String? profilePhotoUrl) {
    final candidate = profilePhotoUrl?.trim() ?? '';
    if (candidate.isEmpty) {
      return DiscoverAssets.defaultArtistAvatar;
    }
    if (_isPlaceholderAsset(candidate)) {
      return DiscoverAssets.defaultArtistAvatar;
    }
    if (_isNetworkUrl(candidate)) {
      return _isValidNetworkImage(candidate)
          ? candidate
          : DiscoverAssets.defaultArtistAvatar;
    }
    return candidate;
  }

  static bool _isPlaceholderAsset(String path) {
    return path.startsWith(_workflowPrefix) || path.startsWith(_pillarPrefix);
  }

  static bool _isNetworkUrl(String value) =>
      value.startsWith('http://') || value.startsWith('https://');

  static bool _isValidNetworkImage(String candidate) {
    final uri = Uri.tryParse(candidate);
    if (uri == null || !uri.hasScheme) return false;
    if (uri.scheme != 'http' && uri.scheme != 'https') return false;
    return uri.host.isNotEmpty;
  }
}
