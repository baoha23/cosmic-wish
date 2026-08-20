import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Typography tuned for legibility on a dark cosmic background.
///
/// Uses the platform default font so diacritics render reliably without
/// requiring a network-fetched font. The system font (Roboto on Android,
/// SF Pro on iOS, Segoe UI on Windows) supports Vietnamese and falls back
/// gracefully on any device.
class AppText {
  AppText._();

  static const String _family = 'Roboto';

  static TextStyle display() => const TextStyle(
    fontFamily: _family,
    fontSize: 32,
    fontWeight: FontWeight.w500,
    color: AppColors.parchment,
    letterSpacing: 0.5,
    height: 1.2,
  );

  static TextStyle title() => const TextStyle(
    fontFamily: _family,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.goldWhisper,
    letterSpacing: 1.2,
    height: 1.25,
  );

  static TextStyle heading(double size) => TextStyle(
    fontFamily: _family,
    fontSize: size,
    fontWeight: FontWeight.w500,
    color: AppColors.parchment,
    letterSpacing: 0.3,
    height: 1.3,
  );

  static TextStyle body(double size, {Color? color}) => TextStyle(
    fontFamily: _family,
    fontSize: size,
    fontWeight: FontWeight.w400,
    color: color ?? AppColors.parchment,
    height: 1.5,
  );

  static TextStyle caption(double size) => TextStyle(
    fontFamily: _family,
    fontSize: size,
    fontWeight: FontWeight.w400,
    color: AppColors.ash,
    height: 1.4,
  );

  static TextStyle button() => const TextStyle(
    fontFamily: _family,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.goldWhisper,
    letterSpacing: 1.5,
    height: 1.0,
  );

  static TextStyle prophecy() => const TextStyle(
    fontFamily: _family,
    fontSize: 18,
    fontStyle: FontStyle.italic,
    fontWeight: FontWeight.w400,
    color: AppColors.goldWhisper,
    height: 1.7,
    letterSpacing: 0.2,
  );
}
