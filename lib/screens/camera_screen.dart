import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:permission_handler/permission_handler.dart';
import '../l10n/gen/app_localizations.dart';
import '../models/wish_session.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'loading_screen.dart';

/// Ritual screen: camera preview in the background as atmospheric
/// decoration, with a single text field as the actual wish input.
///
/// The user does not speak — they type. The mystical copy ("Nói điều
/// ước của bạn") and the camera preview are kept to preserve the
/// ritual mood, but no audio is captured, transcribed, or uploaded.
class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key, required this.session});

  final WishSession session;

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? _camera;
  bool _cameraReady = false;
  _CameraError _cameraError = _CameraError.none;
  final TextEditingController _textController = TextEditingController();

  bool _permissionDenied = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bootstrap();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _textController.dispose();
    final cam = _camera;
    _camera = null;
    cam?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      final cam = _camera;
      if (cam != null && _cameraReady) {
        cam.dispose();
        _camera = null;
        _cameraReady = false;
      }
    } else if (state == AppLifecycleState.resumed) {
      if (_camera == null && !_permissionDenied) _initCamera();
    }
  }

  Future<void> _bootstrap() async {
    final cam = await _ensurePermission(Permission.camera);
    if (!cam) {
      if (mounted) {
        setState(() => _permissionDenied = true);
      }
      return;
    }
    await _initCamera();
  }

  Future<bool> _ensurePermission(Permission permission) async {
    if (await permission.isGranted) return true;
    return (await permission.request()).isGranted;
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) setState(() => _cameraError = _CameraError.noCamera);
        return;
      }
      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        front,
        ResolutionPreset.low,
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() {
        _camera = controller;
        _cameraReady = true;
        _cameraError = _CameraError.none;
      });
    } catch (e) {
      debugPrint('camera init error: $e');
      if (mounted) setState(() => _cameraError = _CameraError.openFailed);
    }
  }

  String? _cameraErrorText(AppLocalizations l) {
    if (_permissionDenied) return l.cameraPermissionNeeded;
    switch (_cameraError) {
      case _CameraError.none:
        return null;
      case _CameraError.noCamera:
        return l.noCameraFound;
      case _CameraError.openFailed:
        return l.cameraOpenError;
    }
  }

  void _submit() {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.enterWishEmpty),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    widget.session.transcript = text;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, _, _) => LoadingScreen(session: widget.session),
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 1000),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.obsidian,
      body: Stack(
        fit: StackFit.expand,
        children: [_buildBackground(), _buildRuneOverlay(), _buildUI()],
      ),
    );
  }

  Widget _topBar() {
    final l = AppLocalizations.of(context)!;
    return Row(
      children: [
        IconButton(
          tooltip: l.close,
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close, color: AppColors.parchment),
        ),
        const Spacer(),
        Text(
          l.sendWish,
          style: AppText.body(
            14,
          ).copyWith(color: AppColors.parchment.withValues(alpha: 0.85)),
        ),
        const Spacer(),
        const SizedBox(width: 48),
      ],
    );
  }

  Widget _buildPrompt() {
    return Text(
          AppLocalizations.of(context)!.thinkingPrompt,
          textAlign: TextAlign.center,
          style: AppText.heading(24).copyWith(color: AppColors.goldWhisper),
        )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .fadeIn(duration: 1500.ms, begin: 0.6);
  }

  Widget _buildBackground() {
    if (_cameraReady && _camera != null) {
      return SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _camera!.value.previewSize?.height ?? 1080,
            height: _camera!.value.previewSize?.width ?? 1920,
            child: CameraPreview(_camera!),
          ),
        ),
      );
    }
    return Container(color: AppColors.obsidian);
  }

  Widget _buildRuneOverlay() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Opacity(opacity: 0.25, child: const _RuneOverlay()),
      ),
    );
  }

  Widget _buildUI() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.4),
            Colors.black.withValues(alpha: 0.2),
            Colors.black.withValues(alpha: 0.7),
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            children: [
              _topBar(),
              const SizedBox(height: 16),
              _buildPrompt(),
              const SizedBox(height: 24),
              _inputBox(),
              const SizedBox(height: 20),
              _submitButton(),
              const Spacer(),
              if (_cameraErrorText(AppLocalizations.of(context)!)
                  case final err?)
                _statusText(err),
            ],
          ),
        ),
      ),
    );
  }

  Widget _inputBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cosmos.withValues(alpha: 0.7),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: TextField(
        controller: _textController,
        maxLines: 6,
        minLines: 4,
        maxLength: 500,
        autofocus: true,
        style: AppText.body(16).copyWith(color: AppColors.parchment),
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context)!.tapToWriteWish,
          hintStyle: AppText.body(15).copyWith(color: AppColors.smoke),
          border: InputBorder.none,
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _submitButton() {
    final enabled = _textController.text.trim().isNotEmpty;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: enabled ? _submit : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          disabledBackgroundColor: AppColors.gold.withValues(alpha: 0.3),
          foregroundColor: AppColors.obsidian,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        child: Text(
          AppLocalizations.of(context)!.sendWishButton,
          style: AppText.button().copyWith(color: AppColors.obsidian),
        ),
      ),
    );
  }

  Widget _statusText(String text) => Text(
    text,
    textAlign: TextAlign.center,
    style: AppText.caption(12).copyWith(color: AppColors.ash),
  );
}

enum _CameraError { none, noCamera, openFailed }

class _RuneOverlay extends StatefulWidget {
  const _RuneOverlay();

  @override
  State<_RuneOverlay> createState() => _RuneOverlayState();
}

class _RuneOverlayState extends State<_RuneOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => Transform.rotate(
          angle: _controller.value * 6.28,
          child: SizedBox(
            width: 280,
            height: 280,
            child: CustomPaint(painter: _RunePainter()),
          ),
        ),
      ),
    );
  }
}

class _RunePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = AppColors.gold.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawCircle(center, size.width * 0.45, paint);
    canvas.drawCircle(
      center,
      size.width * 0.35,
      paint..color = AppColors.gold.withValues(alpha: 0.25),
    );

    final inner = Paint()
      ..color = AppColors.gold.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    const sides = 8;
    for (var i = 0; i < sides; i++) {
      final angle = (i / sides) * 6.28;
      final p1 =
          center +
          Offset(
            size.width * 0.45 * cos(angle),
            size.height * 0.45 * sin(angle),
          );
      final p2 =
          center +
          Offset(
            size.width * 0.35 * cos(angle + 0.39),
            size.height * 0.35 * sin(angle + 0.39),
          );
      canvas.drawLine(p1, p2, inner);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
