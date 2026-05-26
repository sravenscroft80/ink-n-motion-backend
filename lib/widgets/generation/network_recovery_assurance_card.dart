import 'package:flutter/cupertino.dart';
import 'package:ink_n_motion/utils/design_tokens.dart';
import 'package:ink_n_motion/widgets/ink_frosted_glass.dart';

/// Reassuring overlay when async generation fails or times out.
class NetworkRecoveryAssuranceCard extends StatelessWidget {
  const NetworkRecoveryAssuranceCard({
    super.key,
    required this.onDismiss,
    this.showCreditRefund = false,
  });

  final VoidCallback onDismiss;
  final bool showCreditRefund;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: CupertinoColors.black.withValues(alpha: 0.72),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(InkSpacing.lg),
            child: InkFrostedGlass(
              padding: const EdgeInsets.all(InkSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    CupertinoIcons.exclamationmark_triangle_fill,
                    size: 48,
                    color: CupertinoColors.systemOrange,
                  ),
                  const SizedBox(height: InkSpacing.md),
                  Text(
                    'Network Timeout Encountered',
                    style: InkTypography.headline.copyWith(
                      color: InkColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: InkSpacing.sm),
                  Text(
                    showCreditRefund
                        ? 'The server clusters are running hot. Your 3 premium credits have been automatically refunded to your secure profile wallet.'
                        : 'The server clusters are running hot. Please check your connection and try generating again.',
                    style: InkTypography.body.copyWith(
                      color: InkColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: InkSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton.filled(
                      onPressed: onDismiss,
                      child: const Text('Continue'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
