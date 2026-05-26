import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ink_n_motion/state/providers.dart';

/// Persists the selected image path and optional bytes in Riverpod app state.
void commitSelectedImage(
  WidgetRef ref,
  String path, {
  Uint8List? bytes,
}) {
  if (bytes != null && bytes.isNotEmpty) {
    ref.read(appStateProvider.notifier).setSelectedImageWithBytes(
          path: path,
          bytes: bytes,
        );
  } else {
    ref.read(appStateProvider.notifier).setSelectedImage(path);
  }
}
