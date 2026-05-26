import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

/// Loads concept image bytes from a network URL or `data:image/...;base64,...` URI.
Future<Uint8List?> loadConceptImageBytes(String imageSource) async {
  final trimmed = imageSource.trim();
  if (trimmed.isEmpty) return null;

  if (trimmed.startsWith('data:image')) {
    final commaIndex = trimmed.indexOf(',');
    if (commaIndex == -1) return null;
    try {
      return base64Decode(trimmed.substring(commaIndex + 1));
    } catch (_) {
      return null;
    }
  }

  final response = await http.get(Uri.parse(trimmed));
  if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
    return response.bodyBytes;
  }
  return null;
}
