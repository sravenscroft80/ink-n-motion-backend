import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

class MockupPreviewImage extends StatelessWidget {
  const MockupPreviewImage({
    super.key,
    this.imageBytes,
    this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.errorMessage,
  });

  final Uint8List? imageBytes;
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    if (imageBytes != null && imageBytes!.isNotEmpty) {
      return Image.memory(
        imageBytes!,
        width: width,
        height: height,
        fit: fit,
      );
    }

    final url = imageUrl?.trim();
    if (url != null && url.isNotEmpty) {
      if (url.startsWith('data:image')) {
        final commaIndex = url.indexOf(',');
        if (commaIndex != -1) {
          try {
            final decoded = base64Decode(url.substring(commaIndex + 1));
            if (decoded.isNotEmpty) {
              return Image.memory(
                decoded,
                width: width,
                height: height,
                fit: fit,
              );
            }
          } catch (_) {
            return _placeholder();
          }
        }
      }

      return Image.network(
        url,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _loadingPlaceholder(loadingProgress);
        },
        errorBuilder: (context, error, stackTrace) => _placeholder(),
      );
    }

    return _placeholder();
  }

  Widget _loadingPlaceholder(ImageChunkEvent progress) {
    return Container(
      width: width,
      height: height,
      color: const Color(0xFF2A2A3E),
      child: Center(
        child: CircularProgressIndicator(
          value: progress.expectedTotalBytes != null
              ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
              : null,
          color: const Color(0xFFD4A017),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: width,
      height: height,
      color: const Color(0xFF2A2A3E),
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Text(
          errorMessage ?? 'Preview unavailable',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white54, fontSize: 13),
        ),
      ),
    );
  }
}
