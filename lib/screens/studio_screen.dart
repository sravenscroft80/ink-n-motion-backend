import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ink_n_motion/models/studio_handoff.dart';
import 'package:ink_n_motion/models/tattoo_discovery_summary.dart';
import 'package:ink_n_motion/screens/capture_screen.dart';
import 'package:ink_n_motion/state/providers.dart';
import 'package:ink_n_motion/utils/design_tokens.dart';

/// Motion Studio tab — live capture with optional AI Coach handoff.
class StudioScreen extends ConsumerWidget {
  const StudioScreen({
    super.key,
    this.discoverySummary,
    this.generatedImageUrl,
  });

  /// When provided (e.g. route push), seeds [studioHandoffProvider].
  final TattooDiscoverySummary? discoverySummary;
  final String? generatedImageUrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final handoff = _resolveHandoff(ref);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (handoff != null && handoff.summary.hasAnyField)
          _StudioHandoffBanner(
            summary: handoff.summary,
            onDismiss: () {
              ref.read(studioHandoffProvider.notifier).state = null;
            },
          ),
        Expanded(
          child: CaptureScreen(
            embeddedInShell: true,
            discoverySummary: handoff?.summary,
            generatedConceptUrl: handoff?.generatedImageUrl,
          ),
        ),
      ],
    );
  }

  StudioHandoff? _resolveHandoff(WidgetRef ref) {
    if (discoverySummary != null) {
      return StudioHandoff(
        summary: discoverySummary!,
        generatedImageUrl: generatedImageUrl,
      );
    }
    return ref.watch(studioHandoffProvider);
  }
}

class _StudioHandoffBanner extends StatelessWidget {
  const _StudioHandoffBanner({
    required this.summary,
    required this.onDismiss,
  });

  final TattooDiscoverySummary summary;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final vision = summary.reasoning?.trim();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: InkColors.backgroundElevated,
        border: Border(
          bottom: BorderSide(
            color: InkColors.accentGold.withValues(alpha: 0.35),
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          InkSpacing.md,
          InkSpacing.sm,
          InkSpacing.xs,
          InkSpacing.sm,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              CupertinoIcons.sparkles,
              color: InkColors.accentGold,
              size: 18,
            ),
            const SizedBox(width: InkSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Concept loaded from AI Coach',
                    style: InkTypography.caption1.copyWith(
                      color: InkColors.accentGold,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (vision != null && vision.isNotEmpty) ...[
                    const SizedBox(height: InkSpacing.xs),
                    Text(
                      vision,
                      style: InkTypography.caption2.copyWith(
                        color: InkColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              onPressed: onDismiss,
              child: Icon(
                CupertinoIcons.xmark_circle_fill,
                color: InkColors.textTertiary,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
