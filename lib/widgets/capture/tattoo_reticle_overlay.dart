import 'package:flutter/cupertino.dart';
import 'package:ink_n_motion/utils/design_tokens.dart';
import 'package:ink_n_motion/widgets/ink_neon_glow.dart';

/// Centered, rounded neon framing guide for tattoo positioning.
class TattooReticleOverlay extends StatelessWidget {
  const TattooReticleOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: InkNeonGlow(
          color: InkColors.accentNeonCyan,
          blurRadius: 22,
          spreadRadius: 2,
          child: CustomPaint(
            painter: _TattooReticlePainter(),
            child: const SizedBox(width: 240, height: 300),
          ),
        ),
      ),
    );
  }
}

class _TattooReticlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const inset = 8.0;
    const cornerRadius = 28.0;
    final rect = Rect.fromLTWH(
      inset,
      inset,
      size.width - inset * 2,
      size.height - inset * 2,
    );
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(cornerRadius));

    final glowPaint = Paint()
      ..color = InkColors.accentNeonCyan.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawRRect(rrect, glowPaint);

    final cornerPaint = Paint()
      ..color = InkColors.accentNeonCyan
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    const cornerLen = 36.0;
    _drawCorners(canvas, rect, cornerLen, cornerPaint);
  }

  void _drawCorners(Canvas canvas, Rect rect, double len, Paint paint) {
    // Top-left
    canvas.drawLine(rect.topLeft, rect.topLeft + Offset(len, 0), paint);
    canvas.drawLine(rect.topLeft, rect.topLeft + Offset(0, len), paint);
    // Top-right
    canvas.drawLine(rect.topRight, rect.topRight + Offset(-len, 0), paint);
    canvas.drawLine(rect.topRight, rect.topRight + Offset(0, len), paint);
    // Bottom-left
    canvas.drawLine(rect.bottomLeft, rect.bottomLeft + Offset(len, 0), paint);
    canvas.drawLine(rect.bottomLeft, rect.bottomLeft + Offset(0, -len), paint);
    // Bottom-right
    canvas.drawLine(rect.bottomRight, rect.bottomRight + Offset(-len, 0), paint);
    canvas.drawLine(rect.bottomRight, rect.bottomRight + Offset(0, -len), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
