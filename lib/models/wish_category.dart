import 'package:flutter/material.dart';
import '../l10n/gen/app_localizations.dart';
import '../theme/app_colors.dart';

/// All categories share the same antique accent. The visual differentiation
/// is the glyph + the localized label only.
enum WishCategory {
  love(icon: Icons.favorite_outline, glyph: 'I'),
  career(icon: Icons.work_outline, glyph: 'II'),
  health(icon: Icons.health_and_safety_outlined, glyph: 'III'),
  family(icon: Icons.diversity_3_outlined, glyph: 'IV'),
  other(icon: Icons.grain, glyph: 'V');

  const WishCategory({required this.icon, required this.glyph});

  final IconData icon;
  final String glyph;

  /// Localized label — pass the AppLocalizations instance from a
  /// BuildContext. Centralised here so callers don't have to know
  /// which ARB key maps to which enum value.
  String label(AppLocalizations l) {
    switch (this) {
      case WishCategory.love:
        return l.categoryLove;
      case WishCategory.career:
        return l.categoryCareer;
      case WishCategory.health:
        return l.categoryHealth;
      case WishCategory.family:
        return l.categoryFamily;
      case WishCategory.other:
        return l.categoryOther;
    }
  }

  String description(AppLocalizations l) {
    switch (this) {
      case WishCategory.love:
        return l.categoryLoveDesc;
      case WishCategory.career:
        return l.categoryCareerDesc;
      case WishCategory.health:
        return l.categoryHealthDesc;
      case WishCategory.family:
        return l.categoryFamilyDesc;
      case WishCategory.other:
        return l.categoryOtherDesc;
    }
  }

  /// Shared accent. All categories use the same antique gold.
  Color get color => AppColors.categoryAccent;
}
