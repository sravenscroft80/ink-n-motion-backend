import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ink_n_motion/data/tattoo_advisor_questions.dart';
import 'package:ink_n_motion/models/chat_message.dart';
import 'package:ink_n_motion/models/tattoo_discovery_summary.dart';
import 'package:ink_n_motion/state/providers.dart';
import 'package:ink_n_motion/utils/design_tokens.dart';
import 'package:ink_n_motion/widgets/capture/studio_controls.dart';
import 'package:ink_n_motion/widgets/discover/magazine_detail_scaffold.dart';

/// AI Coach — guided 20-question tattoo discovery session.
class AiCoachScreen extends ConsumerStatefulWidget {
  const AiCoachScreen({super.key});

  static const String heroImageAsset = 'assets/images/ai_coach.png';

  static const String introMessage =
      '20 questions to uncover your perfect tattoo design, followed by a '
      'personalized summary and an AI-generated visual concept.';

  @override
  ConsumerState<AiCoachScreen> createState() => _AiCoachScreenState();
}

class _AiCoachScreenState extends ConsumerState<AiCoachScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _submitAnswer() {
    ref.read(aiCoachProvider.notifier).submitAnswer(_inputController.text);
    _inputController.clear();
    _scrollToBottom();
  }

  void _viewAiDesignConcept() {
    final coach = ref.read(aiCoachProvider);
    StudioConceptDialog.show(
      context,
      summary: coach.discoverySummary,
      imageUrl: coach.generatedImageUrl,
      isGeneratingImage: coach.isGeneratingMockup,
      showGenerateVideoBeta: false,
      disclaimer: kStudioEntertainmentDisclaimer,
    );
  }

  Future<void> _saveToDevice() async {
    await ref.read(aiCoachProvider.notifier).saveSummary();
    if (!mounted) return;
    final feedback = ref.read(aiCoachProvider).feedbackMessage;
    if (feedback == null) return;
    await showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Saved'),
        content: Text(feedback),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _openShareSheet() {
    BlueprintShareSheet.show(
      context,
      onShare: () => ref.read(aiCoachProvider.notifier).shareBlueprint(),
    );
  }

  Future<void> _confirmResetSession() async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Start over?'),
        content: const Text(
          'Your answers, blueprint, and generated concept will be cleared.',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      ref.read(aiCoachProvider.notifier).resetSession();
      _inputController.clear();
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final coachState = ref.watch(aiCoachProvider);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    ref.listen(aiCoachProvider, (previous, next) => _scrollToBottom());

    final listItemCount = 1 +
        coachState.messages.length +
        (coachState.isThinking ? 1 : 0) +
        (coachState.isGeneratingMockup ? 1 : 0) +
        (coachState.sessionComplete ? 1 : 0);

    return MagazineDetailScaffold(
      heroImageAsset: AiCoachScreen.heroImageAsset,
      heroHeightFactor: 0.30,
      eyebrow: 'AI Coach',
      title: 'Tattoo Discovery',
      subtitle: '20 questions · personalized blueprint',
      navTitle: 'AI Coach',
      interactiveBody: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (coachState.feedbackMessage != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  InkSpacing.md,
                  InkSpacing.sm,
                  InkSpacing.md,
                  0,
                ),
                child: Text(
                  coachState.feedbackMessage!,
                  style: InkTypography.caption1.copyWith(
                    color: InkColors.accentGoldMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(
                  InkSpacing.md,
                  InkSpacing.md,
                  InkSpacing.md,
                  InkSpacing.sm,
                ),
                itemCount: listItemCount,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return const _CoachIntroMessage();
                  }

                  final messageIndex = index - 1;
                  if (messageIndex < coachState.messages.length) {
                    return _ChatBubble(
                      message: coachState.messages[messageIndex],
                    );
                  }

                  var offset = coachState.messages.length;
                  if (coachState.isThinking) {
                    if (messageIndex == offset) {
                      return const _ThinkingIndicator();
                    }
                    offset += 1;
                  }

                  if (coachState.isGeneratingMockup) {
                    if (messageIndex == offset) {
                      return const _GeneratingMockupIndicator();
                    }
                    offset += 1;
                  }

                  if (coachState.sessionComplete && messageIndex == offset) {
                    return TattooBlueprintCard(
                      summary: coachState.discoverySummary,
                      imageUrl: coachState.generatedImageUrl,
                      isGeneratingImage: coachState.isGeneratingMockup,
                      onViewConcept: _viewAiDesignConcept,
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
      bottomBar: coachState.sessionComplete
          ? StudioSessionResultsBar(
              bottomInset: bottomInset,
              onSaveToDevice: _saveToDevice,
              onShare: _openShareSheet,
              onStartOver: _confirmResetSession,
            )
          : _ChatInputBar(
              controller: _inputController,
              bottomInset: bottomInset,
              enabled: !coachState.isThinking,
              questionNumber: coachState.currentIndex + 1,
              totalQuestions: TattooAdvisorQuestions.prompts.length,
              onSubmit: _submitAnswer,
            ),
    );
  }
}

class _CoachIntroMessage extends StatelessWidget {
  const _CoachIntroMessage();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: InkSpacing.md),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: InkColors.backgroundElevated,
          borderRadius: BorderRadius.circular(InkRadius.lg),
          border: Border.all(
            color: InkColors.accentGold.withValues(alpha: 0.22),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(InkSpacing.md),
          child: Text(
            AiCoachScreen.introMessage,
            style: MagazineDetailScaffold.bodyStyle.copyWith(
              fontSize: 16,
              height: 1.55,
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultsConceptPreview extends StatelessWidget {
  const _ResultsConceptPreview({
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
        aspectRatio: 16 / 10,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: InkColors.backgroundPrimary,
            border: Border.all(
              color: InkColors.accentGold.withValues(alpha: 0.3),
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
            CupertinoActivityIndicator(radius: 12),
            SizedBox(height: InkSpacing.sm),
            Text('Generating 2D concept…'),
          ],
        ),
      );
    }

    final url = imageUrl?.trim();
    if (url != null && url.isNotEmpty) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            url,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
            errorBuilder: (context, error, stackTrace) => const Center(
              child: Text('Preview unavailable'),
            ),
          ),
          Positioned(
            right: InkSpacing.sm,
            bottom: InkSpacing.sm,
            child: Icon(
              CupertinoIcons.eye_fill,
              color: InkColors.accentGold,
              size: 18,
            ),
          ),
        ],
      );
    }

    return const Center(
      child: Text(
        'Tap to view when your concept is ready',
        textAlign: TextAlign.center,
      ),
    );
  }
}

class TattooBlueprintCard extends StatelessWidget {
  const TattooBlueprintCard({
    super.key,
    required this.summary,
    this.imageUrl,
    this.isGeneratingImage = false,
    this.onViewConcept,
  });

  final TattooDiscoverySummary summary;
  final String? imageUrl;
  final bool isGeneratingImage;
  final VoidCallback? onViewConcept;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: InkSpacing.sm, bottom: InkSpacing.md),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(InkRadius.lg),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              InkColors.accentGold.withValues(alpha: 0.22),
              InkColors.backgroundElevated,
              InkColors.backgroundElevated,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: InkColors.accentGold.withValues(alpha: 0.12),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: CupertinoColors.black.withValues(alpha: 0.28),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: InkColors.backgroundElevated.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(InkRadius.lg),
            border: Border.all(
              color: InkColors.accentGold.withValues(alpha: 0.45),
              width: 1.2,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(InkSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      CupertinoIcons.doc_text_fill,
                      color: InkColors.accentGold,
                      size: 20,
                    ),
                    const SizedBox(width: InkSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Premium Blueprint',
                            style: InkTypography.headline.copyWith(
                              color: InkColors.accentGold,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.35,
                            ),
                          ),
                          Text(
                            'Ink-N-Motion · AI Coach',
                            style: InkTypography.caption2.copyWith(
                              color: InkColors.textTertiary,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: InkSpacing.sm,
                        vertical: InkSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: InkColors.accentGold.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(InkRadius.sm),
                        border: Border.all(
                          color: InkColors.accentGold.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Text(
                        'READY',
                        style: InkTypography.caption2.copyWith(
                          color: InkColors.accentGold,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: InkSpacing.md),
                GestureDetector(
                  onTap: onViewConcept,
                  child: _ResultsConceptPreview(
                    imageUrl: imageUrl,
                    isGenerating: isGeneratingImage,
                  ),
                ),
                const SizedBox(height: InkSpacing.lg),
                _BlueprintRow(label: 'Style', value: summary.style),
                _BlueprintRow(label: 'Size', value: summary.size),
                _BlueprintRow(label: 'Placement', value: summary.location),
                _BlueprintRow(label: 'Vision', value: summary.reasoning),
                _BlueprintRow(
                  label: 'Session Plan',
                  value: summary.estimatedTime,
                ),
                const SizedBox(height: InkSpacing.md),
                Text(
                  kStudioEntertainmentDisclaimer,
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
      ),
    );
  }
}

class _BlueprintRow extends StatelessWidget {
  const _BlueprintRow({required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: InkSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: InkTypography.caption2.copyWith(
              color: InkColors.accentGoldMuted,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: InkSpacing.xs),
          Text(
            value?.trim().isNotEmpty == true ? value! : '—',
            style: InkTypography.subhead.copyWith(
              color: InkColors.textPrimary.withValues(alpha: 0.9),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == ChatMessageRole.user;
    final maxWidth = MediaQuery.sizeOf(context).width * 0.78;

    return Padding(
      padding: const EdgeInsets.only(bottom: InkSpacing.sm),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: isUser
                  ? InkColors.accentGold.withValues(alpha: 0.92)
                  : InkColors.backgroundElevated.withValues(alpha: 0.95),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(InkRadius.lg),
                topRight: const Radius.circular(InkRadius.lg),
                bottomLeft:
                    Radius.circular(isUser ? InkRadius.lg : InkRadius.sm),
                bottomRight:
                    Radius.circular(isUser ? InkRadius.sm : InkRadius.lg),
              ),
              border: isUser
                  ? null
                  : Border.all(
                      color: InkColors.textPrimary.withValues(alpha: 0.08),
                    ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: InkSpacing.md,
                vertical: InkSpacing.sm + 2,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.text.isNotEmpty)
                    Text(
                      message.text,
                      style: InkTypography.subhead.copyWith(
                        color: isUser
                            ? CupertinoColors.black.withValues(alpha: 0.88)
                            : InkColors.textPrimary.withValues(alpha: 0.92),
                        height: 1.35,
                      ),
                    ),
                  if (message.isGeneratedImage) ...[
                    if (message.text.isNotEmpty)
                      const SizedBox(height: InkSpacing.sm),
                    _GeneratedDesignImage(imageUrl: message.imageUrl!),
                  ] else if (message.hasImage) ...[
                    if (message.text.isNotEmpty)
                      const SizedBox(height: InkSpacing.sm),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(InkRadius.md),
                      child: Image.network(
                        message.imageUrl!,
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ThinkingIndicator extends StatelessWidget {
  const _ThinkingIndicator();

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.sizeOf(context).width * 0.78;

    return Padding(
      padding: const EdgeInsets.only(bottom: InkSpacing.sm),
      child: Align(
        alignment: Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: InkColors.backgroundElevated.withValues(alpha: 0.95),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(InkRadius.lg),
                topRight: Radius.circular(InkRadius.lg),
                bottomRight: Radius.circular(InkRadius.lg),
                bottomLeft: Radius.circular(InkRadius.sm),
              ),
              border: Border.all(
                color: InkColors.textPrimary.withValues(alpha: 0.08),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: InkSpacing.md,
                vertical: InkSpacing.sm + 2,
              ),
              child: Text(
                'AI Coach is thinking…',
                style: InkTypography.subhead.copyWith(
                  color: InkColors.textSecondary,
                  fontStyle: FontStyle.italic,
                  height: 1.35,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GeneratingMockupIndicator extends StatelessWidget {
  const _GeneratingMockupIndicator();

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.sizeOf(context).width * 0.78;

    return Padding(
      padding: const EdgeInsets.only(bottom: InkSpacing.sm),
      child: Align(
        alignment: Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: InkColors.backgroundElevated.withValues(alpha: 0.95),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(InkRadius.lg),
                topRight: Radius.circular(InkRadius.lg),
                bottomRight: Radius.circular(InkRadius.lg),
                bottomLeft: Radius.circular(InkRadius.sm),
              ),
              border: Border.all(
                color: InkColors.textPrimary.withValues(alpha: 0.08),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: InkSpacing.md,
                vertical: InkSpacing.sm + 2,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CupertinoActivityIndicator(radius: 9),
                  const SizedBox(width: InkSpacing.sm),
                  Text(
                    'Generating visual concept…',
                    style: InkTypography.subhead.copyWith(
                      color: InkColors.textSecondary,
                      fontStyle: FontStyle.italic,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GeneratedDesignImage extends StatelessWidget {
  const _GeneratedDesignImage({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(InkRadius.md),
      child: Image.network(
        imageUrl,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return SizedBox(
            height: 220,
            width: double.infinity,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: InkColors.backgroundPrimary.withValues(alpha: 0.6),
              ),
              child: const Center(child: CupertinoActivityIndicator()),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return SizedBox(
            height: 140,
            width: double.infinity,
            child: Center(
              child: Text(
                'Unable to load generated design.',
                style: InkTypography.caption1.copyWith(
                  color: InkColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ChatInputBar extends StatelessWidget {
  const _ChatInputBar({
    required this.controller,
    required this.bottomInset,
    required this.enabled,
    required this.questionNumber,
    required this.totalQuestions,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final double bottomInset;
  final bool enabled;
  final int questionNumber;
  final int totalQuestions;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        InkSpacing.md,
        InkSpacing.sm,
        InkSpacing.md,
        InkSpacing.sm + bottomInset,
      ),
      decoration: BoxDecoration(
        color: InkColors.backgroundSecondary.withValues(alpha: 0.96),
        border: Border(
          top: BorderSide(
            color: InkColors.textPrimary.withValues(alpha: 0.08),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Question $questionNumber of $totalQuestions',
            style: InkTypography.caption2.copyWith(
              color: InkColors.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: InkSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: CupertinoTextField(
                  controller: controller,
                  enabled: enabled,
                  placeholder:
                      enabled ? 'Type your answer…' : 'AI Coach is thinking…',
                  placeholderStyle: InkTypography.subhead.copyWith(
                    color: InkColors.textTertiary,
                  ),
                  style: InkTypography.subhead.copyWith(
                    color: InkColors.textPrimary,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: InkSpacing.md,
                    vertical: InkSpacing.sm + 2,
                  ),
                  decoration: BoxDecoration(
                    color: InkColors.backgroundPrimary,
                    borderRadius: BorderRadius.circular(InkRadius.lg),
                    border: Border.all(
                      color: InkColors.textPrimary.withValues(alpha: 0.1),
                    ),
                  ),
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: enabled ? (_) => onSubmit() : null,
                ),
              ),
              const SizedBox(width: InkSpacing.sm),
              CupertinoButton(
                padding: const EdgeInsets.all(InkSpacing.sm),
                minimumSize: Size.zero,
                color: enabled
                    ? InkColors.accentGold
                    : InkColors.accentGold.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(InkRadius.lg),
                onPressed: enabled ? onSubmit : null,
                child: Icon(
                  CupertinoIcons.arrow_up,
                  color: CupertinoColors.black.withValues(alpha: 0.85),
                  size: 20,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

