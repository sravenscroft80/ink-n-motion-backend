import 'dart:async';
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:typed_data';

/// Web file picker via dart:html.
Future<({Uint8List bytes, String name})?> pickCoverupImage() async {
  final input = html.FileUploadInputElement()
    ..accept = 'image/*'
    ..style.display = 'none';

  html.document.body?.append(input);

  final completer = Completer<({Uint8List bytes, String name})?>();

  void cleanup() {
    input.remove();
  }

  void completeWithResult(({Uint8List bytes, String name})? value) {
    if (completer.isCompleted) return;
    completer.complete(value);
    cleanup();
  }

  input.onChange.listen((_) async {
    final files = input.files;
    if (files == null || files.isEmpty) {
      completeWithResult(null);
      return;
    }

    final file = files.first;
    try {
      final bytes = await _readFileAsBytes(file);
      if (bytes == null || bytes.isEmpty) {
        completeWithResult(null);
        return;
      }
      completeWithResult((bytes: bytes, name: file.name));
    } catch (_) {
      completeWithResult(null);
    }
  });

  input.click();
  return completer.future;
}

/// Reads [file] bytes from the browser file picker (web equivalent of readAsBytes).
Future<Uint8List?> _readFileAsBytes(html.File file) async {
  final reader = html.FileReader();
  final completer = Completer<Uint8List?>();

  reader.onLoadEnd.listen((_) {
    if (completer.isCompleted) return;
    if (reader.readyState != html.FileReader.DONE) return;

    completer.complete(_bytesFromReaderResult(reader.result));
  });

  reader.onError.listen((_) {
    if (!completer.isCompleted) completer.complete(null);
  });

  reader.readAsArrayBuffer(file);
  return completer.future;
}

Uint8List? _bytesFromReaderResult(Object? result) {
  if (result == null) return null;
  if (result is Uint8List) return result;
  if (result is ByteBuffer) return result.asUint8List();
  if (result is TypedData) {
    return Uint8List.view(result.buffer, result.offsetInBytes, result.lengthInBytes);
  }
  return null;
}
