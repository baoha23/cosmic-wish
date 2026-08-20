import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/gen/app_localizations.dart';
import '../models/wish_session.dart';
import '../services/audio_service.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/starfield_background.dart';
import '../widgets/mystic_button.dart';
import 'camera_screen.dart';

class PreparationScreen extends StatefulWidget {
  const PreparationScreen({super.key, required this.session});

  final WishSession session;

  @override
  State<PreparationScreen> createState() => _PreparationScreenState();
}

class _PreparationScreenState extends State<PreparationScreen> {
  late final AudioService _audio;
  int _countdown = 3;

  @override
  void initState() {
    super.initState();
    _audio = AudioService();
    final appState = context.read<AppState>();
    _init(appState);
  }

  Future<void> _init(AppState appState) async {
    if (appState.soundEnabled) {
      await _audio.init();
      await _audio.playAmbient();
    }
    _startCountdown(appState);
  }

  Future<void> _startCountdown(AppState appState) async {
    for (var i = 5; i > 0; i--) {
      if (!mounted) return;
      setState(() => _countdown = i);
      await Future.delayed(const Duration(seconds: 1));
    }
    if (!mounted) return;
    if (appState.soundEnabled) await _audio.stopAmbient();
    if (!mounted) return;
    _goToCamera();
  }

  void _goToCamera() {
    if (_navigated) return;
    _navigated = true;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, _, _) => CameraScreen(session: widget.session),
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 1500),
      ),
    );
  }

  bool _navigated = false;

  @override
  void dispose() {
    _audio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    return Scaffold(
      body: StarfieldBackground(
        starCount: appState.starCount,
        twinkleSpeed: appState.animationSpeed,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final circleSize = (w * 0.55).clamp(160.0, 240.0);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    const Spacer(flex: 2),
                    Text(
                      AppLocalizations.of(context)!.centerYourselfHeader,
                      style: AppText.heading(26),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      AppLocalizations.of(context)!.universeListensSub,
                      style: AppText.body(16).copyWith(color: AppColors.ash),
                    ),
                    const Spacer(flex: 3),
                    _BreathingCircle(count: _countdown, size: circleSize),
                    const Spacer(flex: 3),
                    MysticButton(
                      label: AppLocalizations.of(context)!.ready,
                      semanticLabel: AppLocalizations.of(
                        context,
                      )!.readySemantic2,
                      expand: true,
                      onPressed: _goToCamera,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _BreathingCircle extends StatefulWidget {
  const _BreathingCircle({required this.count, required this.size});

  final int count;
  final double size;

  @override
  State<_BreathingCircle> createState() => _BreathingCircleState();
}

class _BreathingCircleState extends State<_BreathingCircle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final scale = 0.88 + _controller.value * 0.12;
          return Stack(
            alignment: Alignment.center,
            children: [
              Transform.scale(
                scale: scale,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.4),
                      width: 1,
                    ),
                  ),
                ),
              ),
              Container(
                width: widget.size * 0.78,
                height: widget.size * 0.78,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.15),
                    width: 1,
                  ),
                ),
              ),
              Text(
                '${widget.count}',
                style: AppText.display().copyWith(
                  fontSize: 56,
                  color: AppColors.goldWhisper,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
