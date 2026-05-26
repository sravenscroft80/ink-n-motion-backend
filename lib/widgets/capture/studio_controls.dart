import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show AnimationController, Curves, Material;
import 'package:ink_n_motion/models/tattoo_discovery_summary.dart';
import 'package:ink_n_motion/utils/design_tokens.dart';
import 'package:ink_n_motion/widgets/mockup_preview_image.dart';

/// Entertainment disclaimer for AI Coach concept surfaces.
const String kStudioEntertainmentDisclaimer =
    'For Entertainment Purposes Only. AI-generated concepts are illustrative '
    'and not medical, legal, or professional tattoo advice. Consult a licensed '
    'artist before booking.';

/// Bottom action strip for the Studio shell — concept dialog + save/share row.
class StudioControls extends StatelessWidget {
  const StudioControls({
    super.key,
    required this.bottomInset,
    required this.discoverySummary,
    required this.isRenderingMotion,
    required this.generateEnabled,
    required this.onGenerateDesignConcept,
    required this.onSave,
    required this.onShare,
  });

  final double bottomInset;
  final TattooDiscoverySummary? discoverySummary;
  final bool isRenderingMotion;
  final bool generateEnabled;
  final VoidCallback onGenerateDesignConcept;
  final VoidCallback onSave;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final conceptEnabled = generateEnabled && !isRenderingMotion;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        InkSpacing.md,
        InkSpacing.sm,
        InkSpacing.md,
        InkSpacing.md + bottomInset,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _GoldCtaButton(
            label: conceptEnabled ? 'Animate My Ink' : 'Select a style to animate',
            icon: CupertinoIcons.sparkles,
            enabled: conceptEnabled,
            onPressed: onGenerateDesignConcept,
          ),
          const SizedBox(height: InkSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _SecondaryActionButton(
                  label: 'Save',
                  filled: false,
                  onPressed: onSave,
                ),
              ),
              const SizedBox(width: InkSpacing.sm),
              Expanded(
                child: _SecondaryActionButton(
                  label: 'Share',
                  filled: false,
                  onPressed: onShare,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// AI Coach results footer — disclaimer + Save to Device / Share row.
class StudioSessionResultsBar extends StatelessWidget {
  const StudioSessionResultsBar({
    super.key,
    required this.bottomInset,
    required this.onSaveToDevice,
    required this.onShare,
    this.onStartOver,
  });

  final double bottomInset;
  final VoidCallback onSaveToDevice;
  final VoidCallback onShare;
  final VoidCallback? onStartOver;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        InkSpacing.md,
        InkSpacing.sm,
        InkSpacing.md,
        InkSpacing.md + bottomInset,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            kStudioEntertainmentDisclaimer,
            style: InkTypography.caption1.copyWith(
              color: InkColors.accentGoldMuted,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: InkSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _SecondaryActionButton(
                  label: 'Save to Device',
                  filled: false,
                  onPressed: onSaveToDevice,
                ),
              ),
              const SizedBox(width: InkSpacing.sm),
              Expanded(
                child: _SecondaryActionButton(
                  label: 'Share',
                  filled: true,
                  onPressed: onShare,
                ),
              ),
            ],
          ),
          if (onStartOver != null) ...[
            const SizedBox(height: InkSpacing.xs),
            CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: InkSpacing.xs),
              onPressed: onStartOver,
              child: Text(
                'Start Over',
                style: InkTypography.caption1.copyWith(
                  color: InkColors.textTertiary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Premium share modal — social icons trigger [share_plus] with art + blueprint.
class BlueprintShareSheet extends StatelessWidget {
  const BlueprintShareSheet({super.key, required this.onShare});

  final Future<void> Function() onShare;

  static const _platforms = [
    _SharePlatform(
      id: 'facebook',
      label: 'Facebook',
      icon: CupertinoIcons.person_2_fill,
      accent: Color(0xFF1877F2),
    ),
    _SharePlatform(
      id: 'instagram',
      label: 'Instagram',
      icon: CupertinoIcons.camera_fill,
      accent: Color(0xFFE1306C),
    ),
    _SharePlatform(
      id: 'tiktok',
      label: 'TikTok',
      icon: CupertinoIcons.music_note_2,
      accent: Color(0xFF00F2EA),
    ),
    _SharePlatform(
      id: 'x',
      label: 'X',
      icon: CupertinoIcons.at,
      accent: Color(0xFFF5F5F7),
    ),
  ];

  static Future<void> show(
    BuildContext context, {
    required Future<void> Function() onShare,
  }) {
    return showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => BlueprintShareSheet(
        onShare: () async {
          Navigator.of(ctx).pop();
          await onShare();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(
        InkSpacing.lg,
        InkSpacing.lg,
        InkSpacing.lg,
        InkSpacing.lg + bottom,
      ),
      decoration: BoxDecoration(
        color: InkColors.backgroundElevated,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(InkRadius.xl),
        ),
        border: Border(
          top: BorderSide(
            color: InkColors.accentGold.withValues(alpha: 0.35),
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: InkColors.textTertiary.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: InkSpacing.md),
          Text(
            'Share Your Concept',
            style: InkTypography.headline.copyWith(
              color: InkColors.accentGold,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: InkSpacing.xs),
          Text(
            'Includes your 2D design and blueprint text',
            style: InkTypography.caption1.copyWith(
              color: InkColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: InkSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _platforms
                .map(
                  (p) => _SharePlatformButton(platform: p, onTap: onShare),
                )
                .toList(),
          ),
          const SizedBox(height: InkSpacing.md),
          CupertinoButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: InkTypography.subhead.copyWith(
                color: InkColors.textTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SharePlatform {
  const _SharePlatform({
    required this.id,
    required this.label,
    required this.icon,
    required this.accent,
  });

  final String id;
  final String label;
  final IconData icon;
  final Color accent;
}

class _SharePlatformButton extends StatelessWidget {
  const _SharePlatformButton({
    required this.platform,
    required this.onTap,
  });

  final _SharePlatform platform;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () => onTap(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  platform.accent.withValues(alpha: 0.9),
                  platform.accent.withValues(alpha: 0.55),
                ],
              ),
              border: Border.all(
                color: InkColors.accentGold.withValues(alpha: 0.4),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: platform.accent.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              platform.icon,
              color: platform.id == 'x'
                  ? CupertinoColors.black
                  : CupertinoColors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: InkSpacing.sm),
          Text(
            platform.label,
            style: InkTypography.caption2.copyWith(
              color: InkColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// AI design concept — 2D art, blueprint, disclaimer; optional beta video CTA.
class StudioConceptDialog extends StatelessWidget {
  const StudioConceptDialog({
    super.key,
    required this.summary,
    this.imageUrl,
    this.isGeneratingImage = false,
    this.showGenerateVideoBeta = false,
    this.onGenerateVideoBeta,
    this.disclaimer = kStudioEntertainmentDisclaimer,
  });

  final TattooDiscoverySummary summary;
  final String? imageUrl;
  final bool isGeneratingImage;
  final bool showGenerateVideoBeta;
  final VoidCallback? onGenerateVideoBeta;
  final String disclaimer;

  static Future<void> show(
    BuildContext context, {
    required TattooDiscoverySummary? summary,
    String? imageUrl,
    bool isGeneratingImage = false,
    bool showGenerateVideoBeta = false,
    VoidCallback? onGenerateVideoBeta,
    String disclaimer = kStudioEntertainmentDisclaimer,
  }) {
    return showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => StudioConceptDialog(
        summary: summary ?? const TattooDiscoverySummary(),
        imageUrl: imageUrl,
        isGeneratingImage: isGeneratingImage,
        showGenerateVideoBeta: showGenerateVideoBeta,
        onGenerateVideoBeta: onGenerateVideoBeta == null
            ? null
            : () {
                Navigator.of(ctx).pop();
                onGenerateVideoBeta();
              },
        disclaimer: disclaimer,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.72;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: InkSpacing.lg),
        child: Material(
          color: CupertinoColors.transparent,
          child: Container(
            constraints: BoxConstraints(maxHeight: maxHeight),
            decoration: BoxDecoration(
              color: InkColors.backgroundElevated,
              borderRadius: BorderRadius.circular(InkRadius.lg),
              border: Border.all(
                color: InkColors.accentGold.withValues(alpha: 0.45),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: CupertinoColors.black.withValues(alpha: 0.45),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    InkSpacing.md,
                    InkSpacing.md,
                    InkSpacing.md,
                    InkSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        CupertinoIcons.sparkles,
                        color: InkColors.accentGold,
                        size: 20,
                      ),
                      const SizedBox(width: InkSpacing.sm),
                      Expanded(
                        child: Text(
                          'AI Design Concept',
                          style: InkTypography.headline.copyWith(
                            color: InkColors.accentGold,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        onPressed: () => Navigator.of(context).pop(),
                        child: Icon(
                          CupertinoIcons.xmark_circle_fill,
                          color: InkColors.textTertiary,
                          size: 26,
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      InkSpacing.md,
                      0,
                      InkSpacing.md,
                      InkSpacing.sm,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _ConceptArtPreview(
                          imageUrl: imageUrl,
                          isGenerating: isGeneratingImage,
                        ),
                        const SizedBox(height: InkSpacing.md),
                        Text(
                          summary.toPremiumBlueprintBody(),
                          style: InkTypography.subhead.copyWith(
                            color: InkColors.textPrimary.withValues(alpha: 0.9),
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: InkSpacing.md),
                        Text(
                          disclaimer,
                          style: InkTypography.caption1.copyWith(
                            color: InkColors.accentGoldMuted,
                            height: 1.4,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(InkSpacing.md),
                  child: Row(
                    children: [
                      Expanded(
                        child: CupertinoButton(
                          padding: const EdgeInsets.symmetric(
                            vertical: InkSpacing.sm,
                          ),
                          color: InkColors.backgroundSecondary,
                          borderRadius: BorderRadius.circular(InkRadius.lg),
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(
                            'Close',
                            style: InkTypography.headline.copyWith(
                              color: InkColors.textPrimary,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                      if (showGenerateVideoBeta &&
                          onGenerateVideoBeta != null) ...[
                        const SizedBox(width: InkSpacing.sm),
                        Expanded(
                          child: CupertinoButton(
                            padding: const EdgeInsets.symmetric(
                              vertical: InkSpacing.sm,
                            ),
                            color: InkColors.accentGold,
                            borderRadius: BorderRadius.circular(InkRadius.lg),
                            onPressed: onGenerateVideoBeta,
                            child: Text(
                              'Generate Video (Beta)',
                              style: InkTypography.headline.copyWith(
                                color: CupertinoColors.black.withValues(
                                  alpha: 0.88,
                                ),
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ConceptArtPreview extends StatelessWidget {
  const _ConceptArtPreview({
    required this.imageUrl,
    required this.isGenerating,
  });

  final String? imageUrl;
  final bool isGenerating;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(InkRadius.md),
      child: AspectRatio(
        aspectRatio: 1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: InkColors.backgroundPrimary,
            border: Border.all(
              color: InkColors.accentGold.withValues(alpha: 0.25),
            ),
          ),
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (isGenerating) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoActivityIndicator(radius: 14),
            SizedBox(height: InkSpacing.sm),
            Text(
              'Creating your 2D concept…',
              style: TextStyle(color: InkColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      );
    }

    final url = imageUrl?.trim();
    if (url != null && url.isNotEmpty) {
      return MockupPreviewImage(
        imageUrl: url,
        fit: BoxFit.cover,
        errorMessage: 'Unable to load design preview.',
      );
    }

    return _placeholder('Design preview will appear when generation completes.');
  }

  Widget _placeholder(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(InkSpacing.md),
        child: Text(
          message,
          style: InkTypography.caption1.copyWith(
            color: InkColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _GoldCtaButton extends StatefulWidget {
  const _GoldCtaButton({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  State<_GoldCtaButton> createState() => _GoldCtaButtonState();
}

class _GoldCtaButtonState extends State<_GoldCtaButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glowController;
  late final Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _glowAnimation = Tween<double>(begin: 0.2, end: 0.7).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    _syncGlowAnimation();
  }

  @override
  void didUpdateWidget(covariant _GoldCtaButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled != widget.enabled) {
      _syncGlowAnimation();
    }
  }

  void _syncGlowAnimation() {
    if (widget.enabled) {
      if (!_glowController.isAnimating) {
        _glowController.repeat(reverse: true);
      }
    } else {
      _glowController
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled;

    return InkTactileButton(
      onPressed: enabled ? widget.onPressed : null,
      child: AnimatedBuilder(
        animation: _glowAnimation,
        builder: (context, child) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: InkSpacing.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              color: enabled ? null : const Color(0xFF2A2A32),
              gradient: enabled ? InkColors.goldCtaGradient : null,
              boxShadow: enabled
                  ? [
                      BoxShadow(
                        color: InkColors.accentGoldBright
                            .withValues(alpha: _glowAnimation.value),
                        blurRadius: 22,
                        spreadRadius: 1.5,
                      ),
                      BoxShadow(
                        color: InkColors.accentGold
                            .withValues(alpha: _glowAnimation.value * 0.45),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.icon,
                  color: enabled
                      ? CupertinoColors.black.withValues(alpha: 0.85)
                      : InkColors.textSecondaryMuted,
                  size: 18,
                ),
                const SizedBox(width: InkSpacing.sm),
                Text(
                  widget.label,
                  style: InkTypography.headline.copyWith(
                    color: enabled
                        ? CupertinoColors.black.withValues(alpha: 0.88)
                        : InkColors.textSecondaryMuted,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.35,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SecondaryActionButton extends StatelessWidget {
  const _SecondaryActionButton({
    required this.label,
    required this.filled,
    required this.onPressed,
  });

  final String label;
  final bool filled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkTactileButton(
      onPressed: onPressed,
      padding: const EdgeInsets.symmetric(vertical: InkSpacing.sm),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: InkSpacing.sm),
        decoration: BoxDecoration(
          color: filled ? InkColors.accentGoldBright : InkColors.backgroundElevated,
          borderRadius: BorderRadius.circular(InkRadius.lg),
          border: filled
              ? null
              : Border.all(
                  color: InkColors.textTertiary.withValues(alpha: 0.35),
                ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: InkTypography.headline.copyWith(
            color: filled
                ? CupertinoColors.black.withValues(alpha: 0.88)
                : InkColors.textPrimary,
            fontSize: filled ? 16 : 15,
            fontWeight: filled ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
