import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ink_n_motion/data/style_template_catalog.dart';
import 'package:ink_n_motion/models/video_generation_status.dart';
import 'package:ink_n_motion/screens/paywall_credit_purchase_screen.dart';
import 'package:ink_n_motion/screens/refund_flow_screen.dart';
import 'package:ink_n_motion/services/easy_video_service.dart';
import 'package:ink_n_motion/state/app_state.dart';
import 'package:ink_n_motion/state/providers.dart';
import 'package:ink_n_motion/utils/design_tokens.dart';
import 'package:ink_n_motion/utils/ink_haptics.dart';
import 'package:ink_n_motion/utils/navigation.dart';
import 'package:ink_n_motion/widgets/generation/animated_save_to_gallery_button.dart';
import 'package:ink_n_motion/widgets/generation/generation_success_reveal.dart';
import 'package:ink_n_motion/widgets/generation/local_overlay_sparkle_preview.dart';
import 'package:ink_n_motion/widgets/generation/network_recovery_assurance_card.dart';
import 'package:ink_n_motion/widgets/generation/queue_progress_stepper_card.dart';
import 'package:ink_n_motion/widgets/generation/offline_network_overlay_card.dart';
import 'package:ink_n_motion/widgets/generation/rate_limit_overlay_card.dart';
import 'package:ink_n_motion/widgets/ink_frosted_glass.dart';
import 'package:ink_n_motion/widgets/ink_neon_glow.dart';
import 'package:ink_n_motion/widgets/monetization/ink_share_unlock_modal.dart';

class EasyVideoPreviewScreen extends ConsumerStatefulWidget {
  const EasyVideoPreviewScreen({super.key});

  @override
  ConsumerState<EasyVideoPreviewScreen> createState() => _EasyVideoPreviewScreenState();
}

class _EasyVideoPreviewScreenState extends ConsumerState<EasyVideoPreviewScreen> {
  bool _processing = false;
  bool _autoStarted = false;
  bool _showNetworkRecovery = false;
  String? _saveFeedback;
  bool _shareUnlockShown = false;

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeAutoStartPipeline());
  }

  Future<void> _maybeAutoStartPipeline() async {
    if (_autoStarted || !mounted) return;

    final appState = ref.read(appStateProvider);
    final template = StyleTemplateCatalog.findById(appState.selectedStyleTemplateId);
    if (template == null || !template.isEasy) return;
    if (appState.videoGenerationStatus != VideoGenerationStatus.idle) return;

    _autoStarted = true;
    await _runEasyPipeline();
  }

  Future<void> _runEasyPipeline() async {
    setState(() {
      _processing = true;
      _saveFeedback = null;
    });
    await ref.read(easyVideoServiceProvider).processEasyVideo();
    if (mounted) setState(() => _processing = false);
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
      (previous, next) {
        if (next == VideoGenerationStatus.success &&
            previous != VideoGenerationStatus.success) {
          InkHaptics.generationSuccess();
          unawaited(_maybeShowShareUnlock());
        }
        if (next == VideoGenerationStatus.failed &&
            previous == VideoGenerationStatus.generating) {
          setState(() => _showNetworkRecovery = true);
        }
      },
    );

    final appState = ref.watch(appStateProvider);
    final status = appState.videoGenerationStatus;
    final isGenerating = !appState.isDeviceOfflineMode &&
        (status == VideoGenerationStatus.generating || _processing);
    final isSuccess = status == VideoGenerationStatus.success;
    final styleName = StyleTemplateCatalog.findById(appState.selectedStyleTemplateId)?.name;
    final showSparkleOverlay = isSuccess &&
        appState.isLocalOverlay &&
        appState.sparkleMaskUrl != null &&
        appState.selectedImagePath != null;
    final hasOutput = isSuccess &&
        (appState.dynamicOutputVideoPath != null ||
            (appState.isLocalOverlay && appState.sparkleMaskUrl != null));

    return CupertinoPageScaffold(
      backgroundColor: InkColors.backgroundPrimary,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: InkColors.backgroundSecondary.withValues(alpha: 0.9),
        border: null,
        middle: const Text('Easy Video'),
        leading: CupertinoNavigationBarBackButton(
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(InkSpacing.md),
                child: InkNeonGlow(
                  color: InkColors.accentNeonCyan,
                  child: InkFrostedGlass(
                    borderRadius: InkRadius.lg,
                    padding: const EdgeInsets.all(InkSpacing.lg),
                    child: Center(
                      child: isGenerating
                          ? QueueProgressStepperCard(
                              currentQueueStep: appState.currentQueueStep,
                              accentColor: InkColors.accentNeonCyan,
                            )
                          : showSparkleOverlay
                              ? LocalOverlaySparklePreview(
                                  imagePath: appState.selectedImagePath!,
                                  maskUrl: appState.sparkleMaskUrl!,
                                )
                              : GenerationSuccessReveal(
                              visible: isSuccess,
                              outputHasWatermark: appState.outputHasWatermark,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    CupertinoIcons.play_rectangle_fill,
                                    size: 64,
                                    color: isSuccess
                                        ? InkColors.accentSuccess
                                        : InkColors.accentNeonCyan,
                                  ),
                                  const SizedBox(height: InkSpacing.md),
                                  Text(
                                    isSuccess
                                        ? 'Preview ready'
                                        : 'Easy video preview',
                                    style: InkTypography.headline,
                                    textAlign: TextAlign.center,
                                  ),
                                  if (styleName != null) ...[
                                    const SizedBox(height: InkSpacing.xs),
                                    Text(styleName, style: InkTypography.footnote),
                                  ],
                                  if (hasOutput) ...[
                                    const SizedBox(height: InkSpacing.sm),
                                    Text(
                                      appState.dynamicOutputVideoPath!,
                                      style: InkTypography.caption2,
                                      textAlign: TextAlign.center,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                  const SizedBox(height: InkSpacing.sm),
                                  Text(_statusLabel(status), style: InkTypography.footnote),
                                ],
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(InkSpacing.lg),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton.filled(
                      onPressed: isGenerating ? null : _runEasyPipeline,
                      child: Text(isSuccess ? 'Regenerate Easy Video' : 'Generate Easy Video'),
                    ),
                  ),
                  const SizedBox(height: InkSpacing.sm),
                  AnimatedSaveToGalleryButton(
                    visible: hasOutput,
                    onPressed: _saveToGallery,
                    feedback: _saveFeedback,
                  ),
                  CupertinoButton(
                    onPressed: () => pushCupertino(context, const RefundFlowScreen()),
                    child: const Text('Report bad output'),
                  ),
                ],
              ),
            ),
          ],
            ),
            if (_showNetworkRecovery)
              NetworkRecoveryAssuranceCard(
                onDismiss: () {
                  setState(() => _showNetworkRecovery = false);
                  ref.read(appStateProvider.notifier).resetEasyGenerationStatus();
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
                  _runEasyPipeline();
                },
              ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(VideoGenerationStatus status) {
    switch (status) {
      case VideoGenerationStatus.idle:
        return 'Status: idle · cloud render ready';
      case VideoGenerationStatus.generating:
        return 'Status: generating';
      case VideoGenerationStatus.success:
        return 'Status: success';
      case VideoGenerationStatus.failed:
        return 'Status: failed';
    }
  }
}
