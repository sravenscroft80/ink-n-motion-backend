import 'package:ink_n_motion/models/tattoo_discovery_summary.dart';

/// Blueprint and generated concept passed from AI Coach into Motion Studio.
class StudioHandoff {
  const StudioHandoff({
    required this.summary,
    this.generatedImageUrl,
  });

  final TattooDiscoverySummary summary;
  final String? generatedImageUrl;

  bool get hasGeneratedImage =>
      generatedImageUrl != null && generatedImageUrl!.trim().isNotEmpty;
}
