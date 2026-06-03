import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show ScaffoldMessenger, SnackBar;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ink_n_motion/data/style_template_catalog.dart';
import 'package:ink_n_motion/models/transaction_results.dart';
import 'package:ink_n_motion/models/video_generation_status.dart';
import 'package:ink_n_motion/screens/paywall_credit_purchase_screen.dart';
import 'package:ink_n_motion/screens/refund_flow_screen.dart';
import 'package:ink_n_motion/services/api_service.dart';
import 'package:ink_n_motion/state/app_state.dart';
import 'package:ink_n_motion/state/providers.dart';
import 'package:ink_n_motion/utils/exceptions.dart';
import 'package:ink_n_motion/utils/design_tokens.dart';
import 'package:ink_n_motion/utils/ink_haptics.dart';
import 'package:ink_n_motion/utils/navigation.dart';
import 'package:ink_n_motion/widgets/generation/animated_save_to_gallery_button.dart';
import 'package:ink_n_motion/widgets/generation/generation_success_reveal.dart';
import 'package:ink_n_motion/widgets/generation/local_overlay_sparkle_preview.dart';
import 'package:ink_n_motion/widgets/generation/monthly_limit_overlay_card.dart';
import 'package:ink_n_motion/widgets/generation/network_recovery_assurance_card.dart';
import 'package:ink_n_motion/widgets/generation/queue_progress_stepper_card.dart';
import 'package:ink_n_motion/widgets/generation/offline_network_overlay_card.dart';
import 'package:ink_n_motion/widgets/generation/rate_limit_overlay_card.dart';
import 'package:ink_n_motion/widgets/ink_frosted_glass.dart';
import 'package:ink_n_motion/widgets/ink_neon_glow.dart';
import 'package:ink_n_motion/widgets/monetization/ink_share_unlock_modal.dart';
import 'package:ink_n_motion/widgets/video/ink_network_video_player.dart';

class PremiumVideoGenerationScreen extends ConsumerStatefulWidget {
  const PremiumVideoGenerationScreen({super.key});

  @override
  ConsumerState<PremiumVideoGenerationScreen> createState() =>
      _PremiumVideoGenerationScreenState();
}

class _PremiumVideoGenerationScreenState
    extends ConsumerState<PremiumVideoGenerationScreen> {
  bool _busy = false;
  bool _showNetworkRecovery = false;
  String? _saveFeedback;
  String? _statusText;
  bool _shareUnlockShown = false;
  int _durationSeconds = 5;

  void _selectDuration(int seconds) {
    final isPremium = ref.read(appStateProvider).isPremiumSubscriber;
    if (seconds == 10 && !isPremium) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '10-second renders are available on Ink Plus — upgrade to unlock.',
          ),
        ),
      );
      return;
    }
    setState(() => _durationSeconds = seconds);
  }

  Future<void> _maybeShowShareUnlock() async {
    if (_shareUnlockShown || !mounted) return;
    final isPremium = ref.read(appStateProvider).isPremiumSubscriber;
    if (isPremium) return;

    _shareUnlockShown = true;
    await InkShareUnlockModal.show(
      context,
      onShareComplete: () async {
        final granted =
            await ref.read(appStateProvider.notifier).grantShareUnlockCredits();
        if (granted && mounted) {
          InkShareUnlockSnackbar.show(context);
        }
      },
    );
  }

  Future<void> _showError(String message) async {
    if (!mounted) return;
    await showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Premium generation'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _generate() async {
    final appState = ref.read(appStateProvider);
    final imageBytes = appState.selectedImageBytes;
    if (imageBytes == null || imageBytes.isEmpty) {
      await _showError(
        'No image selected. Please go back and upload a photo.',
      );
      return;
    }

    final styleId = appState.selectedStyleTemplateId;
    if (styleId == null || styleId.isEmpty) {
      await _showError('No style selected. Please go back and choose a style.');
      return;
    }

    final startResult = ref.read(appStateProvider.notifier).beginPremiumGeneration(
          durationSeconds: _durationSeconds,
        );
    if (startResult == PremiumGenerationStartResult.insufficientCredits ||
        startResult == PremiumGenerationStartResult.monthlyLimitReached) {
      return;
    }

    final refundCreditsOnFailure = !ref.read(appStateProvider).isPremiumSubscriber;

    setState(() {
      _busy = true;
      _saveFeedback = null;
      _statusText = 'submitting';
    });

    try {
      final notifier = ref.read(appStateProvider.notifier);
      final success = await notifier.processPremiumVideoGeneration(
        durationSeconds: _durationSeconds,
      );

      if (!mounted) return;

      if (!success) {
        return;
      }
    } on OfflineNetworkException {
      ref
          .read(appStateProvider.notifier)
          .handleGenerationOffline(refundUpfrontCredits: refundCreditsOnFailure);
      if (mounted) setState(() => _showNetworkRecovery = true);
    } on RateLimitException catch (error) {
      ref.read(appStateProvider.notifier).handleGenerationRateLimit(
            error,
            refundUpfrontCredits: refundCreditsOnFailure,
          );
    } catch (error, stackTrace) {
      logApiFailure('PremiumVideoGenerationScreen._generate', error, stackTrace);
      ref.read(appStateProvider.notifier).failPremiumGeneration(
            refundUpfrontCredits: refundCreditsOnFailure,
          );
      if (mounted) {
        setState(() => _showNetworkRecovery = true);
        await _showError('Premium generation failed. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _statusText = null;
        });
      }
    }
  }

  Future<void> _saveToGallery() async {
    if (kIsWeb) {
      setState(() {
        _saveFeedback = 'Right-click the video to save';
      });
      return;
    }

    setState(() => _saveFeedback = 'Saving...');
    final saved =
        await ref.read(appStateProvider.notifier).saveCurrentVideoToGallery();
    if (!mounted) return;
    setState(() {
      _saveFeedback = saved
          ? 'Saved to your gallery!'
          : 'Unable to save video. Please try again.';
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AppState>(appStateProvider, (previous, next) {
      if (next.navigateToPaywall && previous?.navigateToPaywall != true) {
        ref.read(appStateProvider.notifier).clearPaywallNavigationIntent();
        pushCupertino(context, const PaywallCreditPurchaseScreen());
      }
    });

    ref.listen<VideoGenerationStatus>(
      appStateProvider.select((state) => state.videoGenerationStatus),
      (prev, next) {
        if (next == VideoGenerationStatus.success &&
            prev != VideoGenerationStatus.success) {
          InkHaptics.generationSuccess();
          unawaited(_maybeShowShareUnlock());
        }
        if (next == VideoGenerationStatus.failed &&
            prev == VideoGenerationStatus.generating) {
          setState(() => _showNetworkRecovery = true);
        }
      },
    );

    final appState = ref.watch(appStateProvider);
    final status = appState.videoGenerationStatus;
    final isGenerating = !appState.isDeviceOfflineMode &&
        (status == VideoGenerationStatus.generating || _busy);
    final isSuccess = status == VideoGenerationStatus.success;
    final showSparkleOverlay = isSuccess &&
        appState.isLocalOverlay &&
        appState.sparkleMaskUrl != null &&
        appState.selectedImagePath != null;
    final hasOutput = isSuccess &&
        (appState.dynamicOutputVideoPath != null ||
            (appState.isLocalOverlay && appState.sparkleMaskUrl != null));
    final videoUrl = appState.dynamicOutputVideoPath;
    final showInlineVideo = isSuccess &&
        !showSparkleOverlay &&
        videoUrl != null &&
        inkIsNetworkVideoUrl(videoUrl);

    final styleName =
        StyleTemplateCatalog.findById(appState.selectedStyleTemplateId)?.name;

    return CupertinoPageScaffold(
      backgroundColor: InkColors.backgroundPrimary,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: InkColors.backgroundSecondary.withValues(alpha: 0.9),
        border: null,
        middle: const Text('Premium AI'),
        leading: CupertinoNavigationBarBackButton(
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            const CupertinoSliverNavigationBar(
              largeTitle: Text('Premium generation'),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(InkSpacing.md),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  InkFrostedGlass(
                    padding: const EdgeInsets.all(InkSpacing.md),
                    child: Text(
                      appState.isPremiumSubscriber
                          ? 'Ink Plus active · ${appState.premiumRendersRemaining} of ${AppState.premiumMonthlyRenderCap} premium renders left this cycle.'
                          : 'Costs ${AppState.kPremiumCreditCost} credits (5 sec) or ${AppState.kPremiumCreditCostTenSecond} credits (10 sec) upfront when generation starts.',
                      style: InkTypography.body,
                    ),
                  ),
                  if (styleName != null) ...[
                    const SizedBox(height: InkSpacing.sm),
                    Text('Style: $styleName', style: InkTypography.footnote),
                  ],
                  if (_statusText != null) ...[
                    const SizedBox(height: InkSpacing.sm),
                    Text(
                      'Status: $_statusText',
                      style: InkTypography.footnote.copyWith(
                        color: InkColors.accentNeonMagenta,
                      ),
                    ),
                  ],
                  if (appState.isAccountFlaggedForReview) ...[
                    const SizedBox(height: InkSpacing.sm),
                    Text(
                      'Account flagged for review (refund ratio ${(appState.refundRatio * 100).toStringAsFixed(0)}%).',
                      style: InkTypography.footnote.copyWith(
                        color: InkColors.accentWarning,
                      ),
                    ),
                  ],
                  const SizedBox(height: InkSpacing.lg),
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: InkNeonGlow(
                      color: InkColors.accentNeonMagenta,
                      child: Container(
                        decoration: BoxDecoration(
                          color: InkColors.backgroundSecondary,
                          borderRadius: BorderRadius.circular(InkRadius.lg),
                          border: Border.all(
                            color: InkColors.accentNeonMagenta.withValues(alpha: 0.5),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(InkRadius.lg),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              _SelectedImagePreview(
                                imageBytes: appState.selectedImageBytes,
                                imagePath: appState.selectedImagePath,
                              ),
                              if (showInlineVideo)
                                InkNetworkVideoPlayer(
                                  url: videoUrl,
                                  autoPlay: true,
                                )
                              else if (isGenerating)
                                ColoredBox(
                                  color: CupertinoColors.black.withValues(alpha: 0.45),
                                  child: Center(
                                    child: QueueProgressStepperCard(
                                      currentQueueStep: appState.currentQueueStep,
                                      accentColor: InkColors.accentNeonMagenta,
                                    ),
                                  ),
                                )
                              else if (showSparkleOverlay)
                                LocalOverlaySparklePreview(
                                  imagePath: appState.selectedImagePath!,
                                  maskUrl: appState.sparkleMaskUrl!,
                                )
                              else
                                GenerationSuccessReveal(
                                  visible: isSuccess,
                                  outputHasWatermark: appState.outputHasWatermark,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        CupertinoIcons.wand_stars_inverse,
                                        size: 56,
                                        color: isSuccess
                                            ? InkColors.accentSuccess
                                            : InkColors.accentNeonMagenta,
                                      ),
                                      if (hasOutput && !showInlineVideo) ...[
                                        const SizedBox(height: InkSpacing.md),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: InkSpacing.md,
                                          ),
                                          child: Text(
                                            appState.dynamicOutputVideoPath!,
                                            style: InkTypography.caption2,
                                            textAlign: TextAlign.center,
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis,
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
                  ),
                  const SizedBox(height: InkSpacing.lg),
                  _DurationToggle(
                    selectedSeconds: _durationSeconds,
                    isPremium: appState.isPremiumSubscriber,
                    onSelect: _selectDuration,
                  ),
                  const SizedBox(height: InkSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton.filled(
                      color: InkColors.accentNeonMagenta,
                      onPressed: isGenerating ? null : _generate,
                      child: Text(
                        isSuccess
                            ? 'Regenerate Premium Video'
                            : 'Start Premium Generation',
                      ),
                    ),
                  ),
                  const SizedBox(height: InkSpacing.sm),
                  AnimatedSaveToGalleryButton(
                    visible: hasOutput,
                    onPressed: _saveToGallery,
                    feedback: _saveFeedback,
                    filledColor: InkColors.accentNeonMagenta,
                  ),
                  CupertinoButton(
                    onPressed: () => pushCupertino(context, const RefundFlowScreen()),
                    child: const Text('Request refund'),
                  ),
                ]),
              ),
            ),
          ],
            ),
            if (appState.monthlyLimitMessage != null)
              MonthlyLimitOverlayCard(
                message: appState.monthlyLimitMessage!,
                onDismiss: () {
                  ref.read(appStateProvider.notifier).clearMonthlyLimitMessage();
                },
              ),
            if (_showNetworkRecovery)
              NetworkRecoveryAssuranceCard(
                showCreditRefund: !appState.isPremiumSubscriber,
                onDismiss: () {
                  setState(() => _showNetworkRecovery = false);
                  ref.read(appStateProvider.notifier).resetPremiumGenerationStatus();
                },
              ),
            if (appState.rateLimitBlockedMessage != null)
              RateLimitOverlayCard(
                message: appState.rateLimitBlockedMessage!,
                onDismiss: () {
                  ref.read(appStateProvider.notifier).clearRateLimitBlockedMessage();
                },
              ),
            if (appState.isDeviceOfflineMode)
              OfflineNetworkOverlayCard(
                onRetry: () {
                  ref.read(appStateProvider.notifier).clearDeviceOfflineMode();
                  _generate();
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _DurationToggle extends StatelessWidget {
  const _DurationToggle({
    required this.selectedSeconds,
    required this.isPremium,
    required this.onSelect,
  });

  final int selectedSeconds;
  final bool isPremium;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _DurationPill(
            label: '5 sec',
            selected: selectedSeconds == 5,
            onTap: () => onSelect(5),
          ),
        ),
        const SizedBox(width: InkSpacing.sm),
        Expanded(
          child: _DurationPill(
            label: '10 sec',
            selected: selectedSeconds == 10,
            locked: !isPremium,
            onTap: () => onSelect(10),
          ),
        ),
      ],
    );
  }
}

class _DurationPill extends StatelessWidget {
  const _DurationPill({
    required this.label,
    required this.selected,
    required this.onTap,
    this.locked = false,
  });

  static const Color _gold = Color(0xFFD4A017);

  final String label;
  final bool selected;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: InkSpacing.sm),
        decoration: BoxDecoration(
          color: selected
              ? _gold.withValues(alpha: 0.18)
              : InkColors.backgroundElevated,
          borderRadius: BorderRadius.circular(InkRadius.lg),
          border: Border.all(
            color: selected
                ? _gold
                : _gold.withValues(alpha: locked ? 0.25 : 0.45),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: InkTypography.subhead.copyWith(
            color: selected ? _gold : InkColors.textPrimary,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _SelectedImagePreview extends StatelessWidget {
  const _SelectedImagePreview({
    required this.imageBytes,
    required this.imagePath,
  });

  final Uint8List? imageBytes;
  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    if (imageBytes != null && imageBytes!.isNotEmpty) {
      return Image.memory(imageBytes!, fit: BoxFit.cover);
    }

    final path = imagePath?.trim();
    if (path != null && path.isNotEmpty) {
      if (path.startsWith('http') || path.startsWith('blob:')) {
        return Image.network(path, fit: BoxFit.cover);
      }
    }

    return ColoredBox(
      color: InkColors.backgroundSecondary,
      child: Center(
        child: Icon(
          CupertinoIcons.photo,
          size: 48,
          color: InkColors.textTertiary.withValues(alpha: 0.8),
        ),
      ),
    );
  }
}
