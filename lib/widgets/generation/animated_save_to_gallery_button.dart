import 'package:flutter/cupertino.dart';
import 'package:ink_n_motion/utils/design_tokens.dart';

/// Save action that scales in when generation output becomes available.
class AnimatedSaveToGalleryButton extends StatefulWidget {
  const AnimatedSaveToGalleryButton({
    super.key,
    required this.visible,
    required this.onPressed,
    this.feedback,
    this.filledColor,
  });

  final bool visible;
  final VoidCallback onPressed;
  final String? feedback;
  final Color? filledColor;

  @override
  State<AnimatedSaveToGalleryButton> createState() =>
      _AnimatedSaveToGalleryButtonState();
}

class _AnimatedSaveToGalleryButtonState extends State<AnimatedSaveToGalleryButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _scale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    if (widget.visible) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(AnimatedSaveToGalleryButton oldWidget) {
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
    if (!widget.visible) return const SizedBox.shrink();

    return Column(
      children: [
        ScaleTransition(
          scale: _scale,
          child: SizedBox(
            width: double.infinity,
            child: widget.filledColor != null
                ? CupertinoButton.filled(
                    color: widget.filledColor,
                    onPressed: widget.onPressed,
                    child: const Text('Save to Gallery'),
                  )
                : CupertinoButton(
                    onPressed: widget.onPressed,
                    child: const Text('Save to Gallery'),
                  ),
          ),
        ),
        if (widget.feedback != null)
          Padding(
            padding: const EdgeInsets.only(top: InkSpacing.sm),
            child: Text(widget.feedback!, style: InkTypography.caption1),
          ),
      ],
    );
  }
}
