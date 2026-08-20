import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// A mystical cosmic sigil: a hexagram (six-pointed star) inscribed in a
/// circle, with a single eye in the center. Drawn entirely with smooth
/// Bezier curves so it scales to any size without pixelation.
class MysticalGlyph extends StatefulWidget {
  const MysticalGlyph({super.key, this.size = 200});

  final double size;

  @override
  State<MysticalGlyph> createState() => _MysticalGlyphState();
}

class _MysticalGlyphState extends State<MysticalGlyph>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    return SizedBox(
      width: size * 1.3,
      height: size * 1.3,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) {
          final t = Curves.easeInOut.transform(_ctrl.value);
          final scale = 1.0 + 0.06 * t;
          final glowAlpha = 0.22 + 0.22 * t;
          return Stack(
            alignment: Alignment.center,
            children: [
              // Soft outer glow
              Container(
                width: size * 0.95,
                height: size * 0.95,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.goldWhisper.withValues(alpha: glowAlpha),
                      AppColors.gold.withValues(alpha: 0.05),
                      AppColors.gold.withValues(alpha: 0),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
              Transform.scale(
                scale: scale,
                child: CustomPaint(
                  size: Size.square(size),
                  painter: _SigilPainter(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SigilPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;
    final R = w * 0.42; // outer ring radius

    final gold = Paint()
      ..color = AppColors.gold
      ..style = PaintingStyle.fill;
    final goldLine = Paint()
      ..color = AppColors.goldWhisper
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    final goldThin = Paint()
      ..color = AppColors.gold.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    final eyeWhite = Paint()
      ..color = AppColors.goldWhisper
      ..style = PaintingStyle.fill;
    final eyeDark = Paint()
      ..color = AppColors.obsidian
      ..style = PaintingStyle.fill;
    final eyeIris = Paint()
      ..color = AppColors.goldWhisper
      ..style = PaintingStyle.fill;

    // === Outer circle ===
    final ringPath = Path()
      ..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: R));
    canvas.drawPath(ringPath, goldThin);
    canvas.drawPath(
      Path()..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: R - 6)),
      goldThin,
    );

    // === Hexagram (Star of David / Solomon's Seal) ===
    // Two overlapping equilateral triangles
    final triR = R * 0.82; // circumscribed radius of triangles

    // Upward-pointing triangle (apex at top)
    final up = Path();
    for (var i = 0; i < 3; i++) {
      final a = -pi / 2 + i * 2 * pi / 3;
      final x = cx + triR * cos(a);
      final y = cy + triR * sin(a);
      if (i == 0) {
        up.moveTo(x, y);
      } else {
        up.lineTo(x, y);
      }
    }
    up.close();
    canvas.drawPath(up, goldLine);

    // Downward-pointing triangle
    final down = Path();
    for (var i = 0; i < 3; i++) {
      final a = pi / 2 + i * 2 * pi / 3;
      final x = cx + triR * cos(a);
      final y = cy + triR * sin(a);
      if (i == 0) {
        down.moveTo(x, y);
      } else {
        down.lineTo(x, y);
      }
    }
    down.close();
    canvas.drawPath(down, goldLine);

    // === Central eye (the all-seeing eye of cosmic consciousness) ===
    // Eye almond shape
    final eyeR = R * 0.30;
    final eyePath = Path();
    final eyeHalfW = eyeR * 1.4;
    final eyeHalfH = eyeR * 0.7;
    // Almond via two arcs
    eyePath.moveTo(cx - eyeHalfW, cy);
    eyePath.quadraticBezierTo(cx, cy - eyeHalfH, cx + eyeHalfW, cy);
    eyePath.quadraticBezierTo(cx, cy + eyeHalfH, cx - eyeHalfW, cy);
    eyePath.close();
    canvas.drawPath(eyePath, gold);

    // Eye outline (slightly darker)
    canvas.drawPath(
      eyePath,
      Paint()
        ..color = AppColors.goldDark
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // Iris circle
    final irisR = eyeR * 0.55;
    canvas.drawCircle(Offset(cx, cy), irisR, eyeIris);

    // Pupil (dark dot)
    final pupilR = irisR * 0.45;
    canvas.drawCircle(Offset(cx, cy), pupilR, eyeDark);

    // Small catch-light highlight on pupil
    canvas.drawCircle(
      Offset(cx - pupilR * 0.3, cy - pupilR * 0.3),
      pupilR * 0.18,
      eyeWhite,
    );

    // === Six small dots at star vertices (mystic seal marks) ===
    for (var i = 0; i < 6; i++) {
      final a = i * pi / 3;
      final x = cx + (R - 3) * cos(a);
      final y = cy + (R - 3) * sin(a);
      canvas.drawCircle(Offset(x, y), 1.6, gold);
    }

    // === Tiny gold accent strokes around the ring ===
    // Three small tick marks at cardinal positions
    for (final a in [pi / 2, pi / 2 + 2 * pi / 3, pi / 2 + 4 * pi / 3]) {
      final inner = Offset(cx + (R - 8) * cos(a), cy + (R - 8) * sin(a));
      final outer = Offset(cx + (R - 2) * cos(a), cy + (R - 2) * sin(a));
      canvas.drawLine(
        inner,
        outer,
        Paint()
          ..color = AppColors.goldWhisper
          ..strokeWidth = 1.2,
      );
    }
  }

  // Painter draws the same static shape each time; scale is applied
  // by the wrapping Transform.scale so the painter itself never needs
  // to repaint.
  @override
  bool shouldRepaint(covariant _SigilPainter oldDelegate) => false;
}
