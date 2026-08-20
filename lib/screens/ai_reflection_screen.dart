import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/gen/app_localizations.dart';
import '../models/wish_session.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/mystic_button.dart';
import '../widgets/starfield_background.dart';
import 'loading_screen.dart';

/// The bridge between the two AI turns. This is intentionally separate from
/// the history reflection screen, which records a follow-up days later.
class AiReflectionScreen extends StatefulWidget {
  const AiReflectionScreen({super.key, required this.session});

  final WishSession session;

  @override
  State<AiReflectionScreen> createState() => _AiReflectionScreenState();
}

class _AiReflectionScreenState extends State<AiReflectionScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _continue() {
    final answer = _controller.text.trim();
    if (answer.isEmpty) {
      final l = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.aiReflectionRequired)));
      return;
    }
    widget.session.reflectionAnswer = answer;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, _, _) => LoadingScreen(session: widget.session),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 700),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      body: StarfieldBackground(
        starCount: appState.starCount,
        twinkleSpeed: appState.animationSpeed,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 26),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 18),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          tooltip: l.close,
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(
                            Icons.close,
                            color: AppColors.parchment,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        l.aiReflectionEyebrow,
                        textAlign: TextAlign.center,
                        style: AppText.caption(
                          12,
                        ).copyWith(color: AppColors.gold, letterSpacing: 1.7),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        widget.session.reflectionQuestion ?? '',
                        textAlign: TextAlign.center,
                        style: AppText.heading(21).copyWith(height: 1.5),
                      ),
                      const SizedBox(height: 28),
                      TextField(
                        controller: _controller,
                        minLines: 3,
                        maxLines: 6,
                        maxLength: 500,
                        autofocus: true,
                        style: AppText.body(15),
                        decoration: InputDecoration(
                          hintText: l.aiReflectionHint,
                          filled: true,
                          fillColor: AppColors.cosmos.withValues(alpha: 0.55),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide(
                              color: AppColors.gold.withValues(alpha: 0.35),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide(
                              color: AppColors.gold.withValues(alpha: 0.35),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      MysticButton(
                        label: l.aiReflectionCta,
                        expand: true,
                        onPressed: _continue,
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
