import 'package:flutter/cupertino.dart';
import 'package:ink_n_motion/models/paywall_tier.dart';
import 'package:ink_n_motion/utils/design_tokens.dart';

/// Selectable iOS-style paywall tier card with price tag and optional badge.
class PaywallTierCard extends StatelessWidget {
  const PaywallTierCard({
    super.key,
    required this.tier,
    required this.selected,
    required this.onSelect,
    required this.onPurchase,
    this.isProcessing = false,
  });

  final PaywallTier tier;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onPurchase;
  final bool isProcessing;

  @override
  Widget build(BuildContext context) {
    final accent = tier.grantsPremium
        ? InkColors.accentNeonMagenta
        : InkColors.accentNeonCyan;

    return Padding(
      padding: const EdgeInsets.only(bottom: InkSpacing.md),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onSelect,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(InkSpacing.md),
          decoration: BoxDecoration(
            color: InkColors.backgroundSecondary,
            borderRadius: BorderRadius.circular(InkRadius.lg),
            border: Border.all(
              color: selected
                  ? accent
                  : InkColors.textTertiary.withValues(alpha: 0.35),
              width: selected ? 2 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.3),
                      blurRadius: 18,
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (tier.badge != null) ...[
                _TierBadge(badge: tier.badge!, accent: accent),
                const SizedBox(height: InkSpacing.sm),
              ],
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tier.title, style: InkTypography.headline),
                        const SizedBox(height: InkSpacing.xs),
                        Text(tier.subtitle, style: InkTypography.subhead),
                        if (tier.secondaryPriceLabel != null) ...[
                          const SizedBox(height: InkSpacing.xs),
                          Text(
                            tier.secondaryPriceLabel!,
                            style: InkTypography.caption1.copyWith(
                              color: InkColors.accentGold,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: InkSpacing.sm,
                      vertical: InkSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(InkRadius.sm),
                    ),
                    child: Text(
                      tier.priceLabel,
                      style: InkTypography.headline.copyWith(color: accent),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: InkSpacing.md),
              SizedBox(
                width: double.infinity,
                child: CupertinoButton.filled(
                  color: accent,
                  onPressed: isProcessing ? null : onPurchase,
                  child: isProcessing
                      ? const CupertinoActivityIndicator()
                      : Text(tier.grantsPremium ? 'Subscribe' : 'Purchase'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TierBadge extends StatelessWidget {
  const _TierBadge({required this.badge, required this.accent});

  final PaywallBadge badge;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final label = switch (badge) {
      PaywallBadge.mostPopular => 'Most Popular',
      PaywallBadge.bestValue => 'Best Value',
      PaywallBadge.artistDirectory => '🎨 Artist Directory',
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: InkSpacing.sm,
        vertical: InkSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(InkRadius.sm),
        border: Border.all(color: accent.withValues(alpha: 0.45)),
      ),
      child: Text(
        label,
        style: InkTypography.caption1.copyWith(
          color: accent,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
