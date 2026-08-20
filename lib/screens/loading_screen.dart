import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/gen/app_localizations.dart';
import '../models/wish_session.dart';
import '../services/wish_service.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/mystic_button.dart';
import '../widgets/starfield_background.dart';
import 'ai_reflection_screen.dart';
import 'result_screen.dart';

/// Loading bridge for both AI turns. The first response can open the
/// reflection question; the second response opens the final result.
class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key, required this.session});

  final WishSession session;

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  final _service = WishService();
  String _hint = '';
  String _subHint = '';
  bool _hasError = false;
  bool _sending = false;
  Timer? _hintTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _sendWish();
    });
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    _service.dispose();
    super.dispose();
  }

  Future<void> _sendWish() async {
    if (_sending) return;
    setState(() {
      _sending = true;
      _hasError = false;
      _hint = '';
      _subHint = '';
    });
    _startHintCycle();
    try {
      final locale = Localizations.localeOf(context).languageCode;
      final question = widget.session.reflectionQuestion;
      final answer = widget.session.reflectionAnswer;
      if (question == null || answer == null) {
        final initial = await _service.beginWish(
          category: widget.session.category,
          transcript: widget.session.transcript,
          locale: locale,
        );
        _hintTimer?.cancel();
        if (!mounted) return;
        if (initial.needsReflection) {
          widget.session.reflectionQuestion = initial.question;
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (_, _, _) =>
                  AiReflectionScreen(session: widget.session),
              transitionsBuilder: (_, anim, _, child) =>
                  FadeTransition(opacity: anim, child: child),
              transitionDuration: const Duration(milliseconds: 900),
            ),
          );
          return;
        }
        widget.session.response = initial.prophecy;
      } else {
        widget.session.response = await _service.generateProphecy(
          category: widget.session.category,
          transcript: widget.session.transcript,
          question: question,
          reflection: answer,
          locale: locale,
        );
      }
      _hintTimer?.cancel();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, _, _) => ResultScreen(session: widget.session),
          transitionsBuilder: (_, anim, _, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 1500),
        ),
      );
    } catch (e) {
      _hintTimer?.cancel();
      if (!mounted) return;
      final l = AppLocalizations.of(context)!;
      // Show the error inline on the loading screen rather than
      // bouncing back, so the user can retry without losing the
      // wish they just typed.
      setState(() {
        _hint = e.toString();
        _subHint = l.tryAgain;
        _hasError = true;
        _sending = false;
      });
    }
  }

  /// Rotates hint/sub-hint pairs every 2.5s while a wish is in
  /// flight. Uses a [Timer] (not an awaited loop) so dispose can cancel
  /// it cleanly — preventing the previous bug where the error path
  /// hung forever because the loop only returned when `mounted` flipped.
  void _startHintCycle() {
    final l = AppLocalizations.of(context)!;
    final pairs = <(String, String)>[
      (l.sendingToUniverse, l.universeListens),
      (l.universeListens, l.weavingProphecy),
      (l.starsAligning, l.almostThere),
    ];
    if (pairs.first.$1.isEmpty) return; // l10n not ready
    var i = 0;
    setState(() {
      _hint = pairs.first.$1;
      _subHint = pairs.first.$2;
    });
    _hintTimer?.cancel();
    _hintTimer = Timer.periodic(const Duration(milliseconds: 2500), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      i = (i + 1) % pairs.length;
      setState(() {
        _hint = pairs[i].$1;
        _subHint = pairs[i].$2;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    return Scaffold(
      body: StarfieldBackground(
        starCount: appState.starCount,
        twinkleSpeed: appState.animationSpeed,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                if (!_hasError) const _ConcentricRings(),
                if (_hasError) const SizedBox(height: 24),
                const SizedBox(height: 36),
                Text(
                  _hint,
                  style: AppText.heading(18),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _subHint,
                  style: AppText.caption(14),
                  textAlign: TextAlign.center,
                ),
                if (_hasError) ...[
                  const SizedBox(height: 32),
                  MysticButton(
                    label: AppLocalizations.of(context)!.tryAgain,
                    semanticLabel: AppLocalizations.of(context)!.tryAgain,
                    expand: true,
                    onPressed: _sending ? null : _sendWish,
                  ),
                ],
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ConcentricRings extends StatefulWidget {
  const _ConcentricRings();

  @override
  State<_ConcentricRings> createState() => _ConcentricRingsState();
}

class _ConcentricRingsState extends State<_ConcentricRings>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 4))
      ..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      height: 180,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          return CustomPaint(painter: _RingsPainter(_c.value));
        },
      ),
    );
  }
}

class _RingsPainter extends CustomPainter {
  _RingsPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = AppColors.gold.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    for (var i = 0; i < 3; i++) {
      final phase = (t + i / 3) % 1.0;
      final r = phase * size.width * 0.5;
      canvas.drawCircle(
        c,
        r,
        paint..color = AppColors.gold.withValues(alpha: 0.5 * (1 - phase)),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingsPainter oldDelegate) => true;
}
