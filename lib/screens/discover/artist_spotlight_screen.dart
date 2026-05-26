import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ink_n_motion/constants/discover_assets.dart';
import 'package:ink_n_motion/models/spotlight_entry.dart';
import 'package:ink_n_motion/services/spotlight_service.dart';
import 'package:ink_n_motion/state/spotlight_providers.dart';
import 'package:ink_n_motion/utils/design_tokens.dart';
import 'package:ink_n_motion/widgets/discover/artist_profile_photo.dart';
import 'package:ink_n_motion/widgets/discover/magazine_detail_scaffold.dart';
import 'package:url_launcher/url_launcher.dart';

/// Artist Spotlight — artist-of-the-day from [artistOfTheDayProvider].
class ArtistSpotlightScreen extends ConsumerWidget {
  const ArtistSpotlightScreen({super.key});

  static const String _navTitle = 'Artist Spotlight';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(artistOfTheDayProvider, (previous, next) {
      next.whenData((entry) {
        debugPrint(
          'Spotlight: ${entry.name}, '
          'DayOfYear: ${SpotlightService.dayOfYear()}, '
          'Source: ${entry.profileUrl}',
        );
      });
    });

    final artistAsync = ref.watch(artistOfTheDayProvider);

    return artistAsync.when(
      loading: () => MagazineDetailScaffold(
        heroImageAsset: DiscoverAssets.spotlightAbstractHero,
        eyebrow: _navTitle,
        title: 'Loading…',
        navTitle: _navTitle,
        bodyWidget: const Center(child: CupertinoActivityIndicator()),
      ),
      error: (error, stackTrace) => MagazineDetailScaffold(
        heroImageAsset: DiscoverAssets.spotlightAbstractHero,
        eyebrow: _navTitle,
        title: _navTitle,
        navTitle: _navTitle,
        bodyWidget: Center(
          child: ArtistSpotlightProfileCard(
            entry: const SpotlightEntry(
              name: 'Ink-N-Motion Artist',
              profileUrl: '',
              portfolioLink: 'https://inkedmag.com/tattoo-artists/',
              bio:
                  'Curated tattoo artistry—explore featured work and discover your next piece.',
            ),
          ),
        ),
      ),
      data: (entry) => MagazineDetailScaffold(
        heroImageAsset: DiscoverAssets.spotlightAbstractHero,
        eyebrow: 'Artist of the Day · Day ${SpotlightService.dayOfYear()}',
        title: entry.name,
        navTitle: _navTitle,
        bodyWidget: ArtistSpotlightProfileCard(entry: entry),
      ),
    );
  }
}

class ArtistSpotlightProfileCard extends StatelessWidget {
  const ArtistSpotlightProfileCard({super.key, required this.entry});

  final SpotlightEntry entry;

  Future<void> _openPortfolioLink(BuildContext context) async {
    final uri = Uri.tryParse(entry.portfolioLink.trim());
    if (uri == null || !uri.hasScheme) return;

    final launched = await launchUrl(
      uri,
      mode: LaunchMode.inAppBrowserView,
    );

    if (!launched && context.mounted) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: InkColors.backgroundElevated,
        borderRadius: BorderRadius.circular(InkRadius.lg),
        border: Border.all(
          color: InkColors.textPrimary.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(InkSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ArtistProfilePhoto(profilePhotoUrl: entry.profileUrl),
                const SizedBox(width: InkSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.name,
                        style: InkTypography.title2.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.1,
                        ),
                      ),
                      const SizedBox(height: InkSpacing.xs),
                      Text(
                        'Artist of the Day',
                        style: InkTypography.subhead.copyWith(
                          color: InkColors.accentGold,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: InkSpacing.lg),
            Text(
              entry.bio,
              style: MagazineDetailScaffold.bodyStyle.copyWith(
                fontSize: 16,
                height: 1.62,
              ),
            ),
            if (entry.hasPortfolioLink) ...[
              const SizedBox(height: InkSpacing.lg),
              CupertinoButton(
                padding: const EdgeInsets.symmetric(vertical: InkSpacing.md),
                color: InkColors.accentGold,
                borderRadius: BorderRadius.circular(InkRadius.lg),
                onPressed: () => _openPortfolioLink(context),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.compass,
                      color: CupertinoColors.black.withValues(alpha: 0.88),
                      size: 18,
                    ),
                    const SizedBox(width: InkSpacing.sm),
                    Text(
                      'Explore Work',
                      style: InkTypography.headline.copyWith(
                        color: CupertinoColors.black.withValues(alpha: 0.88),
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
