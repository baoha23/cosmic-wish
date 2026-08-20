import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class Star {
  Star({
    required this.position,
    required this.radius,
    required this.brightness,
    required this.tint,
    required this.phase,
    required this.twinkleRate,
    required this.twinkleAmp,
  });

  final Offset position;
  final double radius;
  final double brightness;
  final Color tint;

  /// Where this star sits in its twinkle cycle at t=0, in [0,1).
  final double phase;

  /// Integer oscillations per animation period. Kept whole so the sine
  /// wave stays continuous across the controller's 0→1 wrap (no visible
  /// jump when the loop restarts).
  final int twinkleRate;

  /// Fraction of brightness that pulses (0 = steady, 0.5 = strong twinkle).
  final double twinkleAmp;
}

class _NebulaBlob {
  _NebulaBlob(this.x, this.y, this.radius, this.color, this.alpha);
  final double x;
  final double y;
  final double radius;
  final Color color;
  final double alpha;
}

class _StarfieldPainter extends CustomPainter {
  _StarfieldPainter({
    required this.stars,
    required this.nebula,
    required this.t,
  });

  final List<Star> stars;
  final List<_NebulaBlob> nebula;

  /// Global animation phase in [0,1), repeating each period.
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    for (final blob in nebula) {
      final paint = Paint()
        ..shader =
            RadialGradient(
              colors: [
                blob.color.withValues(alpha: blob.alpha),
                blob.color.withValues(alpha: 0),
              ],
            ).createShader(
              Rect.fromCircle(
                center: Offset(blob.x * size.width, blob.y * size.height),
                radius: blob.radius * size.shortestSide,
              ),
            );
      canvas.drawCircle(
        Offset(blob.x * size.width, blob.y * size.height),
        blob.radius * size.shortestSide,
        paint,
      );
    }

    for (final star in stars) {
      final wave =
          0.5 + 0.5 * sin(2 * pi * (t * star.twinkleRate + star.phase));
      final factor = (1 - star.twinkleAmp) + star.twinkleAmp * wave;
      final alpha = (star.brightness * factor).clamp(0.0, 1.0);
      final p = Paint()
        ..color = star.tint.withValues(alpha: alpha)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(star.position, star.radius, p);
    }
  }

  @override
  bool shouldRepaint(covariant _StarfieldPainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.stars != stars;
}

class StarfieldBackground extends StatefulWidget {
  const StarfieldBackground({
    super.key,
    this.starCount = 160,
    this.twinkleSpeed = 1.0,
    this.child,
  });

  final int starCount;

  /// Multiplier on the twinkle animation speed. Wired to
  /// [AppState.animationSpeed] so the settings slider actually does
  /// something. 1.0 = default cadence.
  final double twinkleSpeed;

  final Widget? child;

  static final _seed = Random(7);
  static final Map<int, List<Star>> _starCache = <int, List<Star>>{};

  static List<Star> _generateStars(int count) {
    final cached = _starCache[count];
    if (cached != null) return cached;
    final stars = List.generate(count, (_) {
      final tier = _seed.nextDouble();
      double radius;
      double brightness;
      double twinkleAmp;
      if (tier < 0.7) {
        // Faint dust: twinkles the most.
        radius = 0.4 + _seed.nextDouble() * 0.6;
        brightness = 0.25 + _seed.nextDouble() * 0.25;
        twinkleAmp = 0.35 + _seed.nextDouble() * 0.25;
      } else if (tier < 0.95) {
        radius = 0.7 + _seed.nextDouble() * 0.8;
        brightness = 0.4 + _seed.nextDouble() * 0.3;
        twinkleAmp = 0.2 + _seed.nextDouble() * 0.2;
      } else {
        // Bright anchors: nearly steady so the field doesn't shimmer.
        radius = 1.2 + _seed.nextDouble() * 1.0;
        brightness = 0.6 + _seed.nextDouble() * 0.3;
        twinkleAmp = 0.08 + _seed.nextDouble() * 0.12;
      }
      final tintRoll = _seed.nextDouble();
      final Color tint;
      if (tintRoll < 0.7) {
        tint = AppColors.parchment;
      } else if (tintRoll < 0.9) {
        tint = const Color(0xFFB6C2D6);
      } else {
        tint = AppColors.goldWhisper;
      }
      return Star(
        position: Offset(_seed.nextDouble(), _seed.nextDouble()),
        radius: radius,
        brightness: brightness,
        tint: tint,
        phase: _seed.nextDouble(),
        twinkleRate: 1 + _seed.nextInt(3), // 1..3 oscillations per period
        twinkleAmp: twinkleAmp,
      );
    });
    _starCache[count] = stars;
    return stars;
  }

  static final List<_NebulaBlob> _nebula = [
    _NebulaBlob(0.25, 0.30, 0.45, const Color(0xFF3A2A55), 0.18),
    _NebulaBlob(0.75, 0.65, 0.55, const Color(0xFF1F2D44), 0.16),
    _NebulaBlob(0.50, 0.85, 0.40, const Color(0xFF2C2238), 0.14),
  ];

  @override
  State<StarfieldBackground> createState() => _StarfieldBackgroundState();
}

class _StarfieldBackgroundState extends State<StarfieldBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  /// Full twinkle loop at speed 1.0. Long enough to feel like a slow,
  /// natural shimmer rather than a flicker.
  static const Duration _basePeriod = Duration(seconds: 12);

  Duration _scaledPeriod() {
    final speed = widget.twinkleSpeed.clamp(0.1, 4.0);
    return Duration(milliseconds: (_basePeriod.inMilliseconds / speed).round());
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _scaledPeriod())
      ..repeat();
  }

  @override
  void didUpdateWidget(covariant StarfieldBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.twinkleSpeed != widget.twinkleSpeed) {
      _controller.duration = _scaledPeriod();
      _controller.repeat(); // apply the new period
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: const BoxDecoration(gradient: AppColors.cosmicGradient),
        ),
        Positioned.fill(
          child: RepaintBoundary(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final size = constraints.biggest;
                final raw = StarfieldBackground._generateStars(
                  widget.starCount,
                );
                final positioned = [
                  for (final s in raw)
                    Star(
                      position: Offset(
                        s.position.dx * size.width,
                        s.position.dy * size.height,
                      ),
                      radius: s.radius,
                      brightness: s.brightness,
                      tint: s.tint,
                      phase: s.phase,
                      twinkleRate: s.twinkleRate,
                      twinkleAmp: s.twinkleAmp,
                    ),
                ];
                return AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) => CustomPaint(
                    painter: _StarfieldPainter(
                      stars: positioned,
                      nebula: StarfieldBackground._nebula,
                      t: _controller.value,
                    ),
                    size: size,
                  ),
                );
              },
            ),
          ),
        ),
        if (widget.child != null) widget.child!,
      ],
    );
  }
}
