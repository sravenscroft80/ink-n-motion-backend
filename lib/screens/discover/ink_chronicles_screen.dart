import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ink_n_motion/screens/home_screen.dart';
import 'package:ink_n_motion/utils/design_tokens.dart';
import 'package:ink_n_motion/widgets/discover/discover_content_widgets.dart';
import 'package:ink_n_motion/widgets/discover/magazine_detail_scaffold.dart';

/// Ink Chronicles — synced to [discoverContentProvider] via [ref.watch].
class InkChroniclesScreen extends ConsumerWidget {
  const InkChroniclesScreen({super.key});

  static const String _navTitle = 'Ink Chronicles';

  void _refreshDiscoverContent(WidgetRef ref) {
    ref.read(contentServiceProvider).clearCaches();
    // ignore: unused_result — re-runs the provider future after cache clear.
    ref.refresh(discoverContentProvider);
  }

  MagazineDetailScaffold _scaffold({
    required String heroImageAsset,
    required String heroImageSeed,
    required String eyebrow,
    required String title,
    String? body,
    Widget? bodyWidget,
    required VoidCallback onRefreshPressed,
  }) {
    return MagazineDetailScaffold(
      heroImageAsset: heroImageAsset,
      heroImageSeed: heroImageSeed,
      eyebrow: eyebrow,
      title: title,
      navTitle: _navTitle,
      body: body,
      bodyWidget: bodyWidget,
      onRefreshPressed: onRefreshPressed,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contentAsync = ref.watch(discoverContentProvider);

    return contentAsync.when(
      loading: () => _scaffold(
        heroImageAsset: HomeScreen.inkChroniclesHero,
        heroImageSeed: 'ink-chronicles-loading',
        eyebrow: _navTitle,
        title: 'Loading…',
        bodyWidget: const Center(child: CupertinoActivityIndicator()),
        onRefreshPressed: () => _refreshDiscoverContent(ref),
      ),
      error: (error, stackTrace) => _scaffold(
        heroImageAsset: HomeScreen.inkChroniclesHero,
        heroImageSeed: 'ink-chronicles-error',
        eyebrow: _navTitle,
        title: _navTitle,
        bodyWidget: Center(
          child: Text(
            'Unable to load content.',
            style: InkTypography.subhead.copyWith(
              color: InkColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        onRefreshPressed: () => _refreshDiscoverContent(ref),
      ),
      data: (content) {
        if (content.inkChronicles.isEmpty) {
          return _scaffold(
            heroImageAsset: HomeScreen.inkChroniclesHero,
            heroImageSeed: 'ink-chronicles-empty',
            eyebrow: _navTitle,
            title: _navTitle,
            bodyWidget: Center(
              child: Text(
                'No chronicles available.',
                style: InkTypography.subhead.copyWith(
                  color: InkColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            onRefreshPressed: () => _refreshDiscoverContent(ref),
          );
        }

        final entry = content.chronicleForToday();

        return _scaffold(
          heroImageAsset: entry.heroImage,
          heroImageSeed: entry.title,
          eyebrow: entry.subtitle,
          title: entry.title,
          body: entry.body,
          onRefreshPressed: () => _refreshDiscoverContent(ref),
        );
      },
    );
  }
}
