import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../l10n/gen/app_localizations.dart';
import '../state/app_state.dart';
import '../state/update_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/floating_anonymous_wishes.dart';
import '../widgets/starfield_background.dart';
import '../widgets/mystic_button.dart';
import '../widgets/mystical_glyph.dart';
import '../widgets/update_prompt.dart';
import 'category_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<AppState>(
        builder: (context, appState, _) {
          return StarfieldBackground(
            starCount: appState.starCount,
            twinkleSpeed: appState.animationSpeed,
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final w = constraints.maxWidth;
                  final h = constraints.maxHeight;
                  final logoSize = (w * 0.70).clamp(180.0, 320.0);
                  final maxContent = (h * 0.86).clamp(0.0, h);

                  return Stack(
                    children: [
                      const Positioned.fill(child: FloatingAnonymousWishes()),
                      const Positioned.fill(child: UpdatePrompt()),
                      _topBar(context),
                      Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: 480),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxHeight: maxContent),
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 24,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(height: 32),
                                  _Logo(size: logoSize),
                                  const SizedBox(height: 28),
                                  Text(
                                    AppLocalizations.of(context)!.appTitle,
                                    style: AppText.display(),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    width: 48,
                                    height: 1,
                                    color: AppColors.gold.withValues(
                                      alpha: 0.4,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    AppLocalizations.of(context)!.homeTagline,
                                    textAlign: TextAlign.center,
                                    style: AppText.body(
                                      15,
                                    ).copyWith(color: AppColors.ash),
                                  ),
                                  const SizedBox(height: 48),
                                  MysticButton(
                                    label: AppLocalizations.of(
                                      context,
                                    )!.startButton,
                                    semanticLabel: AppLocalizations.of(
                                      context,
                                    )!.startButton,
                                    onPressed: () {
                                      if (appState.hapticsEnabled) {
                                        HapticFeedback.selectionClick();
                                      }
                                      Navigator.of(context).push(
                                        PageRouteBuilder(
                                          pageBuilder: (_, _, _) =>
                                              const CategoryScreen(),
                                          transitionsBuilder:
                                              (_, anim, _, child) =>
                                                  FadeTransition(
                                                    opacity: anim,
                                                    child: child,
                                                  ),
                                          transitionDuration: const Duration(
                                            milliseconds: 600,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 32),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _topBar(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final hasUpdate = context.watch<UpdateState>().availableUpdate != null;
    return Positioned(
      top: 8,
      right: 8,
      child: Row(
        children: [
          _iconBtn(
            icon: Icons.history,
            tooltip: l.historyTooltip,
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const HistoryScreen())),
          ),
          _iconBtn(
            icon: Icons.tune,
            tooltip: l.settingsTooltip,
            badge: hasUpdate,
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
    );
  }

  Widget _iconBtn({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    bool badge = false,
  }) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      icon: badge
          ? Badge(
              isLabelVisible: false,
              smallSize: 8,
              backgroundColor: AppColors.gold,
              offset: const Offset(3, -3),
              child: Icon(icon, color: AppColors.ash, size: 20),
            )
          : Icon(icon, color: AppColors.ash, size: 20),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return MysticalGlyph(size: size);
  }
}
