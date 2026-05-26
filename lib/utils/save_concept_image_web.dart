import 'dart:convert';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

Future<void> saveConceptImageImpl(
  Uint8List bytes, {
  String filename = 'ink_concept.png',
}) async {
  final dataUrl = 'data:image/png;base64,${base64Encode(bytes)}';
  final anchor = web.HTMLAnchorElement()
    ..href = dataUrl
    ..download = filename;
  web.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
}
