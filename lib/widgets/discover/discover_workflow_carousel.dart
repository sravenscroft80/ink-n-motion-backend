import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:ink_n_motion/data/workflow_steps.dart';
import 'package:ink_n_motion/utils/design_tokens.dart';

/// Premium image carousel for the five-step Discover workflow.
class DiscoverWorkflowCarousel extends StatefulWidget {
  const DiscoverWorkflowCarousel({super.key});

  @override
  State<DiscoverWorkflowCarousel> createState() =>
      _DiscoverWorkflowCarouselState();
}

class _DiscoverWorkflowCarouselState extends State<DiscoverWorkflowCarousel> {
  static const _steps = DiscoverWorkflowSteps.steps;

  late final PageController _pageController;
  double _page = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.92);
    _pageController.addListener(_onPageChanged);
  }

  void _onPageChanged() {
    final current = _pageController.page;
    if (current == null || current == _page) return;
    setState(() => _page = current);
  }

  @override
  void dispose() {
    _pageController
      ..removeListener(_onPageChanged)
      ..dispose();
    super.dispose();
  }

  int get _activeIndex =>
      _page.round().clamp(0, _steps.length - 1);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final imageHeight = screenWidth * 0.56;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: imageHeight + InkSpacing.lg,
          child: PageView.builder(
            controller: _pageController,
            physics: const BouncingScrollPhysics(),
            itemCount: _steps.length,
            itemBuilder: (context, index) {
              return _WorkflowSlide(
                step: _steps[index],
                imageHeight: imageHeight,
                page: _page,
                index: index,
              );
            },
          ),
        ),
        const SizedBox(height: InkSpacing.md),
        _WorkflowPageIndicators(
          count: _steps.length,
          activeIndex: _activeIndex,
          onTap: (index) {
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 420),
              curve: Curves.easeOutCubic,
            );
          },
        ),
        const SizedBox(height: InkSpacing.lg),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 320),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.06),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: _WorkflowStepCaption(
            key: ValueKey(_activeIndex),
            step: _steps[_activeIndex],
          ),
        ),
      ],
    );
  }
}

class _WorkflowSlide extends StatelessWidget {
  const _WorkflowSlide({
    required this.step,
    required this.imageHeight,
    required this.page,
    required this.index,
  });

  final WorkflowStep step;
  final double imageHeight;
  final double page;
  final int index;

  @override
  Widget build(BuildContext context) {
    final delta = page - index;
    final parallaxOffset = delta * 28;
    final scale = (1 - delta.abs() * 0.06).clamp(0.88, 1.0);
    final fade = (1 - delta.abs() * 0.45).clamp(0.55, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: InkSpacing.xs),
      child: Transform.scale(
        scale: scale,
        child: Opacity(
          opacity: fade,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(InkRadius.lg),
            child: SizedBox(
              height: imageHeight,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Transform.translate(
                    offset: Offset(parallaxOffset, 0),
                    child: Image.asset(
                      step.assetPath,
                      fit: BoxFit.cover,
                      alignment: Alignment(
                        (-delta * 0.15).clamp(-0.35, 0.35),
                        0,
                      ),
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          CupertinoColors.black.withValues(alpha: 0.08),
                          CupertinoColors.black.withValues(alpha: 0.18),
                          CupertinoColors.black.withValues(alpha: 0.62),
                        ],
                        stops: const [0.0, 0.55, 1.0],
                      ),
                    ),
                  ),
                  Positioned(
                    left: InkSpacing.md,
                    bottom: InkSpacing.md,
                    child: _StepBadge(stepNumber: step.stepNumber),
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

class _StepBadge extends StatelessWidget {
  const _StepBadge({required this.stepNumber});

  final String stepNumber;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(InkRadius.sm),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: InkSpacing.sm + 2,
            vertical: InkSpacing.xs + 2,
          ),
          decoration: BoxDecoration(
            color: CupertinoColors.black.withValues(alpha: 0.35),
            border: Border.all(
              color: InkColors.accentGold.withValues(alpha: 0.35),
            ),
            borderRadius: BorderRadius.circular(InkRadius.sm),
          ),
          child: Text(
            stepNumber,
            style: InkTypography.caption1.copyWith(
              color: InkColors.accentGoldLight,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}

class _WorkflowStepCaption extends StatelessWidget {
  const _WorkflowStepCaption({super.key, required this.step});

  final WorkflowStep step;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          step.title,
          style: InkTypography.headline.copyWith(
            color: InkColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: InkSpacing.xs),
        Text(
          step.description,
          style: InkTypography.footnote.copyWith(
            color: InkColors.textPrimary.withValues(alpha: 0.68),
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _WorkflowPageIndicators extends StatelessWidget {
  const _WorkflowPageIndicators({
    required this.count,
    required this.activeIndex,
    required this.onTap,
  });

  final int count;
  final int activeIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++) ...[
          if (i > 0) const SizedBox(width: InkSpacing.sm),
          GestureDetector(
            onTap: () => onTap(i),
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              width: i == activeIndex ? 22 : 7,
              height: 7,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: i == activeIndex
                    ? InkColors.accentGold
                    : InkColors.textPrimary.withValues(alpha: 0.18),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
