import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ink_n_motion/state/providers.dart';
import 'package:ink_n_motion/utils/design_tokens.dart';
import 'package:ink_n_motion/widgets/ink_frosted_glass.dart';

class StudioStyleOption {
  const StudioStyleOption({
    required this.templateId,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.accent,
    this.isPremium = false,
    this.showPremiumBadge = false,
  });

  final String templateId;
  final String label;
  final String subtitle;
  final IconData icon;
  final Color accent;
  /// Premium rendering track — gradient border when selected.
  final bool isPremium;
  /// Catalog chip badge — only the four full-name style chips.
  final bool showPremiumBadge;

  double get chipWidth => showPremiumBadge ? 130 : 110;

  static const Set<String> premiumBadgeTemplateIds = {
    'cyberpunk_neon_glow',
    'traditional_japanese_ink_flow',
    'animated_pop_3d',
    'monochrome_shadow',
    'alex_grey_visionary',
    'steampunk_clockwork',
    'anime_cel_shaded',
    'gothic_horror',
  };
}

/// Horizontal frosted style pills for the Studio capture surface.
class StudioStylePicker extends ConsumerWidget {
  const StudioStylePicker({
    super.key,
    required this.options,
    required this.selectedTemplateId,
    this.selectedLabel,
    required this.onSelected,
  });

  static const List<StudioStyleOption> defaultOptions = [
    StudioStyleOption(
      templateId: 'traditional_japanese_ink_flow',
      label: 'Fluid',
      subtitle: 'Organic waves',
      icon: CupertinoIcons.circle_grid_3x3,
      accent: InkColors.accentTeal,
    ),
    StudioStyleOption(
      templateId: 'animated_pop_3d',
      label: 'Sparkle',
      subtitle: 'Light bursts',
      icon: CupertinoIcons.sparkles,
      accent: InkColors.accentGoldBright,
    ),
    StudioStyleOption(
      templateId: 'cyberpunk_neon_glow',
      label: 'Neon Pulse',
      subtitle: 'Electric grid',
      icon: CupertinoIcons.hexagon,
      accent: InkColors.accentTeal,
    ),
  ];

  /// Full scrollable row: short names first, then catalog display names.
  static const List<StudioStyleOption> allStudioOptions = [
    ...defaultOptions,
    StudioStyleOption(
      templateId: 'cyberpunk_neon_glow',
      label: 'Cyberpunk Neon Glow',
      subtitle: 'Premium track',
      icon: CupertinoIcons.hexagon_fill,
      accent: InkColors.accentTeal,
      isPremium: true,
      showPremiumBadge: true,
    ),
    StudioStyleOption(
      templateId: 'traditional_japanese_ink_flow',
      label: 'Traditional Japanese Ink Flow',
      subtitle: 'Premium track',
      icon: CupertinoIcons.circle_grid_3x3_fill,
      accent: InkColors.accentTeal,
      isPremium: true,
      showPremiumBadge: true,
    ),
    StudioStyleOption(
      templateId: 'animated_pop_3d',
      label: 'Animated Pop 3D',
      subtitle: 'Easy track',
      icon: CupertinoIcons.sparkles,
      accent: InkColors.accentGoldBright,
      showPremiumBadge: true,
    ),
    StudioStyleOption(
      templateId: 'monochrome_shadow',
      label: 'Monochrome Shadow',
      subtitle: 'Easy · depth shadows',
      icon: CupertinoIcons.circle_lefthalf_fill,
      accent: InkColors.textSecondaryMuted,
      showPremiumBadge: true,
    ),
    StudioStyleOption(
      templateId: 'alex_grey_visionary',
      label: 'Alex Grey Visionary',
      subtitle: 'Premium track',
      icon: CupertinoIcons.eye_fill,
      accent: InkColors.premiumGradientStart,
      isPremium: true,
      showPremiumBadge: true,
    ),
    StudioStyleOption(
      templateId: 'steampunk_clockwork',
      label: 'Steampunk Clockwork',
      subtitle: 'Premium track',
      icon: CupertinoIcons.clock_fill,
      accent: Color(0xFFB87333),
      isPremium: true,
      showPremiumBadge: true,
    ),
    StudioStyleOption(
      templateId: 'anime_cel_shaded',
      label: 'Anime Cel-Shaded',
      subtitle: 'Premium track',
      icon: CupertinoIcons.bolt_fill,
      accent: InkColors.accentNeonMagenta,
      isPremium: true,
      showPremiumBadge: true,
    ),
    StudioStyleOption(
      templateId: 'gothic_horror',
      label: 'Gothic Horror',
      subtitle: 'Premium track',
      icon: CupertinoIcons.moon_fill,
      accent: InkColors.textSecondaryMuted,
      isPremium: true,
      showPremiumBadge: true,
    ),
  ];

  final List<StudioStyleOption> options;
  final String? selectedTemplateId;
  final String? selectedLabel;
  final ValueChanged<StudioStyleOption> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    StudioStyleOption? selectedOption;
    if (selectedTemplateId != null) {
      for (final option in options) {
        if (option.templateId != selectedTemplateId) continue;
        if (selectedLabel == null || option.label == selectedLabel) {
          selectedOption = option;
          break;
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _StyleSectionDivider(),
        const SizedBox(height: InkSpacing.md),
        SizedBox(
          height: 108,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: InkSpacing.md),
            itemCount: options.length,
            separatorBuilder: (context, index) => const SizedBox(width: InkSpacing.sm),
            itemBuilder: (context, index) {
              final option = options[index];
              final isActive = selectedOption != null &&
                  option.templateId == selectedOption.templateId &&
                  option.label == selectedOption.label;
              return _StudioStylePill(
                option: option,
                isActive: isActive,
                onTap: () {
                  ref
                      .read(appStateProvider.notifier)
                      .setSelectedStyleTemplate(option.templateId);
                  onSelected(option);
                },
              );
            },
          ),
        ),
        const SizedBox(height: InkSpacing.sm),
        Text(
          selectedOption == null
              ? 'Step 2: Choose your animation style'
              : '${selectedOption.label} mode selected',
          textAlign: TextAlign.center,
          style: InkTypography.caption1.copyWith(
            color: InkColors.textSecondaryMuted,
          ),
        ),
      ],
    );
  }
}

class _StyleSectionDivider extends StatelessWidget {
  const _StyleSectionDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: InkSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              color: InkColors.textPrimary.withValues(alpha: 0.08),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: InkSpacing.sm),
            child: Text(
              'STYLE',
              style: InkTypography.sectionLabel,
            ),
          ),
          Expanded(
            child: Container(
              height: 1,
              color: InkColors.textPrimary.withValues(alpha: 0.08),
            ),
          ),
        ],
      ),
    );
  }
}

class _StudioStylePill extends StatelessWidget {
  const _StudioStylePill({
    required this.option,
    required this.isActive,
    required this.onTap,
  });

  final StudioStyleOption option;
  final bool isActive;
  final VoidCallback onTap;

  static const double _chipHeight = 100;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(InkRadius.lg);
    final showPremiumBorder = option.isPremium && isActive;
    final showFreeBorder = !option.isPremium && isActive;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        width: option.chipWidth,
        height: _chipHeight,
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          gradient: showPremiumBorder ? InkColors.premiumChipGradient : null,
          border: showFreeBorder
              ? Border.all(
                  color: InkColors.accentTeal.withValues(alpha: 0.95),
                  width: 1.5,
                )
              : null,
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: (option.isPremium
                            ? InkColors.premiumGradientStart
                            : InkColors.accentTeal)
                        .withValues(alpha: 0.25),
                    blurRadius: 12,
                    spreadRadius: -2,
                  ),
                ]
              : null,
        ),
        child: Padding(
          padding: EdgeInsets.all(showPremiumBorder ? 1.5 : 0),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              InkFrostedGlass(
                showBorder: false,
                borderRadius: InkRadius.lg,
                sigma: 22,
                padding: const EdgeInsets.fromLTRB(
                  InkSpacing.sm,
                  InkSpacing.sm,
                  InkSpacing.sm,
                  InkSpacing.xs,
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: showPremiumBorder ? _chipHeight - 3 : _chipHeight,
                  child: Column(
                    children: [
                      Icon(
                        option.icon,
                        size: 20,
                        color: isActive
                            ? (option.isPremium
                                ? InkColors.accentGoldBright
                                : InkColors.accentTeal)
                            : option.accent,
                      ),
                      const SizedBox(height: InkSpacing.xs),
                      Expanded(
                        child: Align(
                          alignment: Alignment.center,
                          child: Text(
                            option.label,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: InkTypography.caption2.copyWith(
                              color: isActive
                                  ? InkColors.textPrimary
                                  : InkColors.textSecondary,
                              fontWeight: FontWeight.w600,
                              height: 1.15,
                            ),
                          ),
                        ),
                      ),
                      Text(
                        option.subtitle,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: InkTypography.caption2.copyWith(
                          color: InkColors.textTertiary,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (option.showPremiumBadge &&
                  StudioStyleOption.premiumBadgeTemplateIds
                      .contains(option.templateId))
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      gradient: InkColors.premiumChipGradient,
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: InkColors.premiumGradientStart
                              .withValues(alpha: 0.4),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Text(
                      '✨ PREMIUM',
                      style: InkTypography.caption2.copyWith(
                        color: InkColors.textPrimary,
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                        height: 1.1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
