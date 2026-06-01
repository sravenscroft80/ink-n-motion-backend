import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

/// Mobile/desktop gallery picker via image_picker.
Future<({Uint8List bytes, String name})?> pickCoverupImage() async {
  final picker = ImagePicker();
  final file = await picker.pickImage(source: ImageSource.gallery);
  if (file == null) return null;

  final bytes = await file.readAsBytes();
  return (bytes: bytes, name: file.name);
}

/// Mobile/desktop camera capture via image_picker (system camera UI).
Future<({Uint8List bytes, String name})?> captureCoverupImage() async {
  final picker = ImagePicker();
  final file = await picker.pickImage(source: ImageSource.camera);
  if (file == null) return null;

  final bytes = await file.readAsBytes();
  return (bytes: bytes, name: file.name);
}
