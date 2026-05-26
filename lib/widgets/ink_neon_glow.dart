import 'package:flutter/cupertino.dart';

/// Soft neon glow behind generative / accent UI.
class InkNeonGlow extends StatelessWidget {
  const InkNeonGlow({
    super.key,
    required this.color,
    required this.child,
    this.blurRadius = 28,
    this.spreadRadius = 0,
  });

  final Color color;
  final Widget child;
  final double blurRadius;
  final double spreadRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.45),
            blurRadius: blurRadius,
            spreadRadius: spreadRadius,
          ),
        ],
      ),
      child: child,
    );
  }
}
