import 'package:flutter/cupertino.dart';
import 'package:ink_n_motion/services/chronicle_image_resolver.dart';

/// Hero / gallery image with museum-grade fallbacks — never a broken thumb.
class DiscoverHeroImage extends StatelessWidget {
  const DiscoverHeroImage({
    super.key,
    required this.source,
    required this.seed,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
  });

  final String source;
  final String seed;
  final BoxFit fit;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final resolved = ChronicleImageResolver.resolveForDisplay(
      source,
      seed: seed,
    );
    final fallback = ChronicleImageResolver.museumFallbackForSeed(seed);

    if (ChronicleImageResolver.isNetworkSource(resolved)) {
      return Image.network(
        resolved,
        fit: fit,
        alignment: alignment,
        filterQuality: FilterQuality.high,
        errorBuilder: (context, error, stackTrace) => _assetImage(fallback),
      );
    }

    return _assetImage(resolved, errorFallback: fallback);
  }

  Widget _assetImage(String path, {String? errorFallback}) {
    return Image.asset(
      path,
      fit: fit,
      alignment: alignment,
      filterQuality: FilterQuality.high,
      errorBuilder: (context, error, stackTrace) {
        return Image.asset(
          errorFallback ?? ChronicleImageResolver.museumFallbackForSeed(seed),
          fit: fit,
          alignment: alignment,
          filterQuality: FilterQuality.high,
        );
      },
    );
  }
}
