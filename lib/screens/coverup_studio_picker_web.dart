import 'dart:async';
// ignore: deprecated_member_use — web file input per product spec.
import 'dart:html' as html;
import 'dart:typed_data';

/// Web file picker via dart:html.
Future<({Uint8List bytes, String name})?> pickCoverupImage() async {
  final input = html.FileUploadInputElement()..accept = 'image/*';
  final completer = Completer<({Uint8List bytes, String name})?>();

  input.onChange.listen((_) {
    final files = input.files;
    if (files == null || files.isEmpty) {
      if (!completer.isCompleted) completer.complete(null);
      return;
    }

    final file = files.first;
    final reader = html.FileReader();
    reader.readAsArrayBuffer(file);
    reader.onLoad.listen((_) {
      if (completer.isCompleted) return;
      final result = reader.result;
      if (result is ByteBuffer) {
        completer.complete((
          bytes: Uint8List.view(result),
          name: file.name,
        ));
      } else {
        completer.complete(null);
      }
    });
    reader.onError.listen((_) {
      if (!completer.isCompleted) completer.complete(null);
    });
  });

  input.click();
  return completer.future;
}
