import 'package:flutter/cupertino.dart';
import 'package:ink_n_motion/utils/design_tokens.dart';
import 'package:ink_n_motion/widgets/ink_frosted_glass.dart';

/// Native fallback when the device cannot reach cloud render clusters.
class OfflineNetworkOverlayCard extends StatelessWidget {
  const OfflineNetworkOverlayCard({
    super.key,
    required this.onRetry,
  });

  final VoidCallback onRetry;

  static const _headline = 'Connection Disrupted';
  static const _subtitle =
      'Ink-N-Motion could not reach the cloud rendering clusters. '
      'Your credits have been safely preserved in your wallet. '
      'Please check your signal and try again.';

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: CupertinoColors.black.withValues(alpha: 0.8),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(InkSpacing.lg),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(InkRadius.lg),
                border: Border.all(
                  color: CupertinoColors.systemGrey.withValues(alpha: 0.55),
                ),
              ),
              child: InkFrostedGlass(
                padding: const EdgeInsets.all(InkSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CupertinoIcons.wifi_exclamationmark,
                      size: 52,
                      color: CupertinoColors.inactiveGray,
                    ),
                    const SizedBox(height: InkSpacing.md),
                    Text(
                      _headline,
                      style: InkTypography.headline.copyWith(
                        color: InkColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: InkSpacing.sm),
                    Text(
                      _subtitle,
                      style: InkTypography.body.copyWith(
                        color: InkColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: InkSpacing.lg),
                    SizedBox(
                      width: double.infinity,
                      child: CupertinoButton.filled(
                        onPressed: onRetry,
                        child: const Text('Retry Connection'),
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
