Future<bool> saveNetworkVideoToGallery(String url) async => false;

Future<bool> saveNetworkImageToGallery(
  String url, {
  String filename = 'ink_image.png',
}) async =>
    false;

bool looksLikeVideoUrl(String path) {
  final lower = path.toLowerCase();
  return lower.contains('.mp4') ||
      lower.contains('.mov') ||
      lower.contains('.webm') ||
      lower.contains('/video');
}
