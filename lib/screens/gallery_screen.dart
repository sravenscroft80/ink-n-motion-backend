import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ink_n_motion/state/providers.dart';
import 'package:ink_n_motion/utils/design_tokens.dart';
import 'package:ink_n_motion/widgets/video/ink_network_video_player.dart';

class GalleryScreen extends ConsumerWidget {
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paths = ref.watch(appStateProvider).generatedVideoPaths;
    final count = paths.length;

    return CupertinoPageScaffold(
      backgroundColor: InkColors.backgroundPrimary,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          // ── Branded header ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                InkSpacing.md, InkSpacing.lg, InkSpacing.md, InkSpacing.xs,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'INK GALLERY',
                          style: InkTypography.sectionLabel,
                        ),
                        const SizedBox(height: InkSpacing.xs),
                        Text(
                          'Your Ink, Alive.',
                          style: InkTypography.largeTitle,
                        ),
                      ],
                    ),
                  ),
                  if (count > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: InkColors.accentTeal.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: InkColors.accentTeal.withValues(alpha: 0.35),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '$count ${count == 1 ? 'animation' : 'animations'}',
                        style: InkTypography.caption1.copyWith(
                          color: InkColors.accentTeal,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ── Empty state or grid ─────────────────────────────────────
          if (paths.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _GalleryEmptyState(),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                InkSpacing.md, InkSpacing.sm, InkSpacing.md, InkSpacing.xl,
              ),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: InkSpacing.md,
                  crossAxisSpacing: InkSpacing.md,
                  childAspectRatio: 0.75,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _GalleryVideoTile(
                    path: paths[index],
                    index: index,
                  ),
                  childCount: paths.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GalleryEmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(InkSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Glowing icon
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: InkColors.accentGold.withValues(alpha: 0.08),
                border: Border.all(
                  color: InkColors.accentGold.withValues(alpha: 0.25),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: InkColors.accentGold.withValues(alpha: 0.15),
                    blurRadius: 32,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Icon(
                CupertinoIcons.wand_stars,
                size: 38,
                color: InkColors.accentGold,
              ),
            ),
            const SizedBox(height: InkSpacing.lg),
            Text(
              'No animations yet.',
              style: InkTypography.title3.copyWith(
                color: InkColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: InkSpacing.sm),
            Text(
              'Head to Motion Studio, upload your tattoo photo, pick a style and animate it. Your saved videos will live here.',
              style: InkTypography.subhead.copyWith(
                color: InkColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: InkSpacing.xl),
            // CTA hint
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: InkSpacing.md, vertical: InkSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: InkColors.accentGold.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(InkRadius.lg),
                border: Border.all(
                  color: InkColors.accentGold.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    CupertinoIcons.sparkles,
                    size: 14,
                    color: InkColors.accentGold,
                  ),
                  const SizedBox(width: InkSpacing.xs),
                  Text(
                    'Tap Studio below to get started',
                    style: InkTypography.caption1.copyWith(
                      color: InkColors.accentGold,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GalleryVideoTile extends StatelessWidget {
  const _GalleryVideoTile({
    required this.path,
    required this.index,
  });

  final String path;
  final int index;

  @override
  Widget build(BuildContext context) {
    final isPremium = path.contains('/premium/');
    final accent = isPremium ? InkColors.accentNeonMagenta : InkColors.accentTeal;
    final badgeLabel = isPremium ? '10s' : '5s';
    final badgeColor = isPremium ? InkColors.accentNeonMagenta : InkColors.accentGold;

    return InkTactileButton(
      onPressed: inkIsNetworkVideoUrl(path)
          ? () => FullscreenVideoPlayerScreen.open(context, path)
          : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(InkRadius.md),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF05070E),
            border: Border.all(color: accent.withValues(alpha: 0.4), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.18),
                blurRadius: 16,
                spreadRadius: -2,
              ),
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background glow
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 0.85,
                      colors: [
                        accent.withValues(alpha: 0.07),
                        const Color(0xFF05070E),
                      ],
                    ),
                  ),
                ),
              ),

              // Play icon
              Center(
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withValues(alpha: 0.15),
                    border: Border.all(
                      color: accent.withValues(alpha: 0.6),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    CupertinoIcons.play_fill,
                    size: 20,
                    color: accent,
                  ),
                ),
              ),

              // Duration badge top right
              Positioned(
                top: InkSpacing.sm,
                right: InkSpacing.sm,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: badgeColor.withValues(alpha: 0.5),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    badgeLabel,
                    style: InkTypography.caption2.copyWith(
                      color: badgeColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),

              // Bottom label gradient
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        const Color(0xFF05070E).withValues(alpha: 0.95),
                        const Color(0xFF05070E).withValues(alpha: 0.5),
                        CupertinoColors.transparent,
                      ],
                      stops: const [0.0, 0.6, 1.0],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      InkSpacing.sm, InkSpacing.lg, InkSpacing.sm, InkSpacing.sm,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Ink Animation ${index + 1}',
                          style: InkTypography.caption1.copyWith(
                            color: InkColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          isPremium ? 'Premium render' : 'Standard render',
                          style: InkTypography.caption2.copyWith(
                            color: InkColors.textSecondaryMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
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
