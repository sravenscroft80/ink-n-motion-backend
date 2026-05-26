import 'package:flutter/cupertino.dart';
import 'package:ink_n_motion/utils/design_tokens.dart';
import 'package:ink_n_motion/widgets/discover/discover_hero_image.dart';

/// Magazine-style pillar detail — full-bleed hero, overlay nav, premium body.
class MagazineDetailScaffold extends StatelessWidget {
  const MagazineDetailScaffold({
    super.key,
    required this.heroImageAsset,
    required this.eyebrow,
    required this.title,
    this.subtitle,
    this.navTitle,
    this.previousPageTitle = 'Discover',
    this.body,
    this.bodyWidget,
    this.interactiveBody,
    this.bottomBar,
    this.heroHeightFactor = 0.44,
    this.onRefreshPressed,
    this.heroImageSeed,
  }) : assert(
          (body != null || bodyWidget != null) ^ (interactiveBody != null),
          'Provide scroll body (body/bodyWidget) or interactiveBody, not both.',
        );

  final String heroImageAsset;
  final String eyebrow;
  final String title;
  final String? subtitle;
  final String? navTitle;
  final String previousPageTitle;
  final String? body;
  final Widget? bodyWidget;
  final Widget? interactiveBody;
  final Widget? bottomBar;
  final double heroHeightFactor;

  /// When set, shows a trailing refresh control on the overlay navigation bar.
  final VoidCallback? onRefreshPressed;

  /// Seed for museum-grade fallback art (defaults to [title] in hero).
  final String? heroImageSeed;

  static TextStyle get eyebrowStyle => InkTypography.caption2.copyWith(
        color: InkColors.accentGold,
        letterSpacing: 1.6,
        fontWeight: FontWeight.w700,
      );

  static TextStyle get heroTitleStyle => InkTypography.largeTitle.copyWith(
        fontSize: 34,
        height: 1.1,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.2,
      );

  static TextStyle get heroSubtitleStyle => InkTypography.subhead.copyWith(
        color: InkColors.textPrimary.withValues(alpha: 0.82),
        letterSpacing: 0.35,
        fontWeight: FontWeight.w500,
      );

  static TextStyle get bodyStyle => InkTypography.body.copyWith(
        fontSize: 18,
        height: 1.68,
        letterSpacing: 0.25,
        color: InkColors.textPrimary.withValues(alpha: 0.88),
        fontWeight: FontWeight.w400,
      );

  @override
  Widget build(BuildContext context) {
    if (interactiveBody != null) {
      return _buildInteractiveLayout(context);
    }
    return _buildScrollLayout(context);
  }

  Widget _buildInteractiveLayout(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    final heroHeight = MediaQuery.sizeOf(context).height * heroHeightFactor;
    final totalHeroHeight = heroHeight + topInset;

    return CupertinoPageScaffold(
      backgroundColor: InkColors.backgroundPrimary,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: totalHeroHeight,
                width: double.infinity,
                child: _MagazineHero(
                  heroImageAsset: heroImageAsset,
                  heroImageSeed: heroImageSeed ?? title,
                  eyebrow: eyebrow,
                  title: title,
                  subtitle: subtitle,
                ),
              ),
              Expanded(child: interactiveBody!),
              ?bottomBar,
            ],
          ),
          _MagazineNavigationBar(
            previousPageTitle: previousPageTitle,
            navTitle: navTitle ?? title,
            onRefreshPressed: onRefreshPressed,
          ),
        ],
      ),
    );
  }

  Widget _buildScrollLayout(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    final heroHeight = MediaQuery.sizeOf(context).height * heroHeightFactor;
    final totalHeroHeight = heroHeight + topInset;

    return CupertinoPageScaffold(
      backgroundColor: InkColors.backgroundPrimary,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: SizedBox(
                  height: totalHeroHeight,
                  width: double.infinity,
                  child: _MagazineHero(
                    heroImageAsset: heroImageAsset,
                    heroImageSeed: heroImageSeed ?? title,
                    eyebrow: eyebrow,
                    title: title,
                    subtitle: subtitle,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(InkSpacing.xl),
                  child: bodyWidget ??
                      Text(
                        body!,
                        style: bodyStyle,
                      ),
                ),
              ),
            ],
          ),
          _MagazineNavigationBar(
            previousPageTitle: previousPageTitle,
            navTitle: navTitle ?? title,
            onRefreshPressed: onRefreshPressed,
          ),
        ],
      ),
    );
  }
}

class _MagazineHero extends StatelessWidget {
  const _MagazineHero({
    required this.heroImageAsset,
    required this.heroImageSeed,
    required this.eyebrow,
    required this.title,
    this.subtitle,
  });

  final String heroImageAsset;
  final String heroImageSeed;
  final String eyebrow;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DiscoverHeroImage(source: heroImageAsset, seed: heroImageSeed),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                CupertinoColors.black.withValues(alpha: 0.92),
                CupertinoColors.black.withValues(alpha: 0.52),
                CupertinoColors.black.withValues(alpha: 0.0),
              ],
              stops: const [0.0, 0.42, 0.88],
            ),
          ),
        ),
        Positioned(
          left: InkSpacing.xl,
          right: InkSpacing.xl,
          bottom: InkSpacing.xl,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow.toUpperCase(),
                style: MagazineDetailScaffold.eyebrowStyle,
              ),
              const SizedBox(height: InkSpacing.sm),
              Text(
                title,
                style: MagazineDetailScaffold.heroTitleStyle,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: InkSpacing.xs),
                Text(
                  subtitle!,
                  style: MagazineDetailScaffold.heroSubtitleStyle,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _MagazineNavigationBar extends StatelessWidget {
  const _MagazineNavigationBar({
    required this.previousPageTitle,
    required this.navTitle,
    this.onRefreshPressed,
  });

  final String previousPageTitle;
  final String navTitle;
  final VoidCallback? onRefreshPressed;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: CupertinoTheme(
          data: CupertinoTheme.of(context).copyWith(
            primaryColor: InkColors.textPrimary,
            barBackgroundColor: const Color(0x00000000),
          ),
          child: CupertinoNavigationBar(
            backgroundColor: const Color(0x00000000),
            border: null,
            transitionBetweenRoutes: false,
            previousPageTitle: previousPageTitle,
            middle: Text(
              navTitle,
              style: InkTypography.headline.copyWith(
                color: InkColors.textPrimary,
              ),
            ),
            trailing: onRefreshPressed == null
                ? null
                : CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: onRefreshPressed,
                    child: Icon(
                      CupertinoIcons.refresh,
                      color: InkColors.textPrimary,
                      semanticLabel: 'Refresh',
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
