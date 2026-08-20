import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/gen/app_localizations.dart';
import '../models/wish_history_entry.dart';
import '../services/reflection_prompt_service.dart';
import '../state/app_state.dart';
import '../state/history_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/mystic_button.dart';
import '../widgets/starfield_background.dart';

/// Full-screen reflection flow shown from history (and from the home
/// nudge). Lets the user write a short note, pick a mood, and report
/// whether the wish is coming true.
class ReflectionScreen extends StatefulWidget {
  const ReflectionScreen({super.key, required this.entry});

  final WishHistoryEntry entry;

  @override
  State<ReflectionScreen> createState() => _ReflectionScreenState();
}

class _ReflectionScreenState extends State<ReflectionScreen> {
  late final TextEditingController _noteController;
  WishMood _mood = WishMood.unknown;
  WishOutcome _outcome = WishOutcome.unknown;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: widget.entry.reflectionNote);
    _mood = widget.entry.mood;
    _outcome = widget.entry.outcome;
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final historyState = context.read<HistoryState>();
    final l = AppLocalizations.of(context)!;
    final note = _noteController.text.trim();
    await historyState.saveReflection(
      id: widget.entry.id,
      reflectionNote: note.isEmpty ? null : note,
      mood: _mood,
      outcome: _outcome,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l.reflectSaved)));
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final appState = context.watch<AppState>();
    final prompt = ReflectionPromptService().promptFor(
      Localizations.localeOf(context).languageCode,
    );
    return Scaffold(
      body: StarfieldBackground(
        starCount: appState.starCount,
        twinkleSpeed: appState.animationSpeed,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                Row(
                  children: [
                    IconButton(
                      tooltip: l.close,
                      icon: const Icon(Icons.close, color: AppColors.parchment),
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                    const Spacer(),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  l.reflectTitle,
                  style: AppText.heading(22),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  prompt,
                  textAlign: TextAlign.center,
                  style: AppText.body(14).copyWith(
                    fontStyle: FontStyle.italic,
                    color: AppColors.goldWhisper,
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _noteController,
                          minLines: 4,
                          maxLines: 8,
                          maxLength: 500,
                          style: AppText.body(15),
                          decoration: InputDecoration(
                            hintText: l.reflectNoteHint,
                            hintStyle: AppText.body(15).copyWith(
                              color: AppColors.parchment.withValues(alpha: 0.4),
                            ),
                            filled: true,
                            fillColor: AppColors.cosmos.withValues(alpha: 0.5),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide: BorderSide(
                                color: AppColors.gold.withValues(alpha: 0.3),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide: BorderSide(
                                color: AppColors.gold.withValues(alpha: 0.3),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(l.reflectMoodLabel, style: AppText.caption(13)),
                        const SizedBox(height: 8),
                        _MoodChips(
                          selected: _mood,
                          onChanged: (m) => setState(() => _mood = m),
                        ),
                        const SizedBox(height: 24),
                        Text(l.reflectOutcomeLabel, style: AppText.caption(13)),
                        const SizedBox(height: 8),
                        _OutcomeChips(
                          selected: _outcome,
                          onChanged: (o) => setState(() => _outcome = o),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 24, top: 8),
                  child: MysticButton(
                    label: _saving ? '…' : l.reflectSave,
                    expand: true,
                    onPressed: _saving ? null : _save,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MoodChips extends StatelessWidget {
  const _MoodChips({required this.selected, required this.onChanged});

  final WishMood selected;
  final ValueChanged<WishMood> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final choices = <(WishMood, String)>[
      (WishMood.hopeful, l.moodHopeful),
      (WishMood.peaceful, l.moodPeaceful),
      (WishMood.grateful, l.moodGrateful),
      (WishMood.restless, l.moodRestless),
      (WishMood.sad, l.moodSad),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final (mood, label) in choices)
          _Chip(
            label: label,
            selected: selected == mood,
            onTap: () => onChanged(selected == mood ? WishMood.unknown : mood),
          ),
      ],
    );
  }
}

class _OutcomeChips extends StatelessWidget {
  const _OutcomeChips({required this.selected, required this.onChanged});

  final WishOutcome selected;
  final ValueChanged<WishOutcome> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final choices = <(WishOutcome, String)>[
      (WishOutcome.fulfilled, l.outcomeFulfilled),
      (WishOutcome.partial, l.outcomePartial),
      (WishOutcome.unfulfilled, l.outcomeUnfulfilled),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final (outcome, label) in choices)
          _Chip(
            label: label,
            selected: selected == outcome,
            onTap: () =>
                onChanged(selected == outcome ? WishOutcome.unknown : outcome),
          ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.gold.withValues(alpha: 0.25)
              : AppColors.cosmos.withValues(alpha: 0.5),
          border: Border.all(
            color: selected
                ? AppColors.gold
                : AppColors.gold.withValues(alpha: 0.3),
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: AppText.body(13).copyWith(
            color: selected ? AppColors.goldWhisper : AppColors.parchment,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
