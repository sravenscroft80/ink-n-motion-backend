import 'dart:convert';
import 'dart:typed_data';

// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

Future<void> saveConceptImageImpl(
  Uint8List bytes, {
  String filename = 'ink_concept.png',
}) async {
  final dataUrl = 'data:image/png;base64,${base64Encode(bytes)}';
  final anchor = html.AnchorElement()
    ..href = dataUrl
    ..download = filename;
  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
}
