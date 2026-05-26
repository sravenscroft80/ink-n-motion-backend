import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:ink_n_motion/utils/ink_haptics.dart';

/// iOS-style shutter flash — quick white fade (~100ms) over the preview stack.
class ShutterFlashOverlay extends StatefulWidget {
  const ShutterFlashOverlay({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  ShutterFlashOverlayState createState() => ShutterFlashOverlayState();
}

class ShutterFlashOverlayState extends State<ShutterFlashOverlay>
    with SingleTickerProviderStateMixin {
  static const Duration _flashDuration = Duration(milliseconds: 100);

  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _flashDuration);
    _opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.92), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 0.92, end: 0.0), weight: 60),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Triggers the physical-shutter style flash overlay.
  Future<void> flash() async {
    if (!mounted) return;
    unawaited(InkHaptics.shutterCapture());
    await _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        IgnorePointer(
          child: AnimatedBuilder(
            animation: _opacity,
            builder: (context, child) {
              if (_opacity.value <= 0) return const SizedBox.shrink();
              return ColoredBox(
                color: const Color(0xFFFFFFFF).withValues(alpha: _opacity.value),
              );
            },
          ),
        ),
      ],
    );
  }
}
