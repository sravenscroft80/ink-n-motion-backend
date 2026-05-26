/// Successful video generation payload from the Ink‑N‑Motion API.
class GenerateVideoResponse {
  const GenerateVideoResponse({
    this.videoUrl,
    this.maskUrl,
    this.isLocalOverlay = false,
  });

  final String? videoUrl;
  final String? maskUrl;
  final bool isLocalOverlay;
}
