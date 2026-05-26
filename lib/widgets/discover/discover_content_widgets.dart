import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ink_n_motion/models/discover_content.dart';
import 'package:ink_n_motion/services/content_service.dart';
import 'package:ink_n_motion/utils/design_tokens.dart';

final contentServiceProvider = Provider<ContentService>((ref) {
  return ContentService();
});

final discoverContentProvider = FutureProvider<DiscoverContent>((ref) {
  return ref.watch(contentServiceProvider).loadDiscoverContent();
});

final styleDetailProvider =
    FutureProvider.autoDispose.family<StyleArchiveEntry?, String>(
  (ref, styleId) {
    return ref.watch(contentServiceProvider).styleById(styleId);
  },
);

class DiscoverContentScaffold extends StatelessWidget {
  const DiscoverContentScaffold({
    super.key,
    required this.title,
    required this.body,
  });

  final String title;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: InkColors.backgroundPrimary,
      navigationBar: CupertinoNavigationBar(
        middle: Text(title),
        previousPageTitle: 'Discover',
      ),
      child: SafeArea(child: body),
    );
  }
}

class DiscoverContentLoader extends StatelessWidget {
  const DiscoverContentLoader({
    super.key,
    required this.builder,
  });

  final Widget Function(BuildContext context, DiscoverContent content) builder;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final contentAsync = ref.watch(discoverContentProvider);

        return contentAsync.when(
          loading: () => const Center(child: CupertinoActivityIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(InkSpacing.lg),
              child: Text(
                'Unable to load content.',
                style: InkTypography.subhead.copyWith(
                  color: InkColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          data: (content) => builder(context, content),
        );
      },
    );
  }
}

class DiscoverDailyArticle extends StatelessWidget {
  const DiscoverDailyArticle({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.body,
    this.meta,
  });

  final String eyebrow;
  final String title;
  final String body;
  final String? meta;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        InkSpacing.lg,
        InkSpacing.lg,
        InkSpacing.lg,
        InkSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            eyebrow,
            style: InkTypography.caption1.copyWith(
              color: InkColors.accentGold,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: InkSpacing.sm),
          Text(
            title,
            style: InkTypography.title2.copyWith(
              color: InkColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (meta != null) ...[
            const SizedBox(height: InkSpacing.xs),
            Text(
              meta!,
              style: InkTypography.footnote.copyWith(
                color: InkColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: InkSpacing.lg),
          Text(
            body,
            style: InkTypography.body.copyWith(
              color: InkColors.textPrimary.withValues(alpha: 0.86),
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}

class DiscoverStyleListTile extends StatelessWidget {
  const DiscoverStyleListTile({
    super.key,
    required this.entry,
    this.onTap,
  });

  final StyleArchiveEntry entry;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(InkSpacing.md),
        decoration: BoxDecoration(
          color: InkColors.backgroundSecondary,
          borderRadius: BorderRadius.circular(InkRadius.md),
          border: Border.all(
            color: InkColors.textPrimary.withValues(alpha: 0.06),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.name,
                          style: InkTypography.headline.copyWith(
                            color: InkColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      _HistoricalEraTag(era: entry.historicalEra),
                    ],
                  ),
                  const SizedBox(height: InkSpacing.xs),
                  Text(
                    entry.description,
                    style: InkTypography.subhead.copyWith(
                      color: InkColors.textPrimary.withValues(alpha: 0.72),
                      height: 1.45,
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: InkSpacing.sm),
              Icon(
                CupertinoIcons.chevron_right,
                size: 16,
                color: InkColors.textTertiary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HistoricalEraTag extends StatelessWidget {
  const _HistoricalEraTag({required this.era});

  final String era;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: InkSpacing.sm,
        vertical: InkSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: InkColors.backgroundElevated,
        borderRadius: BorderRadius.circular(InkRadius.sm),
        border: Border.all(
          color: InkColors.accentGoldMuted.withValues(alpha: 0.45),
        ),
      ),
      child: Text(
        era,
        style: InkTypography.caption2.copyWith(
          color: InkColors.accentGold,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.35,
        ),
      ),
    );
  }
}
