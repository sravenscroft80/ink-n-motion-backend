import 'package:flutter/cupertino.dart';
import 'package:ink_n_motion/utils/design_tokens.dart';
import 'package:ink_n_motion/widgets/discover/discover_hero_image.dart';

/// Premium pillar detail layout — hero image, gradient overlay, and nav bar.
class PillarDetailScaffold extends StatelessWidget {
  const PillarDetailScaffold({
    super.key,
    required this.heroImageAsset,
    required this.eyebrow,
    required this.title,
    this.subtitle,
    this.previousPageTitle = 'Discover',
    this.navTitle,
    required this.slivers,
  });

  final String heroImageAsset;
  final String eyebrow;
  final String title;
  final String? subtitle;
  final String previousPageTitle;
  final String? navTitle;
  final List<Widget> slivers;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: InkColors.backgroundPrimary,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: InkColors.backgroundPrimary.withValues(alpha: 0.88),
        border: null,
        previousPageTitle: previousPageTitle,
        middle: Text(navTitle ?? title),
      ),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          SliverToBoxAdapter(
            child: PillarHeroHeader(
              heroImageAsset: heroImageAsset,
              eyebrow: eyebrow,
              title: title,
              subtitle: subtitle,
            ),
          ),
          ...slivers,
        ],
      ),
    );
  }
}

class PillarHeroHeader extends StatelessWidget {
  const PillarHeroHeader({
    super.key,
    required this.heroImageAsset,
    required this.eyebrow,
    required this.title,
    this.subtitle,
  });

  final String heroImageAsset;
  final String eyebrow;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final heroHeight = MediaQuery.sizeOf(context).height * 0.36;
    return Stack(
      children: [
        SizedBox(
          height: heroHeight,
          width: double.infinity,
          child: DiscoverHeroImage(
            source: heroImageAsset,
            seed: title,
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  CupertinoColors.black.withValues(alpha: 0.12),
                  CupertinoColors.black.withValues(alpha: 0.45),
                  InkColors.backgroundPrimary,
                ],
                stops: const [0.0, 0.62, 1.0],
              ),
            ),
          ),
        ),
        Positioned(
          left: InkSpacing.xl,
          right: InkSpacing.xl,
          bottom: InkSpacing.lg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow.toUpperCase(),
                style: InkTypography.caption2.copyWith(
                  color: InkColors.accentGold,
                  letterSpacing: 1.6,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: InkSpacing.sm),
              Text(
                title,
                style: InkTypography.largeTitle.copyWith(
                  fontSize: 36,
                  height: 1.08,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: InkSpacing.xs),
                Text(
                  subtitle!,
                  style: InkTypography.footnote.copyWith(
                    color: InkColors.textSecondary,
                    letterSpacing: 0.3,
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

class PillarMuseumSection extends StatelessWidget {
  const PillarMuseumSection({super.key, required this.label, required this.body});

  final String label;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: InkSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: InkTypography.caption1.copyWith(
              color: InkColors.accentGold,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: InkSpacing.md),
          Text(
            body,
            style: InkTypography.body.copyWith(
              color: InkColors.textPrimary.withValues(alpha: 0.82),
              height: 1.65,
              letterSpacing: 0.15,
            ),
          ),
        ],
      ),
    );
  }
}
