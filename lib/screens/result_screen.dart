import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../l10n/gen/app_localizations.dart';
import '../models/wish_session.dart';
import '../services/anonymous_wishes_service.dart';
import '../services/audio_service.dart';
import '../services/notification_service.dart';
import '../state/app_state.dart';
import '../state/history_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/countdown_label.dart';
import '../widgets/starfield_background.dart';
import '../widgets/mystic_button.dart';
import 'home_screen.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key, required this.session});

  final WishSession session;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final _audio = AudioService();
  final _notifications = NotificationService();
  DateTime? _notifyAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _saveAndPlay();
    });
  }

  Future<void> _saveAndPlay() async {
    final appState = context.read<AppState>();
    final historyState = context.read<HistoryState>();
    final l = AppLocalizations.of(context)!;
    if (appState.soundEnabled) {
      await _audio.playChime();
    }
    final response = widget.session.response;
    if (response == null || response.text.isEmpty) return;

    // Roll a random 7-30 day countdown and persist it on the entry.
    final countdown = historyState.service.rollCountdown();
    final notifyAt = DateTime.now().add(countdown);
    final entry = await historyState.addEntry(
      category: widget.session.category,
      transcript: widget.session.transcript,
      response: response.text,
      notifyAt: notifyAt,
    );
    if (mounted) setState(() => _notifyAt = entry.notifyAt);

    // Schedule the system notification for when the universe responds.
    final notifId = NotificationService.idForEntry(entry.id);
    await _notifications.scheduleResponseCountdown(
      id: notifId,
      title: l.notifResponseTitle,
      body: l.notifResponseBody,
      when: notifyAt,
    );

    // Schedule the farewell notification for when the wish is released.
    final expiresAt = entry.expiresAt;
    if (expiresAt.isAfter(DateTime.now())) {
      await _notifications.scheduleExpiry(
        baseId: notifId,
        title: l.notifFarewellTitle,
        body: l.notifFarewellBody,
        when: expiresAt,
      );
    }

    // Best-effort: share this wish anonymously so others can see it
    // floating in the cosmos. Errors are swallowed inside the service.
    if (appState.shareAnonymousWishes) {
      final anonymous = AnonymousWishesService();
      try {
        await anonymous.share(
          category: entry.category,
          transcript: widget.session.transcript,
        );
      } finally {
        anonymous.dispose();
      }
    }
  }

  @override
  void dispose() {
    _audio.dispose();
    super.dispose();
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
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final iconSize = (w * 0.18).clamp(60.0, 96.0);
              return Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 32,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight - 200,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 16),
                            _Glyph(size: iconSize),
                            const SizedBox(height: 28),
                            Text(
                              l.wishEngravedHeader,
                              textAlign: TextAlign.center,
                              style: AppText.heading(20),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              width: 48,
                              height: 1,
                              color: AppColors.gold.withValues(alpha: 0.4),
                            ),
                            if (_notifyAt != null) ...[
                              const SizedBox(height: 20),
                              CountdownLabel(
                                target: _notifyAt!,
                                style: AppText.body(
                                  14,
                                ).copyWith(color: AppColors.goldWhisper),
                              ),
                            ],
                            const SizedBox(height: 32),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: AppColors.cosmos.withValues(alpha: 0.5),
                                border: Border.all(
                                  color: AppColors.gold.withValues(alpha: 0.3),
                                ),
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: Text(
                                widget.session.response != null &&
                                        widget.session.response!.text.isNotEmpty
                                    ? widget.session.response!.text
                                    : l.wishNotRecorded,
                                style: AppText.prophecy(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(28, 8, 28, 24),
                    child: MysticButton(
                      label: l.returnHome,
                      semanticLabel: l.returnHome,
                      expand: true,
                      onPressed: () {
                        if (appState.hapticsEnabled) {
                          HapticFeedback.selectionClick();
                        }
                        Navigator.of(context).pushAndRemoveUntil(
                          PageRouteBuilder(
                            pageBuilder: (_, _, _) => const HomeScreen(),
                            transitionsBuilder: (_, anim, _, child) =>
                                FadeTransition(opacity: anim, child: child),
                            transitionDuration: const Duration(
                              milliseconds: 600,
                            ),
                          ),
                          (_) => false,
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Glyph extends StatelessWidget {
  const _Glyph({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.cosmos.withValues(alpha: 0.5),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Icon(
        Icons.brightness_2_outlined,
        color: AppColors.gold,
        size: size * 0.46,
      ),
    );
  }
}
