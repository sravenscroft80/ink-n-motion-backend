import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ink_n_motion/models/discover_content.dart';
import 'package:ink_n_motion/screens/discover/style_archive_screen.dart';
import 'package:ink_n_motion/widgets/discover/discover_hero_image.dart';
import 'package:ink_n_motion/utils/design_tokens.dart';
import 'package:ink_n_motion/widgets/discover/discover_content_widgets.dart';
import 'package:ink_n_motion/widgets/discover/pillar_detail_scaffold.dart';

class StyleDetailScreen extends ConsumerWidget {
  const StyleDetailScreen({super.key, required this.styleId});

  final String styleId;

  static const String _navTitle = StyleArchiveScreen.screenTitle;
  static const String _previousPageTitle = StyleArchiveScreen.screenTitle;

  /// Bundled placeholder for loading/error chrome only — not used for loaded entries.
  static const String _loadingHeroAsset = 'assets/images/style_archive.png';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entryAsync = ref.watch(styleDetailProvider(styleId));

    return entryAsync.when(
      loading: () => const PillarDetailScaffold(
        heroImageAsset: _loadingHeroAsset,
        eyebrow: 'Museum Entry',
        title: 'Loading…',
        navTitle: _navTitle,
        previousPageTitle: _previousPageTitle,
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: CupertinoActivityIndicator()),
          ),
        ],
      ),
      error: (error, stackTrace) => const PillarDetailScaffold(
        heroImageAsset: _loadingHeroAsset,
        eyebrow: 'Museum Entry',
        title: 'Style',
        navTitle: _navTitle,
        previousPageTitle: _previousPageTitle,
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Text('Unable to load museum entry.'),
            ),
          ),
        ],
      ),
      data: (entry) {
        if (entry == null) {
          return const PillarDetailScaffold(
            heroImageAsset: _loadingHeroAsset,
            eyebrow: 'Museum Entry',
            title: 'Not Found',
            navTitle: _navTitle,
            previousPageTitle: _previousPageTitle,
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text('Style not found in the archive.'),
                ),
              ),
            ],
          );
        }
        return _StyleDetailBody(entry: entry);
      },
    );
  }
}

class _StyleDetailBody extends StatelessWidget {
  const _StyleDetailBody({required this.entry});

  final StyleArchiveEntry entry;

  @override
  Widget build(BuildContext context) {
    final historical = entry.historicalReferences;
    final modern = entry.modernInterpretations;

    return PillarDetailScaffold(
      heroImageAsset: entry.heroImage,
      eyebrow: 'Museum Entry',
      title: entry.name,
      subtitle: entry.historicalEra,
      navTitle: entry.name,
      previousPageTitle: StyleDetailScreen._previousPageTitle,
      slivers: [
        if (entry.hasDescription)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                InkSpacing.xl,
                InkSpacing.lg,
                InkSpacing.xl,
                InkSpacing.md,
              ),
              child: Text(
                entry.description,
                style: InkTypography.title3.copyWith(
                  color: InkColors.textPrimary.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                  letterSpacing: 0.15,
                ),
              ),
            ),
          ),
        if (entry.hasOrigin)
          SliverToBoxAdapter(
            child: PillarMuseumSection(
              label: 'Origin',
              body: entry.origin,
            ),
          ),
        if (entry.hasTechnique)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(top: entry.hasOrigin ? InkSpacing.xl : 0),
              child: PillarMuseumSection(
                label: 'Technique',
                body: entry.technique,
              ),
            ),
          ),
        if (entry.hasGallery && historical.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: _MuseumGallerySectionHeader(
              title: 'Historical References',
              topPadding: _galleryTopPadding(entry),
            ),
          ),
          _MuseumGalleryGrid(images: historical),
        ],
        if (entry.hasGallery && modern.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: _MuseumGallerySectionHeader(
              title: 'Modern Interpretations',
              topPadding: entry.hasGallery && historical.isNotEmpty
                  ? InkSpacing.lg
                  : _galleryTopPadding(entry),
            ),
          ),
          _MuseumGalleryGrid(images: modern),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: InkSpacing.xl)),
      ],
    );
  }

  static double _galleryTopPadding(StyleArchiveEntry entry) {
    if (entry.hasDescription || entry.hasOrigin || entry.hasTechnique) {
      return InkSpacing.xl;
    }
    return InkSpacing.lg;
  }
}

class _MuseumGallerySectionHeader extends StatelessWidget {
  const _MuseumGallerySectionHeader({
    required this.title,
    this.topPadding = InkSpacing.xl,
  });

  final String title;
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        InkSpacing.xl,
        topPadding,
        InkSpacing.xl,
        InkSpacing.sm,
      ),
      child: Text(
        title.toUpperCase(),
        style: InkTypography.caption2.copyWith(
          color: InkColors.accentGoldMuted,
          letterSpacing: 1.4,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MuseumGalleryGrid extends StatelessWidget {
  const _MuseumGalleryGrid({required this.images});

  final List<StyleGalleryImage> images;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        InkSpacing.xl,
        InkSpacing.sm,
        InkSpacing.xl,
        0,
      ),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: InkSpacing.md,
          crossAxisSpacing: InkSpacing.md,
          childAspectRatio: 0.78,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => _MuseumGalleryTile(image: images[index]),
          childCount: images.length,
        ),
      ),
    );
  }
}

class _MuseumGalleryTile extends StatelessWidget {
  const _MuseumGalleryTile({required this.image});

  final StyleGalleryImage image;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(InkRadius.md),
            child: DiscoverHeroImage(
              source: image.asset,
              seed: image.caption,
            ),
          ),
        ),
        const SizedBox(height: InkSpacing.sm),
        Text(
          image.referenceType.displayLabel,
          style: InkTypography.caption2.copyWith(
            color: InkColors.accentGold,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.35,
          ),
        ),
        const SizedBox(height: InkSpacing.xs),
        Text(
          image.caption,
          style: InkTypography.caption1.copyWith(
            color: InkColors.textSecondary,
            height: 1.35,
          ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

/// Museum plate silhouette — used for blocked paths and load failures.
