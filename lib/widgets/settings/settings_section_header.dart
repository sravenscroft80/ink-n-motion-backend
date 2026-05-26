import 'package:flutter/cupertino.dart';
import 'package:ink_n_motion/utils/design_tokens.dart';

/// Gold bar + spaced caps label — matches Discover EXPLORE section style.
class SettingsSectionHeader extends StatelessWidget {
  const SettingsSectionHeader({super.key, required this.label});

  static const Color sectionGold = Color(0xFFD4A017);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: InkSpacing.md,
        right: InkSpacing.md,
        top: InkSpacing.lg,
        bottom: InkSpacing.sm,
      ),
      child: Row(
        children: [
          Container(
            width: 2,
            height: 14,
            color: sectionGold,
          ),
          const SizedBox(width: InkSpacing.sm),
          Text(
            label,
            style: InkTypography.caption2.copyWith(
              fontSize: 11,
              letterSpacing: 3.0,
              fontWeight: FontWeight.w600,
              color: InkColors.textPrimary.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
