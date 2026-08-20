import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  SettingsService();

  static const _kSoundEnabled = 'sound_enabled';
  static const _kHapticsEnabled = 'haptics_enabled';
  static const _kStarCount = 'star_count';
  static const _kAnimationSpeed = 'animation_speed';
  static const _kDailyReminderEnabled = 'daily_reminder_enabled';
  static const _kReminderHour = 'reminder_hour';
  static const _kReminderMinute = 'reminder_minute';
  static const _kLocale = 'locale';
  static const _kShareAnonymousWishes = 'share_anonymous_wishes';
  static const _kSkippedVersionCode = 'skipped_version_code';

  Future<bool> getSoundEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kSoundEnabled) ?? true;
  }

  Future<void> setSoundEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kSoundEnabled, value);
  }

  Future<bool> getHapticsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kHapticsEnabled) ?? true;
  }

  Future<void> setHapticsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kHapticsEnabled, value);
  }

  Future<int> getStarCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kStarCount) ?? 200;
  }

  Future<void> setStarCount(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kStarCount, value);
  }

  Future<double> getAnimationSpeed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_kAnimationSpeed) ?? 1.0;
  }

  Future<void> setAnimationSpeed(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kAnimationSpeed, value);
  }

  Future<bool> getDailyReminderEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kDailyReminderEnabled) ?? false;
  }

  Future<void> setDailyReminderEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kDailyReminderEnabled, value);
  }

  Future<int> getReminderHour() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kReminderHour) ?? 20;
  }

  Future<void> setReminderHour(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kReminderHour, value);
  }

  Future<int> getReminderMinute() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kReminderMinute) ?? 0;
  }

  Future<void> setReminderMinute(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kReminderMinute, value);
  }

  Future<String> getLocale() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kLocale) ?? 'system';
  }

  Future<void> setLocale(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLocale, value);
  }

  Future<bool> getShareAnonymousWishes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kShareAnonymousWishes) ?? false;
  }

  Future<void> setShareAnonymousWishes(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kShareAnonymousWishes, value);
  }

  /// Release versionCode the user chose to skip prompting for.
  /// 0 = nothing skipped.
  Future<int> getSkippedVersionCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kSkippedVersionCode) ?? 0;
  }

  Future<void> setSkippedVersionCode(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kSkippedVersionCode, value);
  }
}
