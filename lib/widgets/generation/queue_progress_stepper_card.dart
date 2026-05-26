import 'package:flutter/cupertino.dart';
import 'package:ink_n_motion/utils/design_tokens.dart';

/// Dark-mode Cupertino linear stepper for async cloud render checkpoints.
class QueueProgressStepperCard extends StatelessWidget {
  const QueueProgressStepperCard({
    super.key,
    required this.currentQueueStep,
    this.accentColor = CupertinoColors.activeBlue,
  });

  final String? currentQueueStep;
  final Color accentColor;

  static const _stepLabels = [
    'Registered in Cloud Queue',
    'AI Cluster Rendering',
    'Finalizing MP4 Stream',
  ];

  int _activeStepIndex(String? step) {
    switch (step) {
      case 'queued':
      case 'starting':
        return 0;
      case 'processing':
        return 1;
      case 'finalizing':
        return 2;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeIndex = _activeStepIndex(currentQueueStep);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: InkSpacing.md,
        vertical: InkSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6.darkColor.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(InkRadius.lg),
        border: Border.all(
          color: CupertinoColors.separator.darkColor.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const CupertinoActivityIndicator(radius: 12),
          const SizedBox(height: InkSpacing.lg),
          for (var i = 0; i < _stepLabels.length; i++) ...[
            if (i > 0) const SizedBox(height: InkSpacing.md),
            _StepRow(
              label: _stepLabels[i],
              index: i + 1,
              isComplete: i < activeIndex,
              isActive: i == activeIndex,
              accentColor: accentColor,
            ),
          ],
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.label,
    required this.index,
    required this.isComplete,
    required this.isActive,
    required this.accentColor,
  });

  final String label;
  final int index;
  final bool isComplete;
  final bool isActive;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final isHighlighted = isComplete || isActive;
    final indicatorColor = isComplete || isActive
        ? CupertinoColors.activeBlue
        : CupertinoColors.systemGrey;
    final labelColor = isHighlighted
        ? CupertinoColors.label.darkColor
        : CupertinoColors.systemGrey;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepIndicator(
          index: index,
          color: indicatorColor,
          filled: isComplete,
          ring: isActive && !isComplete,
          accentColor: accentColor,
        ),
        const SizedBox(width: InkSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: InkTypography.callout.copyWith(
                  color: labelColor,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              if (isActive) ...[
                const SizedBox(height: InkSpacing.xs),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: Container(
                    height: 3,
                    color: CupertinoColors.systemGrey4,
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: 0.62,
                      child: Container(
                        color: CupertinoColors.activeBlue,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({
    required this.index,
    required this.color,
    required this.filled,
    required this.ring,
    required this.accentColor,
  });

  final int index;
  final Color color;
  final bool filled;
  final bool ring;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? CupertinoColors.activeBlue : null,
        border: Border.all(
          color: ring ? CupertinoColors.activeBlue : color,
          width: ring ? 2.5 : 1.5,
        ),
      ),
      alignment: Alignment.center,
      child: filled
          ? const Icon(
              CupertinoIcons.check_mark,
              size: 14,
              color: CupertinoColors.white,
            )
          : Text(
              '$index',
              style: InkTypography.caption1.copyWith(
                color: ring ? CupertinoColors.activeBlue : color,
                fontWeight: FontWeight.w600,
              ),
            ),
    );
  }
}
