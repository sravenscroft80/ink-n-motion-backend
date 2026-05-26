import 'package:flutter/cupertino.dart';
import 'package:ink_n_motion/services/navigation.dart';
import 'package:ink_n_motion/utils/design_tokens.dart';

class DiscoverPillarGrid extends StatelessWidget {
  const DiscoverPillarGrid({super.key});

  static const _pillars = [
    (
      title: 'Resource Library',
      snippet: 'Curated industry resources and books.',
      imageAsset: 'assets/images/ink_chronicles.png',
      route: InkRoutes.inkChronicles,
      category: 'LIBRARY',
    ),
    (
      title: 'Artist Spotlight',
      snippet: 'Creators pushing ink beyond the static frame.',
      imageAsset: 'assets/images/artist_spotlight.png',
      route: InkRoutes.artistSpotlight,
      category: 'SPOTLIGHT',
    ),
    (
      title: 'Tattoo Style Archive',
      snippet: 'Editorial histories of tattoo traditions and cultural origins.',
      imageAsset: 'assets/images/style_archive.png',
      route: InkRoutes.styleArchive,
      category: 'ARCHIVE',
    ),
    (
      title: 'AI Concept Generator',
      snippet: 'Describe your tattoo in one prompt. Instant generation.',
      imageAsset: 'assets/images/ai_coach.png',
      route: InkRoutes.aiCoach,
      category: 'GENERATOR',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: InkSpacing.sm,
        crossAxisSpacing: InkSpacing.sm,
        childAspectRatio: 0.88,
      ),
      itemCount: _pillars.length,
      itemBuilder: (context, index) {
        final pillar = _pillars[index];
        return _DiscoverPillarTile(
          title: pillar.title,
          snippet: pillar.snippet,
          imageAsset: pillar.imageAsset,
          category: pillar.category,
          onTap: () => InkNavigation.pushNamed(context, pillar.route),
        );
      },
    );
  }
}

class _DiscoverPillarTile extends StatelessWidget {
  const _DiscoverPillarTile({
    required this.title,
    required this.snippet,
    required this.imageAsset,
    required this.category,
    required this.onTap,
  });

  final String title;
  final String snippet;
  final String imageAsset;
  final String category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(InkRadius.lg),
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(imageAsset),
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: FractionallySizedBox(
                heightFactor: 1 / 3,
                widthFactor: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        CupertinoColors.transparent,
                        CupertinoColors.black.withValues(alpha: 0.75),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: InkSpacing.sm,
              left: InkSpacing.sm,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: CupertinoColors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  category,
                  style: InkTypography.caption2.copyWith(
                    fontSize: 9,
                    color: CupertinoColors.white,
                    letterSpacing: 1.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(InkSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    title,
                    style: InkTypography.footnote.copyWith(
                      fontWeight: FontWeight.w700,
                      color: InkColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: InkSpacing.xs),
                  Text(
                    snippet,
                    style: InkTypography.caption2.copyWith(
                      color: InkColors.textPrimary.withValues(alpha: 0.82),
                      height: 1.25,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Positioned(
              right: InkSpacing.md,
              bottom: InkSpacing.md,
              child: Icon(
                CupertinoIcons.chevron_right,
                size: 14,
                color: CupertinoColors.white.withValues(alpha: 0.54),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
