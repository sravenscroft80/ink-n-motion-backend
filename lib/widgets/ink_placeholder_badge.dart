import 'package:flutter/cupertino.dart';
import 'package:ink_n_motion/utils/design_tokens.dart';

class InkPlaceholderBadge extends StatelessWidget {
  const InkPlaceholderBadge({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: InkSpacing.sm,
        vertical: InkSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: InkColors.backgroundElevated,
        borderRadius: BorderRadius.circular(InkRadius.sm),
        border: Border.all(color: InkColors.textTertiary.withValues(alpha: 0.4)),
      ),
      child: Text(label, style: InkTypography.caption1),
    );
  }
}
