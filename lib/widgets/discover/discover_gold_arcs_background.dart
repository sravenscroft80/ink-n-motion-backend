import 'package:flutter/cupertino.dart';
import 'package:ink_n_motion/utils/design_tokens.dart';

/// Subtle decorative gold arcs behind Discover content.
class DiscoverGoldArcsBackground extends StatelessWidget {
  const DiscoverGoldArcsBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return const Positioned.fill(
      child: CustomPaint(
        painter: _DiscoverGoldArcsPainter(),
      ),
    );
  }
}

class _DiscoverGoldArcsPainter extends CustomPainter {
  const _DiscoverGoldArcsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = InkColors.accentGold.withValues(alpha: 0.22);

    final arc1 = Path()
      ..moveTo(size.width * 0.05, size.height * 0.12)
      ..quadraticBezierTo(
        size.width * 0.55,
        size.height * 0.02,
        size.width * 0.95,
        size.height * 0.18,
      );
    canvas.drawPath(arc1, paint);

    final faint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9
      ..color = InkColors.accentGold.withValues(alpha: 0.12);

    final arc2 = Path()
      ..moveTo(size.width * 0.0, size.height * 0.28)
      ..quadraticBezierTo(
        size.width * 0.45,
        size.height * 0.35,
        size.width * 0.88,
        size.height * 0.22,
      );
    canvas.drawPath(arc2, faint);

    final arc3 = Path()
      ..moveTo(size.width * 0.15, size.height * 0.55)
      ..quadraticBezierTo(
        size.width * 0.6,
        size.height * 0.48,
        size.width * 1.05,
        size.height * 0.62,
      );
    canvas.drawPath(arc3, faint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
