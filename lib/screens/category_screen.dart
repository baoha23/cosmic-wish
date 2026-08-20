import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../l10n/gen/app_localizations.dart';
import '../models/wish_category.dart';
import '../models/wish_session.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/starfield_background.dart';
import '../widgets/mystic_button.dart';
import 'preparation_screen.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  WishCategory? _selected;

  void _confirm() {
    if (_selected == null) return;
    if (context.read<AppState>().hapticsEnabled) {
      HapticFeedback.selectionClick();
    }
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, _, _) =>
            PreparationScreen(session: WishSession(category: _selected!)),
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      body: Consumer<AppState>(
        builder: (context, appState, _) {
          return StarfieldBackground(
            starCount: appState.starCount,
            twinkleSpeed: appState.animationSpeed,
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _header(),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      itemCount: WishCategory.values.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final c = WishCategory.values[i];
                        return _Card(
                          category: c,
                          l: l,
                          isSelected: _selected == c,
                          onTap: () {
                            if (appState.hapticsEnabled) {
                              HapticFeedback.selectionClick();
                            }
                            setState(() => _selected = c);
                          },
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: MysticButton(
                      label: AppLocalizations.of(context)!.continueButton,
                      semanticLabel: AppLocalizations.of(
                        context,
                      )!.continueButton,
                      expand: true,
                      onPressed: _selected != null ? _confirm : null,
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

  Widget _header() {
    final l = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.selectCategoryHeader, style: AppText.heading(22)),
          const SizedBox(height: 6),
          Text(l.selectCategorySub, style: AppText.caption(14)),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.category,
    required this.l,
    required this.isSelected,
    required this.onTap,
  });

  final WishCategory category;
  final AppLocalizations l;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.midnight.withValues(alpha: 0.9)
              : AppColors.cosmos.withValues(alpha: 0.6),
          border: Border.all(
            color: isSelected
                ? AppColors.gold
                : AppColors.goldDeep.withValues(alpha: 0.3),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected
                      ? AppColors.gold
                      : AppColors.goldDeep.withValues(alpha: 0.5),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Text(
                category.glyph,
                style: AppText.heading(15).copyWith(
                  color: isSelected ? AppColors.goldWhisper : AppColors.ash,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    category.label(l),
                    style: AppText.heading(16).copyWith(
                      color: isSelected
                          ? AppColors.goldWhisper
                          : AppColors.parchment,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(category.description(l), style: AppText.caption(13)),
                ],
              ),
            ),
            if (isSelected)
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.gold,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
