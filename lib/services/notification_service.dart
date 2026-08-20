import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService();

  static const _channelId = 'cosmic_wish_daily';
  static const _channelName = 'Daily Cosmic Wish';
  static const _channelDesc = 'Nhắc nhở gửi điều ước mỗi ngày';

  // Distinct channel for wish-response countdowns so users can mute
  // them independently from the daily reminder.
  static const _responseChannelId = 'cosmic_wish_response';
  static const _responseChannelName = 'Phản hồi điều ước';
  static const _responseChannelDesc =
      'Thông báo khi vũ trụ hồi đáp điều ước của bạn';

  // Channel for "the universe releases your wish" — a more poetic,
  // lower-importance notice when a wish's 30-day lifetime ends.
  static const _releaseChannelId = 'cosmic_wish_release';
  static const _releaseChannelName = 'Giải phóng điều ước';
  static const _releaseChannelDesc = 'Vũ trụ giải phóng điều ước khi hết hạn';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  Future<void>? _initFuture;

  Future<void> init() async {
    if (_initialized) return;
    // Coalesce concurrent init() calls so two screens calling init()
    // at the same time only run setup once. Without this guard, the
    // second caller can see `_initialized = true` (set early) but the
    // plugin not yet ready, then call cancel() and get a late-init
    // error from the platform channel.
    if (_initFuture != null) return _initFuture!;
    _initFuture = _doInit();
    return _initFuture;
  }

  Future<void> _doInit() async {
    try {
      tz.initializeTimeZones();
      final localTimezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTimezone.identifier));
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const initSettings = InitializationSettings(android: androidSettings);
      await _plugin.initialize(settings: initSettings);

      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await androidPlugin?.requestNotificationsPermission();
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDesc,
          importance: Importance.defaultImportance,
        ),
      );
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          _responseChannelId,
          _responseChannelName,
          description: _responseChannelDesc,
          importance: Importance.high,
        ),
      );
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          _releaseChannelId,
          _releaseChannelName,
          description: _releaseChannelDesc,
          importance: Importance.defaultImportance,
        ),
      );
      _initialized = true;
    } catch (e) {
      _initialized = false;
      _initFuture = null;
      debugPrint('NotificationService init failed: $e');
    }
  }

  Future<void> scheduleDaily({required int hour, required int minute}) async {
    try {
      await init();
      await cancelDaily();
      final now = tz.TZDateTime.now(tz.local);
      var scheduled = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );
      if (scheduled.isBefore(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }
      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      );
      await _plugin.zonedSchedule(
        id: 0,
        title: 'Vũ trụ đang lắng nghe...',
        body: 'Hãy dành một chút tĩnh lặng để gửi điều ước hôm nay.',
        scheduledDate: scheduled,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint('scheduleDaily failed: $e');
    }
  }

  Future<void> cancelDaily() async {
    try {
      await _plugin.cancel(id: 0);
    } catch (e) {
      debugPrint('cancelDaily failed: $e');
    }
  }

  /// Schedule a one-shot notification for when the universe "responds"
  /// to a wish. Each entry uses a stable int id derived from the entry
  /// id so the notification can be cancelled/updated later.
  Future<void> scheduleResponseCountdown({
    required int id,
    required String title,
    required String body,
    required DateTime when,
  }) async {
    try {
      await init();
      final scheduled = tz.TZDateTime.from(when, tz.local);
      final details = const NotificationDetails(
        android: AndroidNotificationDetails(
          _responseChannelId,
          _responseChannelName,
          channelDescription: _responseChannelDesc,
          importance: Importance.high,
          priority: Priority.high,
        ),
      );
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduled,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (e) {
      debugPrint('scheduleResponseCountdown failed: $e');
    }
  }

  Future<void> cancelResponseCountdown(int id) async {
    try {
      // cancel() can throw LateInitializationError if init() hasn't
      // run yet (e.g. test that removes an entry before scheduling
      // any notification). Make sure init completes first.
      await init();
      await _plugin.cancel(id: id);
    } catch (e) {
      debugPrint('cancelResponseCountdown failed: $e');
    }
  }

  /// Schedule the "the universe has released your wish" notification
  /// for when a wish reaches its 30-day lifetime. We use a different
  /// id range from response countdowns (offset by 0x40000000) to
  /// avoid collisions in the underlying platform's id space.
  Future<void> scheduleExpiry({
    required int baseId,
    required String title,
    required String body,
    required DateTime when,
  }) async {
    try {
      await init();
      final scheduled = tz.TZDateTime.from(when, tz.local);
      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          _releaseChannelId,
          _releaseChannelName,
          channelDescription: _releaseChannelDesc,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      );
      await _plugin.zonedSchedule(
        id: 0x40000000 | (baseId & 0x3fffffff),
        title: title,
        body: body,
        scheduledDate: scheduled,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (e) {
      debugPrint('scheduleExpiry failed: $e');
    }
  }

  Future<void> cancelExpiry(int baseId) async {
    try {
      await init();
      await _plugin.cancel(id: 0x40000000 | (baseId & 0x3fffffff));
    } catch (e) {
      debugPrint('cancelExpiry failed: $e');
    }
  }

  /// Stable int id for a given string entry id, so we can call
  /// `cancelResponseCountdown(entry.idHash)` later.
  static int idForEntry(String entryId) {
    // 32-bit signed range; collision acceptable for this use case.
    return entryId.hashCode & 0x7fffffff;
  }
}
