import 'dart:typed_data';

import 'save_concept_image_stub.dart'
    if (dart.library.html) 'save_concept_image_web.dart'
    if (dart.library.io) 'save_concept_image_io.dart';

Future<void> saveConceptImage(Uint8List bytes, {String filename = 'ink_concept.png'}) {
  return saveConceptImageImpl(bytes, filename: filename);
}
