import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

/// Cross-platform image selection via [ImagePicker] (mobile, desktop, and web).
class ImageAssetService {
  ImageAssetService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  /// Returns a local file path, or `null` if the user cancelled.
  Future<String?> pickFromGallery() async {
    final result = await pickImage(source: ImageSource.gallery);
    return result?.path;
  }

  /// Opens the device camera through [ImagePicker] (works on web and mobile).
  Future<PickedImageResult?> pickFromCamera() async {
    return pickImage(source: ImageSource.camera);
  }

  /// Returns path + in-memory bytes for preview on web.
  Future<PickedImageResult?> pickImage({
    required ImageSource source,
    int imageQuality = 92,
  }) async {
    final file = await _picker.pickImage(
      source: source,
      imageQuality: imageQuality,
    );
    if (file == null) return null;

    final bytes = await file.readAsBytes();
    return PickedImageResult(path: file.path, bytes: bytes);
  }
}

class PickedImageResult {
  const PickedImageResult({
    required this.path,
    required this.bytes,
  });

  final String path;
  final Uint8List bytes;
}
