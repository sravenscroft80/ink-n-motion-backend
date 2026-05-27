import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show CircularProgressIndicator;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ink_n_motion/models/discover_content.dart';
import 'package:ink_n_motion/services/navigation.dart';
import 'package:ink_n_motion/utils/design_tokens.dart';
import 'package:ink_n_motion/widgets/discover/discover_content_widgets.dart';

class StyleArchiveScreen extends ConsumerWidget {
  const StyleArchiveScreen({super.key});

  static const String screenTitle = 'Tattoo Style Archive';

  static const Color _backgroundColor = Color(0xFF0D0D0D);
  static const Color _cardColor = Color(0xFF1A1A1A);

  static const String _subtitle = 'From ancient roots to modern movements';

  List<StyleArchiveEntry> _visibleStyles(List<StyleArchiveEntry> styles) {
    return styles.where((entry) {
      if (entry.id == 'nordic-runes') return false;
      if (entry.heroImage.contains('ai_coach.png')) return false;
      return true;
    }).toList();
  }

  String _descriptionPreview(String description) {
    final trimmed = description.trim();
    if (trimmed.length <= 80) return trimmed;
    return '${trimmed.substring(0, 80)}…';
  }

  void _openStyleDetail(BuildContext context, String styleId) {
    InkNavigation.pushStyleDetail(context, styleId);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contentAsync = ref.watch(discoverContentProvider);

    return CupertinoPageScaffold(
      backgroundColor: _backgroundColor,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StyleArchiveHeader(
              onBack: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: contentAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: InkColors.accentGold,
                  ),
                ),
                error: (error, stackTrace) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(InkSpacing.lg),
                    child: Text(
                      'Unable to load style archive.',
                      style: InkTypography.subhead.copyWith(
                        color: InkColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                data: (content) {
                  final styles = _visibleStyles(content.styleArchive);
                  if (styles.isEmpty) {
                    return Center(
                      child: Text(
                        'Style archive loading...',
                        style: InkTypography.subhead.copyWith(
                          color: InkColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  return ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      InkSpacing.md,
                      InkSpacing.sm,
                      InkSpacing.md,
                      InkSpacing.xl,
                    ),
                    itemCount: styles.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: InkSpacing.sm),
                    itemBuilder: (context, index) {
                      final entry = styles[index];
                      return _StyleArchiveCard(
                        entry: entry,
                        descriptionPreview:
                            _descriptionPreview(entry.description),
                        onTap: () => _openStyleDetail(context, entry.id),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StyleArchiveHeader extends StatelessWidget {
  const _StyleArchiveHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        InkSpacing.xs,
        InkSpacing.sm,
        InkSpacing.md,
        InkSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            onPressed: onBack,
            child: const Icon(
              CupertinoIcons.back,
              color: InkColors.textPrimary,
              size: 28,
            ),
          ),
          const SizedBox(height: InkSpacing.sm),
          Text(
            StyleArchiveScreen.screenTitle,
            style: InkTypography.title2.copyWith(
              color: InkColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: InkSpacing.xs),
          Text(
            StyleArchiveScreen._subtitle,
            style: InkTypography.subhead.copyWith(
              color: InkColors.accentGold,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _StyleArchiveCard extends StatelessWidget {
  const _StyleArchiveCard({
    required this.entry,
    required this.descriptionPreview,
    required this.onTap,
  });

  final StyleArchiveEntry entry;
  final String descriptionPreview;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(InkSpacing.md),
        decoration: BoxDecoration(
          color: StyleArchiveScreen._cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                entry.heroImage,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 80,
                  height: 80,
                  color: InkColors.backgroundElevated,
                  alignment: Alignment.center,
                  child: Icon(
                    CupertinoIcons.photo,
                    color: InkColors.textTertiary,
                    size: 28,
                  ),
                ),
              ),
            ),
            const SizedBox(width: InkSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.name,
                    style: const TextStyle(
                      color: InkColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: InkSpacing.xs),
                  _EraPillBadge(era: entry.historicalEra),
                  const SizedBox(height: InkSpacing.xs),
                  Text(
                    descriptionPreview,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: InkColors.textSecondary,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: InkSpacing.sm),
            const Icon(
              CupertinoIcons.chevron_right,
              size: 18,
              color: InkColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

class _EraPillBadge extends StatelessWidget {
  const _EraPillBadge({required this.era});

  final String era;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: InkSpacing.sm,
        vertical: InkSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: InkColors.accentGold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: InkColors.accentGold.withValues(alpha: 0.45),
        ),
      ),
      child: Text(
        era,
        style: InkTypography.caption2.copyWith(
          color: InkColors.accentGold,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
