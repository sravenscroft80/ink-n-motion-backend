import 'dart:typed_data';

import 'package:flutter/material.dart';

class CapturedImageView extends StatelessWidget {
  const CapturedImageView({
    super.key,
    this.path,
    this.bytes,
    this.onRetake,
  });

  final String? path;
  final Uint8List? bytes;
  final VoidCallback? onRetake;

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;
    if (bytes != null && bytes!.isNotEmpty) {
      imageWidget = Image.memory(bytes!, fit: BoxFit.cover);
    } else if (path != null && path!.trim().isNotEmpty) {
      final trimmed = path!.trim();
      if (trimmed.startsWith('http') || trimmed.startsWith('blob:')) {
        imageWidget = Image.network(trimmed, fit: BoxFit.cover);
      } else {
        imageWidget = Image.asset(trimmed, fit: BoxFit.cover);
      }
    } else {
      imageWidget = const Center(
        child: Icon(Icons.image, color: Colors.white38, size: 64),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        imageWidget,
        if (onRetake != null)
          Positioned(
            top: 16,
            right: 16,
            child: IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: onRetake,
            ),
          ),
      ],
    );
  }
}
