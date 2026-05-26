import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/scheduler.dart';

/// Neon particle shimmer layered over the tattoo mask ink region.
class SparkleParticleOverlay extends StatefulWidget {
  const SparkleParticleOverlay({
    super.key,
    required this.maskUrl,
    this.particleCount = 56,
  });

  final String maskUrl;
  final int particleCount;

  @override
  State<SparkleParticleOverlay> createState() => _SparkleParticleOverlayState();
}

class _SparkleParticleOverlayState extends State<SparkleParticleOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  List<_SparkleParticle> _particles = const [];
  bool _anchorsReady = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..addListener(_onTick);

    SchedulerBinding.instance.scheduleFrameCallback((_) {
      _controller.repeat();
    });

    _loadMaskAnchors();
  }

  void _onTick() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadMaskAnchors() async {
    try {
      final response = await Dio().get<List<int>>(
        widget.maskUrl,
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = response.data;
      if (bytes == null || bytes.isEmpty || !mounted) return;

      final codec = await ui.instantiateImageCodec(Uint8List.fromList(bytes));
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final width = image.width;
      final height = image.height;
      final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      image.dispose();

      if (byteData == null || !mounted) return;
      final pixels = byteData.buffer.asUint8List();
      final anchors = <Offset>[];
      const step = 6;

      for (var y = 0; y < height; y += step) {
        for (var x = 0; x < width; x += step) {
          final index = (y * width + x) * 4;
          final alpha = pixels[index + 3];
          if (alpha > 96) {
            anchors.add(
              Offset(x / width, y / height),
            );
          }
        }
      }

      if (anchors.isEmpty) {
        anchors.add(const Offset(0.5, 0.5));
      }

      final random = math.Random(7);
      final particles = List<_SparkleParticle>.generate(widget.particleCount, (i) {
        final anchor = anchors[i % anchors.length];
        return _SparkleParticle(
          anchor: anchor,
          phase: random.nextDouble() * math.pi * 2,
          drift: 0.012 + random.nextDouble() * 0.028,
          size: 1.6 + random.nextDouble() * 3.4,
          color: i.isEven
              ? CupertinoColors.activeBlue
              : CupertinoColors.systemPurple,
        );
      });

      if (!mounted) return;
      setState(() {
        _particles = particles;
        _anchorsReady = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _particles = _fallbackParticles();
        _anchorsReady = true;
      });
    }
  }

  List<_SparkleParticle> _fallbackParticles() {
    final random = math.Random(11);
    return List<_SparkleParticle>.generate(widget.particleCount, (i) {
      return _SparkleParticle(
        anchor: Offset(
          0.2 + random.nextDouble() * 0.6,
          0.2 + random.nextDouble() * 0.6,
        ),
        phase: random.nextDouble() * math.pi * 2,
        drift: 0.02,
        size: 2.4,
        color: i.isEven
            ? CupertinoColors.activeBlue
            : CupertinoColors.systemPurple,
      );
    });
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onTick)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _SparkleParticlePainter(
              particles: _particles,
              progress: _controller.value,
              anchorsReady: _anchorsReady,
            ),
            child: const SizedBox.expand(),
          );
        },
      ),
    );
  }
}

class _SparkleParticle {
  const _SparkleParticle({
    required this.anchor,
    required this.phase,
    required this.drift,
    required this.size,
    required this.color,
  });

  final Offset anchor;
  final double phase;
  final double drift;
  final double size;
  final Color color;
}

class _SparkleParticlePainter extends CustomPainter {
  _SparkleParticlePainter({
    required this.particles,
    required this.progress,
    required this.anchorsReady,
  });

  final List<_SparkleParticle> particles;
  final double progress;
  final bool anchorsReady;

  @override
  void paint(Canvas canvas, Size size) {
    if (!anchorsReady || particles.isEmpty) return;

    final glowPaint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final corePaint = Paint()..style = PaintingStyle.fill;

    final tick = progress * math.pi * 2;

    for (final particle in particles) {
      final shimmer = math.sin(tick + particle.phase);
      final crawlX = math.cos(tick * 0.7 + particle.phase) * particle.drift;
      final crawlY = math.sin(tick * 0.9 + particle.phase) * particle.drift;

      final x = (particle.anchor.dx + crawlX) * size.width;
      final y = (particle.anchor.dy + crawlY) * size.height;

      final opacity = (0.35 + (shimmer + 1) * 0.32).clamp(0.0, 1.0);
      final radius = particle.size * (0.85 + shimmer * 0.25);

      glowPaint.color = particle.color.withValues(alpha: opacity * 0.55);
      canvas.drawCircle(Offset(x, y), radius * 2.2, glowPaint);

      corePaint.color = particle.color.withValues(alpha: opacity);
      canvas.drawCircle(Offset(x, y), radius, corePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparkleParticlePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.particles != particles ||
        oldDelegate.anchorsReady != anchorsReady;
  }
}
