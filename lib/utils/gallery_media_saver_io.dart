import 'dart:io';

import 'package:gal/gal.dart';
import 'package:http/http.dart' as http;
import 'package:ink_n_motion/utils/concept_image_loader.dart';
import 'package:path_provider/path_provider.dart';

Future<bool> _ensureGalleryAccess() async {
  if (await Gal.hasAccess()) return true;
  return Gal.requestAccess();
}

Future<bool> saveNetworkVideoToGallery(String url) async {
  try {
    if (!await _ensureGalleryAccess()) return false;

    final trimmed = url.trim();
    if (trimmed.isEmpty) return false;

    final response = await http
        .get(Uri.parse(trimmed))
        .timeout(const Duration(seconds: 120));
    if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
      return false;
    }

    final ext = _videoExtensionFromUrl(trimmed);
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/ink_motion_${DateTime.now().millisecondsSinceEpoch}.$ext',
    );
    await file.writeAsBytes(response.bodyBytes);
    await Gal.putVideo(file.path);
    return true;
  } catch (_) {
    return false;
  }
}

Future<bool> saveNetworkImageToGallery(
  String url, {
  String filename = 'ink_image.png',
}) async {
  try {
    if (!await _ensureGalleryAccess()) return false;

    final bytes = await loadConceptImageBytes(url);
    if (bytes == null || bytes.isEmpty) return false;

    await Gal.putImageBytes(bytes, name: filename);
    return true;
  } catch (_) {
    return false;
  }
}

String _videoExtensionFromUrl(String url) {
  final lower = url.toLowerCase();
  if (lower.contains('.webm')) return 'webm';
  if (lower.contains('.mov')) return 'mov';
  return 'mp4';
}

bool looksLikeVideoUrl(String path) {
  final lower = path.toLowerCase();
  return lower.contains('.mp4') ||
      lower.contains('.mov') ||
      lower.contains('.webm') ||
      lower.contains('/video');
}
