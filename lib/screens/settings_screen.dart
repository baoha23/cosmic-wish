import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import '../l10n/gen/app_localizations.dart';
import '../state/app_state.dart';
import '../state/update_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/starfield_background.dart';
import '../widgets/update_prompt.dart';
import 'admin_login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      body: Consumer<AppState>(
        builder: (context, appState, child) {
          if (!appState.isLoaded) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.gold),
            );
          }
          return StarfieldBackground(
            starCount: appState.starCount,
            twinkleSpeed: appState.animationSpeed,
            child: SafeArea(
              child: Column(
                children: [
                  _buildHeader(context, l.settings),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      children: [
                        _SectionHeader(l.soundEffects),
                        _SwitchTile(
                          title: l.soundEffects,
                          subtitle: l.soundEffectsSubtitle,
                          value: appState.soundEnabled,
                          onChanged: (v) {
                            if (appState.hapticsEnabled) {
                              HapticFeedback.lightImpact();
                            }
                            appState.setSoundEnabled(v);
                          },
                        ),
                        _SwitchTile(
                          title: l.haptics,
                          subtitle: l.hapticsSubtitle,
                          value: appState.hapticsEnabled,
                          onChanged: (v) {
                            if (v) HapticFeedback.mediumImpact();
                            appState.setHapticsEnabled(v);
                          },
                        ),
                        const SizedBox(height: 24),
                        _SectionHeader(l.effects),
                        _SliderTile(
                          title: l.starDensity,
                          value: appState.starCount.toDouble(),
                          min: 80,
                          max: 400,
                          divisions: 6,
                          suffix: '${appState.starCount}',
                          onChanged: (v) => appState.setStarCount(v.round()),
                        ),
                        _SliderTile(
                          title: l.animationSpeed,
                          value: appState.animationSpeed,
                          min: 0.5,
                          max: 2.0,
                          divisions: 6,
                          suffix:
                              '${appState.animationSpeed.toStringAsFixed(1)}x',
                          onChanged: (v) => appState.setAnimationSpeed(v),
                        ),
                        const SizedBox(height: 24),
                        _SectionHeader(l.reminder),
                        _SwitchTile(
                          title: l.dailyReminder,
                          subtitle: l.dailyReminderSubtitle,
                          value: appState.dailyReminderEnabled,
                          onChanged: (v) => appState.setDailyReminderEnabled(v),
                        ),
                        if (appState.dailyReminderEnabled)
                          _TimePickerTile(
                            label: l.reminderTime,
                            hour: appState.reminderHour,
                            minute: appState.reminderMinute,
                            onChanged: (h, m) => appState.setReminderTime(h, m),
                          ),
                        const SizedBox(height: 24),
                        _SectionHeader(l.language),
                        _LanguageTile(
                          currentLocale: appState.locale,
                          onChanged: appState.setLocale,
                        ),
                        const SizedBox(height: 24),
                        _SectionHeader(l.privacy),
                        _SwitchTile(
                          title: l.shareAnonymousWishes,
                          subtitle: l.shareAnonymousWishesSubtitle,
                          value: appState.shareAnonymousWishes,
                          onChanged: appState.setShareAnonymousWishes,
                        ),
                        const SizedBox(height: 24),
                        _UpdateCheckTile(),
                        const SizedBox(height: 24),
                        const _VersionFooter(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String title) {
    final l = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, color: AppColors.parchment),
            tooltip: l.back,
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: AppText.heading(20),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
      child: Text(
        title.toUpperCase(),
        style: AppText.body(
          12,
        ).copyWith(color: AppColors.gold, letterSpacing: 2),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.plum.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.plum.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.heading(16)),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppText.body(
                    13,
                  ).copyWith(color: AppColors.parchment.withValues(alpha: 0.5)),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.gold,
          ),
        ],
      ),
    );
  }
}

class _SliderTile extends StatelessWidget {
  const _SliderTile({
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.suffix,
    required this.onChanged,
  });

  final String title;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String suffix;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.plum.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.plum.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: AppText.heading(16))),
              Text(
                suffix,
                style: AppText.body(14).copyWith(color: AppColors.gold),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppColors.gold,
              inactiveTrackColor: AppColors.gold.withValues(alpha: 0.2),
              thumbColor: AppColors.goldWhisper,
              overlayColor: AppColors.gold.withValues(alpha: 0.2),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({required this.currentLocale, required this.onChanged});

  final String currentLocale;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.plum.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.plum.withValues(alpha: 0.3)),
      ),
      child: RadioGroup<String>(
        groupValue: currentLocale,
        onChanged: (value) {
          if (value != null) onChanged(value);
        },
        child: Column(
          children: [
            RadioListTile<String>(
              value: 'system',
              title: Text(l.languageSystem, style: AppText.heading(14)),
              subtitle: Text(
                l.languageSystemSub,
                style: AppText.body(
                  12,
                ).copyWith(color: AppColors.parchment.withValues(alpha: 0.5)),
              ),
              activeColor: AppColors.gold,
              contentPadding: EdgeInsets.zero,
            ),
            RadioListTile<String>(
              value: 'vi',
              title: Text(l.languageVietnamese, style: AppText.heading(14)),
              activeColor: AppColors.gold,
              contentPadding: EdgeInsets.zero,
            ),
            RadioListTile<String>(
              value: 'en',
              title: Text(l.languageEnglish, style: AppText.heading(14)),
              activeColor: AppColors.gold,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }
}

class _TimePickerTile extends StatelessWidget {
  const _TimePickerTile({
    required this.label,
    required this.hour,
    required this.minute,
    required this.onChanged,
  });

  final String label;
  final int hour;
  final int minute;
  final void Function(int hour, int minute) onChanged;

  @override
  Widget build(BuildContext context) {
    final timeStr =
        '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.plum.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.plum.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppText.heading(16))),
          TextButton(
            onPressed: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay(hour: hour, minute: minute),
                builder: (ctx, child) {
                  return Theme(
                    data: Theme.of(ctx).copyWith(
                      colorScheme: const ColorScheme.dark(
                        primary: AppColors.gold,
                        surface: AppColors.plum,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null) onChanged(picked.hour, picked.minute);
            },
            child: Text(
              timeStr,
              style: AppText.body(16).copyWith(color: AppColors.gold),
            ),
          ),
        ],
      ),
    );
  }
}

/// Quiet version footer. Tapping it 5 times in quick succession opens
/// the hidden admin console; no visual feedback before the fifth tap
/// so the entrance stays genuinely hidden.
class _VersionFooter extends StatefulWidget {
  const _VersionFooter();

  @override
  State<_VersionFooter> createState() => _VersionFooterState();
}

class _VersionFooterState extends State<_VersionFooter> {
  static const _tapsRequired = 5;
  static const _tapWindow = Duration(seconds: 3);

  String _version = '';
  int _taps = 0;
  DateTime _lastTap = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _version = 'Cosmic Wish v${info.version}');
    });
  }

  void _onTap() {
    final now = DateTime.now();
    if (now.difference(_lastTap) > _tapWindow) _taps = 0;
    _lastTap = now;
    _taps++;
    if (_taps < _tapsRequired) return;
    _taps = 0;
    HapticFeedback.mediumImpact();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Center(
          child: Text(
            _version,
            style: AppText.body(11).copyWith(color: AppColors.ash),
          ),
        ),
      ),
    );
  }
}

/// Manual "check for updates" row. A check that finds something (even
/// a previously skipped version) opens the update dialog; otherwise
/// a quiet snackbar confirms the app is current.
class _UpdateCheckTile extends StatefulWidget {
  @override
  State<_UpdateCheckTile> createState() => _UpdateCheckTileState();
}

class _UpdateCheckTileState extends State<_UpdateCheckTile> {
  bool _checking = false;

  Future<void> _check(AppLocalizations l) async {
    if (_checking) return;
    setState(() => _checking = true);
    try {
      final release = await context.read<UpdateState>().checkForUpdate(
            force: true,
          );
      if (!mounted) return;
      if (release != null) {
        showUpdateDialog(context);
      } else {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(l.updateUpToDate),
              backgroundColor: AppColors.plum,
            ),
          );
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.plum.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.plum.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Expanded(child: Text(l.updateCheckButton, style: AppText.heading(16))),
          if (_checking)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.gold,
              ),
            )
          else
            TextButton(
              onPressed: () => _check(l),
              child: Text(
                l.tryAgain,
                style: AppText.body(14).copyWith(color: AppColors.gold),
              ),
            ),
        ],
      ),
    );
  }
}
