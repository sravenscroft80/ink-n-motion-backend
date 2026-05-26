import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:ink_n_motion/utils/design_tokens.dart';

/// Frosted glass panel — CupertinoVisualEffect-style blur overlay.
class InkFrostedGlass extends StatelessWidget {
  const InkFrostedGlass({
    super.key,
    required this.child,
    this.borderRadius = InkRadius.md,
    this.padding,
    this.sigma = 24,
    this.showBorder = true,
  });

  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final double sigma;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: const Color(0xA812121A),
            borderRadius: BorderRadius.circular(borderRadius),
            border: showBorder
                ? Border.all(
                    color: InkColors.textPrimary.withValues(alpha: 0.08),
                  )
                : null,
          ),
          child: child,
        ),
      ),
    );
  }
}
