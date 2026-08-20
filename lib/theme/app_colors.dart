import 'package:flutter/material.dart';

/// Antique, low-saturation cosmic palette.
class AppColors {
  AppColors._();

  static const Color obsidian = Color(0xFF050208);
  static const Color cosmos = Color(0xFF0B0612);
  static const Color midnight = Color(0xFF12091F);
  static const Color plum = Color(0xFF1B1028);

  static const Color gold = Color(0xFFB89968);
  static const Color goldDark = Color(0xFF8C7146);
  static const Color goldDeep = Color(0xFF8C7146);
  static const Color goldWhisper = Color(0xFFD8C39A);

  static const Color parchment = Color(0xFFE8E1D4);
  static const Color ash = Color(0xFF9C9488);
  static const Color smoke = Color(0xFF6E6760);

  static const Color categoryAccent = gold;

  static const LinearGradient cosmicGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[obsidian, cosmos, midnight, plum],
    stops: <double>[0.0, 0.35, 0.7, 1.0],
  );
}
