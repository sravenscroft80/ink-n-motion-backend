import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:ink_n_motion/utils/design_tokens.dart';
import 'package:ink_n_motion/widgets/sparkle_particle_overlay.dart';

/// Stacked tattoo photo + animated sparkle particles for the low-cost track.
class LocalOverlaySparklePreview extends StatelessWidget {
  const LocalOverlaySparklePreview({
    super.key,
    required this.imagePath,
    required this.maskUrl,
    this.borderRadius = InkRadius.lg,
  });

  final String imagePath;
  final String maskUrl;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(
            File(imagePath),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => ColoredBox(
              color: InkColors.backgroundSecondary,
              child: Center(
                child: Icon(
                  CupertinoIcons.photo,
                  size: 48,
                  color: InkColors.textTertiary,
                ),
              ),
            ),
          ),
          SparkleParticleOverlay(maskUrl: maskUrl),
          Positioned(
            left: InkSpacing.sm,
            right: InkSpacing.sm,
            bottom: InkSpacing.sm,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: CupertinoColors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(InkRadius.sm),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: InkSpacing.sm,
                  vertical: InkSpacing.xs,
                ),
                child: Text(
                  'Make it Sparkle · live mask overlay',
                  style: InkTypography.caption1.copyWith(
                    color: InkColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
