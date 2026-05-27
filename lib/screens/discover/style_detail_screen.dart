import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ink_n_motion/models/discover_content.dart';
import 'package:ink_n_motion/screens/discover/style_archive_screen.dart';
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
        const SliverToBoxAdapter(child: SizedBox(height: InkSpacing.xl)),
      ],
    );
  }
}

/// Museum plate silhouette — used for blocked paths and load failures.
