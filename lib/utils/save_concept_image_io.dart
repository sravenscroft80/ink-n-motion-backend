import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:gal/gal.dart';

Future<bool> saveConceptImageImpl(
  Uint8List bytes, {
  String filename = 'ink_concept',
}) async {
  debugPrint('SAVE-DEBUG: start, bytes.length=${bytes.length}, name=$filename');
  try {
    final has = await Gal.hasAccess();
    debugPrint('SAVE-DEBUG: hasAccess(before)=$has');
    if (!has) {
      final req = await Gal.requestAccess();
      debugPrint('SAVE-DEBUG: requestAccess result=$req');
      if (!req) {
        debugPrint('SAVE-DEBUG: access DENIED, aborting');
        return false;
      }
    }
    await Gal.putImageBytes(bytes, name: filename);
    debugPrint('SAVE-DEBUG: putImageBytes SUCCEEDED');
    return true;
  } catch (e, st) {
    debugPrint('SAVE-DEBUG: putImageBytes FAILED: $e');
    debugPrint('$st');
    return false;
  }
}
