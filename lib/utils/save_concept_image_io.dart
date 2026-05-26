import 'dart:typed_data';

import 'package:gal/gal.dart';

Future<void> saveConceptImageImpl(
  Uint8List bytes, {
  String filename = 'ink_concept.png',
}) async {
  await Gal.putImageBytes(bytes, name: filename);
}
