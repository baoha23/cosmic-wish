import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/gen/app_localizations.dart';
import '../models/wish_history_entry.dart';
import '../state/app_state.dart';
import '../state/history_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/countdown_label.dart';
import '../widgets/mystic_button.dart';
import '../widgets/starfield_background.dart';
import 'reflection_screen.dart';

/// Read-only detail view for a single [WishHistoryEntry]. Mirrors the
/// visual mood of the result screen but doesn't schedule notifications
/// or mutate the entry.
class HistoryDetailScreen extends StatelessWidget {
  const HistoryDetailScreen({super.key, required this.entry});

  final WishHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final entries = context.watch<HistoryState>().entries;
    final entry = entries.firstWhere(
      (candidate) => candidate.id == this.entry.id,
      orElse: () => this.entry,
    );
    return Scaffold(
      body: StarfieldBackground(
        starCount: 180,
        twinkleSpeed: context.watch<AppState>().animationSpeed,
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(28, 16, 28, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _Glyph(size: 72),
                      const SizedBox(height: 24),
                      Text(
                        entry.category.label(l),
                        textAlign: TextAlign.center,
                        style: AppText.heading(
                          18,
                        ).copyWith(color: entry.category.color),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatTimestamp(entry.timestamp),
                        style: AppText.body(12).copyWith(
                          color: AppColors.parchment.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: 48,
                        height: 1,
                        color: AppColors.gold.withValues(alpha: 0.4),
                      ),
                      if (entry.notifyAt != null) ...[
                        const SizedBox(height: 20),
                        CountdownLabel(
                          target: entry.notifyAt!,
                          style: AppText.body(
                            14,
                          ).copyWith(color: AppColors.goldWhisper),
                        ),
                      ],
                      if (entry.transcript.isNotEmpty) ...[
                        const SizedBox(height: 28),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            AppLocalizations.of(context)!.wishLabel,
                            style: AppText.caption(13).copyWith(
                              color: AppColors.ash,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.cosmos.withValues(alpha: 0.5),
                            border: Border.all(
                              color: entry.category.color.withValues(
                                alpha: 0.3,
                              ),
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Text(
                            '"${entry.transcript}"',
                            style: AppText.body(
                              15,
                            ).copyWith(color: AppColors.parchment),
                          ),
                        ),
                      ],
                      const SizedBox(height: 28),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          AppLocalizations.of(context)!.prophecy,
                          style: AppText.caption(13).copyWith(
                            color: AppColors.ash,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
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
                        child: Text(entry.response, style: AppText.prophecy()),
                      ),
                      const SizedBox(height: 28),
                      _ReflectionBlock(entry: entry),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime t) {
    return '${t.day.toString().padLeft(2, '0')}/${t.month.toString().padLeft(2, '0')}/${t.year} '
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildTopBar(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(
        children: [
          IconButton(
            tooltip: l.close,
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, color: AppColors.parchment),
          ),
          const Spacer(),
          Text(
            l.wishDetail,
            style: AppText.body(
              14,
            ).copyWith(color: AppColors.parchment.withValues(alpha: 0.85)),
          ),
          const Spacer(),
          const SizedBox(width: 48),
        ],
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

class _ReflectionBlock extends StatelessWidget {
  const _ReflectionBlock({required this.entry});
  final WishHistoryEntry entry;

  String _moodLabel(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    switch (entry.mood) {
      case WishMood.hopeful:
        return l.moodHopeful;
      case WishMood.peaceful:
        return l.moodPeaceful;
      case WishMood.restless:
        return l.moodRestless;
      case WishMood.sad:
        return l.moodSad;
      case WishMood.grateful:
        return l.moodGrateful;
      case WishMood.unknown:
        return '—';
    }
  }

  String _outcomeLabel(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    switch (entry.outcome) {
      case WishOutcome.fulfilled:
        return l.outcomeFulfilled;
      case WishOutcome.partial:
        return l.outcomePartial;
      case WishOutcome.unfulfilled:
        return l.outcomeUnfulfilled;
      case WishOutcome.unknown:
        return '—';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    if (!entry.hasReflection) {
      return MysticButton(
        label: l.reflectNow,
        semanticLabel: l.reflectNow,
        expand: true,
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ReflectionScreen(entry: entry)),
          );
        },
      );
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.plum.withValues(alpha: 0.6),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: AppColors.gold, size: 16),
              const SizedBox(width: 8),
              Text(
                l.journeyReflected,
                style: AppText.caption(
                  13,
                ).copyWith(color: AppColors.goldWhisper, letterSpacing: 1.5),
              ),
              const Spacer(),
              InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ReflectionScreen(entry: entry),
                    ),
                  );
                },
                child: Text(
                  l.reflectNow,
                  style: AppText.caption(13).copyWith(color: AppColors.gold),
                ),
              ),
            ],
          ),
          if (entry.reflectionNote != null &&
              entry.reflectionNote!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              entry.reflectionNote!,
              style: AppText.body(15).copyWith(
                color: AppColors.parchment,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              _MetaPill(label: _moodLabel(context)),
              const SizedBox(width: 8),
              _MetaPill(label: _outcomeLabel(context)),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: AppText.caption(12).copyWith(color: AppColors.parchment),
      ),
    );
  }
}
