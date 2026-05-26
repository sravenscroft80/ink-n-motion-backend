import 'package:flutter/cupertino.dart';
import 'package:ink_n_motion/utils/design_tokens.dart';

/// Bold gold section label for Discover landing sections.
class DiscoverWorkflowLabel extends StatelessWidget {
  const DiscoverWorkflowLabel({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      'Workflow',
      style: InkTypography.title3.copyWith(
        color: InkColors.accentGold,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.4,
      ),
    );
  }
}

/// Section label for the Explore pillars grid.
class DiscoverPillarSectionLabel extends StatelessWidget {
  const DiscoverPillarSectionLabel({super.key});

  static const Color _sectionGold = Color(0xFFD4A017);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 2,
          height: 14,
          color: _sectionGold,
        ),
        const SizedBox(width: InkSpacing.sm),
        Text(
          'EXPLORE',
          style: InkTypography.caption2.copyWith(
            fontSize: 11,
            letterSpacing: 3.0,
            fontWeight: FontWeight.w600,
            color: InkColors.textPrimary.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}
