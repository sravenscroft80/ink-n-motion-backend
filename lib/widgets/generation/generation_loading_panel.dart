import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:ink_n_motion/utils/design_tokens.dart';
import 'package:ink_n_motion/widgets/generation/generation_status_messages.dart';

/// Dark-mode pulsing ring loader with cycling premium status copy.
class GenerationLoadingPanel extends StatefulWidget {
  const GenerationLoadingPanel({
    super.key,
    required this.accentColor,
  });

  final Color accentColor;

  @override
  State<GenerationLoadingPanel> createState() => _GenerationLoadingPanelState();
}

class _GenerationLoadingPanelState extends State<GenerationLoadingPanel>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulse;
  Timer? _messageTimer;
  int _messageIndex = 0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.88, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _messageTimer = Timer.periodic(GenerationStatusMessages.cycleInterval, (_) {
      if (!mounted) return;
      setState(() {
        _messageIndex =
            (_messageIndex + 1) % GenerationStatusMessages.pipelineSteps.length;
      });
    });
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final message = GenerationStatusMessages.pipelineSteps[_messageIndex];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ScaleTransition(
          scale: _pulse,
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return SizedBox(
                width: 72,
                height: 72,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(72, 72),
                      painter: _PulsingRingPainter(
                        color: widget.accentColor,
                        progress: _pulseController.value,
                      ),
                    ),
                    CupertinoActivityIndicator(
                      radius: 14,
                      color: widget.accentColor,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: InkSpacing.lg),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: Text(
            message,
            key: ValueKey<String>(message),
            style: InkTypography.callout.copyWith(color: InkColors.textPrimary),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

class _PulsingRingPainter extends CustomPainter {
  _PulsingRingPainter({required this.color, required this.progress});

  final Color color;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    final trackPaint = Paint()
      ..color = color.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, radius, trackPaint);

    final arcPaint = Paint()
      ..color = color.withValues(alpha: 0.45 + (progress * 0.4))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.2,
      2.4 + progress,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _PulsingRingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
