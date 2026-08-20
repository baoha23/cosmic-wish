import 'package:flutter/foundation.dart';

enum LogLevel { debug, info, warn, error }

class AppLogger {
  AppLogger();

  static const _enabled = kDebugMode;
  static final AppLogger _instance = AppLogger();
  static AppLogger get instance => _instance;

  void log(
    String message, {
    LogLevel level = LogLevel.info,
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!_enabled && level == LogLevel.debug) return;
    final ts = DateTime.now().toIso8601String();
    final tagStr = tag != null ? '[$tag] ' : '';
    final errStr = error != null ? ' | error: $error' : '';
    final out = '$ts ${level.name.toUpperCase()} $tagStr$message$errStr';
    if (level == LogLevel.error) {
      debugPrint(out);
      if (stackTrace != null) debugPrint(stackTrace.toString());
    } else {
      debugPrint(out);
    }
  }

  void debug(String message, {String? tag}) =>
      log(message, level: LogLevel.debug, tag: tag);
  void info(String message, {String? tag}) =>
      log(message, level: LogLevel.info, tag: tag);
  void warn(String message, {String? tag, Object? error}) =>
      log(message, level: LogLevel.warn, tag: tag, error: error);
  void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) => log(
    message,
    level: LogLevel.error,
    tag: tag,
    error: error,
    stackTrace: stackTrace,
  );
}
