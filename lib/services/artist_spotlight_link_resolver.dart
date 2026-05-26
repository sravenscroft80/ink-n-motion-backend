import 'package:ink_n_motion/models/discover_content.dart';

class ArtistSpotlightLinkResolver {
  static String resolveExploreUrl(ArtistSpotlightEntry entry) {
    final name = entry.name.trim();
    if (name.isEmpty) {
      return 'https://www.google.com/search?q=tattoo+artist+portfolio';
    }
    final query = Uri.encodeComponent('$name tattoo artist portfolio');
    return 'https://www.google.com/search?q=$query';
  }
}
