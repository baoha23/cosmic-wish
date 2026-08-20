import 'package:flutter/foundation.dart';
import '../services/notification_service.dart';
import '../services/settings_service.dart';

class AppState extends ChangeNotifier {
  AppState({
    SettingsService? settingsService,
    NotificationService? notificationService,
  }) : _settings = settingsService ?? SettingsService(),
       _notifications = notificationService ?? NotificationService() {
    _loadFuture = _load();
  }

  final SettingsService _settings;
  final NotificationService _notifications;
  late final Future<void> _loadFuture;

  String _locale = 'system';
  bool _soundEnabled = true;
  bool _hapticsEnabled = true;
  int _starCount = 200;
  double _animationSpeed = 1.0;
  bool _dailyReminderEnabled = false;
  int _reminderHour = 20;
  int _reminderMinute = 0;
  bool _loaded = false;
  bool _shareAnonymousWishes = false;

  bool get soundEnabled => _soundEnabled;
  bool get hapticsEnabled => _hapticsEnabled;
  int get starCount => _starCount;
  double get animationSpeed => _animationSpeed;
  bool get dailyReminderEnabled => _dailyReminderEnabled;
  int get reminderHour => _reminderHour;
  int get reminderMinute => _reminderMinute;
  String get locale => _locale;
  bool get isLoaded => _loaded;
  bool get shareAnonymousWishes => _shareAnonymousWishes;

  Future<void> _load() async {
    _soundEnabled = await _settings.getSoundEnabled();
    _hapticsEnabled = await _settings.getHapticsEnabled();
    _starCount = await _settings.getStarCount();
    _animationSpeed = await _settings.getAnimationSpeed();
    _dailyReminderEnabled = await _settings.getDailyReminderEnabled();
    _reminderHour = await _settings.getReminderHour();
    _reminderMinute = await _settings.getReminderMinute();
    _locale = await _settings.getLocale();
    _shareAnonymousWishes = await _settings.getShareAnonymousWishes();
    _loaded = true;
    notifyListeners();
  }

  Future<void> setSoundEnabled(bool value) async {
    await _loadFuture;
    if (_soundEnabled == value) return;
    _soundEnabled = value;
    notifyListeners();
    await _settings.setSoundEnabled(value);
  }

  Future<void> setHapticsEnabled(bool value) async {
    await _loadFuture;
    if (_hapticsEnabled == value) return;
    _hapticsEnabled = value;
    notifyListeners();
    await _settings.setHapticsEnabled(value);
  }

  Future<void> setStarCount(int value) async {
    await _loadFuture;
    if (_starCount == value) return;
    _starCount = value;
    notifyListeners();
    await _settings.setStarCount(value);
  }

  Future<void> setAnimationSpeed(double value) async {
    await _loadFuture;
    if (_animationSpeed == value) return;
    _animationSpeed = value;
    notifyListeners();
    await _settings.setAnimationSpeed(value);
  }

  Future<void> setDailyReminderEnabled(bool value) async {
    await _loadFuture;
    if (_dailyReminderEnabled == value) return;
    _dailyReminderEnabled = value;
    notifyListeners();
    await _settings.setDailyReminderEnabled(value);
    if (value) {
      await _notifications.scheduleDaily(
        hour: _reminderHour,
        minute: _reminderMinute,
      );
    } else {
      await _notifications.cancelDaily();
    }
  }

  Future<void> setReminderTime(int hour, int minute) async {
    await _loadFuture;
    if (_reminderHour == hour && _reminderMinute == minute) return;
    _reminderHour = hour;
    _reminderMinute = minute;
    notifyListeners();
    await _settings.setReminderHour(hour);
    await _settings.setReminderMinute(minute);
    if (_dailyReminderEnabled) {
      await _notifications.scheduleDaily(hour: hour, minute: minute);
    }
  }

  Future<void> setLocale(String value) async {
    await _loadFuture;
    if (_locale == value) return;
    _locale = value;
    notifyListeners();
    await _settings.setLocale(value);
  }

  Future<void> setShareAnonymousWishes(bool value) async {
    await _loadFuture;
    if (_shareAnonymousWishes == value) return;
    _shareAnonymousWishes = value;
    notifyListeners();
    await _settings.setShareAnonymousWishes(value);
  }
}
