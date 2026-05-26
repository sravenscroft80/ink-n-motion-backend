import 'package:flutter/cupertino.dart';
import 'package:ink_n_motion/utils/design_tokens.dart';

/// Fade-in wrapper for generation success content with optional preview watermark.
class GenerationSuccessReveal extends StatefulWidget {
  const GenerationSuccessReveal({
    super.key,
    required this.visible,
    required this.child,
    this.outputHasWatermark = false,
  });

  final bool visible;
  final Widget child;
  final bool outputHasWatermark;

  @override
  State<GenerationSuccessReveal> createState() => _GenerationSuccessRevealState();
}

class _GenerationSuccessRevealState extends State<GenerationSuccessReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    if (widget.visible) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(GenerationSuccessReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible && !oldWidget.visible) {
      _controller.forward(from: 0);
    } else if (!widget.visible && oldWidget.visible) {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          widget.child,
          if (widget.outputHasWatermark && widget.visible)
            Positioned(
              right: InkSpacing.sm,
              bottom: InkSpacing.sm,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: CupertinoColors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(InkRadius.sm),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: InkSpacing.sm,
                    vertical: InkSpacing.xs,
                  ),
                  child: Text(
                    'ink·n·motion',
                    style: InkTypography.caption2.copyWith(
                      color: InkColors.textPrimary.withValues(alpha: 0.92),
                      letterSpacing: 0.6,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
