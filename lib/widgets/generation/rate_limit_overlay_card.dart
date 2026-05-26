import 'package:flutter/cupertino.dart';
import 'package:ink_n_motion/utils/design_tokens.dart';
import 'package:ink_n_motion/widgets/ink_frosted_glass.dart';

/// Native warning when the backend flood shield returns HTTP 429.
class RateLimitOverlayCard extends StatelessWidget {
  const RateLimitOverlayCard({
    super.key,
    required this.message,
    required this.onDismiss,
  });

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: CupertinoColors.black.withValues(alpha: 0.78),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(InkSpacing.lg),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(InkRadius.lg),
                border: Border.all(
                  color: CupertinoColors.systemYellow.withValues(alpha: 0.65),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: CupertinoColors.systemYellow.withValues(alpha: 0.22),
                    blurRadius: 28,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: InkFrostedGlass(
                padding: const EdgeInsets.all(InkSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      CupertinoIcons.hourglass,
                      size: 48,
                      color: CupertinoColors.systemYellow,
                    ),
                    const SizedBox(height: InkSpacing.md),
                    Text(
                      'Generation Temporarily Limited',
                      style: InkTypography.headline.copyWith(
                        color: InkColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: InkSpacing.sm),
                    Text(
                      message,
                      style: InkTypography.body.copyWith(
                        color: InkColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: InkSpacing.lg),
                    SizedBox(
                      width: double.infinity,
                      child: CupertinoButton.filled(
                        color: CupertinoColors.systemYellow.darkColor,
                        onPressed: onDismiss,
                        child: const Text(
                          'Got it',
                          style: TextStyle(color: CupertinoColors.black),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
