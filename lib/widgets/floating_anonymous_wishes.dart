import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../services/anonymous_wishes_service.dart';
import '../theme/app_colors.dart';

/// A calm, decorative overlay that shows anonymous wishes from other
/// people drifting slowly across the screen like soft clouds. Pure
/// visual — `IgnorePointer` is wrapped so taps always go to the
/// underlying CTA.
class FloatingAnonymousWishes extends StatefulWidget {
  const FloatingAnonymousWishes({super.key, this.maxItems = 6});

  final int maxItems;

  @override
  State<FloatingAnonymousWishes> createState() =>
      _FloatingAnonymousWishesState();
}

class _FloatingAnonymousWishesState extends State<FloatingAnonymousWishes> {
  final _service = AnonymousWishesService();
  final _random = Random();

  List<_DriftSpec> _specs = const [];
  Timer? _refresh;

  @override
  void initState() {
    super.initState();
    _load();
    // Re-fetch every 5 minutes so the home screen feels alive, but
    // also so we don't hammer the API when the user lingers.
    _refresh = Timer.periodic(const Duration(minutes: 5), (_) => _load());
  }

  Future<void> _load() async {
    final wishes = await _service.fetchSample(count: 14);
    if (!mounted) return;
    if (wishes.isEmpty) {
      setState(() => _specs = const []);
      return;
    }
    final specs = <_DriftSpec>[];
    final take = wishes.length < widget.maxItems
        ? wishes.length
        : widget.maxItems;
    final used = <AnonymousWish>{};
    for (var i = 0; i < take; i++) {
      // Pick a wish that hasn't been used in this round yet.
      final remaining = wishes.where((w) => !used.contains(w)).toList();
      if (remaining.isEmpty) break;
      final pick = remaining[_random.nextInt(remaining.length)];
      used.add(pick);
      specs.add(_DriftSpec.from(wish: pick, seed: _random.nextDouble()));
    }
    setState(() => _specs = specs);
  }

  @override
  void dispose() {
    _refresh?.cancel();
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          return Stack(
            children: [
              for (final spec in _specs)
                _DriftingWish(spec: spec, canvas: size),
            ],
          );
        },
      ),
    );
  }
}

class _DriftSpec {
  _DriftSpec({
    required this.wish,
    required this.top,
    required this.fontSize,
    required this.opacity,
    required this.durationSeconds,
    required this.delayMs,
    required this.startFromLeft,
  });

  final AnonymousWish wish;

  /// Vertical position as a fraction of the canvas height (0..1).
  final double top;
  final double fontSize;
  final double opacity;
  final int durationSeconds;
  final int delayMs;
  final bool startFromLeft;

  factory _DriftSpec.from({required AnonymousWish wish, required double seed}) {
    final r = Random((seed * 1e6).toInt());
    return _DriftSpec(
      wish: wish,
      top: 0.08 + r.nextDouble() * 0.84,
      fontSize: 13 + r.nextDouble() * 4,
      opacity: 0.32 + r.nextDouble() * 0.28,
      durationSeconds: 28 + r.nextInt(22),
      delayMs: r.nextInt(12000),
      startFromLeft: r.nextBool(),
    );
  }
}

class _DriftingWish extends StatefulWidget {
  const _DriftingWish({required this.spec, required this.canvas});

  final _DriftSpec spec;
  final Size canvas;

  @override
  State<_DriftingWish> createState() => _DriftingWishState();
}

class _DriftingWishState extends State<_DriftingWish>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.spec.durationSeconds),
    );
    _delayTimer = Timer(Duration(milliseconds: widget.spec.delayMs), () {
      if (mounted) _controller.repeat();
    });
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        // Easing: t in 0..1 maps to -0.3..1.3, off-screen on both sides.
        final eased = Curves.easeInOut.transform(t);
        final start = -0.3;
        final end = 1.3;
        final pos = start + (end - start) * eased;
        final left =
            (widget.spec.startFromLeft ? pos : 1 - pos) * widget.canvas.width;
        return Positioned(
          left: left - 120,
          top: widget.spec.top * widget.canvas.height,
          child: Opacity(
            opacity: widget.spec.opacity,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 240),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.obsidian.withValues(alpha: 0.35),
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.15),
                  width: 0.5,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '"${widget.spec.wish.transcript}"',
                style: TextStyle(
                  color: AppColors.parchment,
                  fontSize: widget.spec.fontSize,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        );
      },
    );
  }
}
