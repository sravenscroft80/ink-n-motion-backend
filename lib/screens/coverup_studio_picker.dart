import 'dart:typed_data';

/// Picks a tattoo photo for coverup upload (stub — overridden per platform).
Future<({Uint8List bytes, String name})?> pickCoverupImage() async {
  return null;
}

/// Camera capture stub (overridden per platform).
Future<({Uint8List bytes, String name})?> captureCoverupImage() async {
  return null;
}
