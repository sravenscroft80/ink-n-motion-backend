import 'package:flutter/cupertino.dart';
import 'package:ink_n_motion/constants/discover_assets.dart';
import 'package:ink_n_motion/services/artist_image_resolver.dart';

/// Profile circle — [FadeInImage] for network sources, museum avatar fallback.
class ArtistProfilePhoto extends StatelessWidget {
  const ArtistProfilePhoto({
    super.key,
    required this.profilePhotoUrl,
    this.size = 88,
  });

  final String profilePhotoUrl;
  final double size;

  static bool _isNetworkUrl(String value) =>
      value.startsWith('http://') || value.startsWith('https://');

  @override
  Widget build(BuildContext context) {
    final source = ArtistImageResolver.resolve(profilePhotoUrl);

    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: source == DiscoverAssets.defaultArtistAvatar
            ? _fadeAvatar(DiscoverAssets.defaultArtistAvatar)
            : _isNetworkUrl(source)
                ? FadeInImage.assetNetwork(
                    placeholder: DiscoverAssets.defaultArtistAvatar,
                    image: source,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.high,
                    fadeInDuration: const Duration(milliseconds: 320),
                    fadeOutDuration: const Duration(milliseconds: 120),
                    imageErrorBuilder: (context, error, stackTrace) =>
                        _fadeAvatar(DiscoverAssets.defaultArtistAvatar),
                  )
                : FadeInImage(
                    placeholder: const AssetImage(
                      DiscoverAssets.defaultArtistAvatar,
                    ),
                    image: AssetImage(source),
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.high,
                    fadeInDuration: const Duration(milliseconds: 320),
                    fadeOutDuration: const Duration(milliseconds: 120),
                    imageErrorBuilder: (context, error, stackTrace) =>
                        _fadeAvatar(DiscoverAssets.defaultArtistAvatar),
                  ),
      ),
    );
  }

  Widget _fadeAvatar(String assetPath) {
    return Image.asset(
      assetPath,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.high,
      errorBuilder: (context, error, stackTrace) => Image.asset(
        DiscoverAssets.defaultArtistAvatar,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
      ),
    );
  }
}
