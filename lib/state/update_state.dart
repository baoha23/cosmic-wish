import 'package:flutter/foundation.dart';
import '../services/settings_service.dart';
import '../services/update_service.dart';

/// Holds the pending update, if any. The check runs silently on
/// construction (same pattern as [AppState]); a failure just means
/// "no update".
class UpdateState extends ChangeNotifier {
  UpdateState({UpdateService? service, SettingsService? settings})
    : _service = service ?? UpdateService(),
      _settings = settings ?? SettingsService() {
    _check();
  }

  final UpdateService _service;
  final SettingsService _settings;

  /// The service behind this state (download/install flows reuse it).
  UpdateService get service => _service;

  AppRelease? _availableUpdate;
  int _skippedVersionCode = 0;

  /// The newest release newer than this build, or null when up to
  /// date (or the check couldn't run).
  AppRelease? get availableUpdate => _availableUpdate;

  /// Whether the update dialog should auto-prompt: an update exists
  /// and the user hasn't skipped that versionCode.
  bool get shouldPrompt =>
      _availableUpdate != null &&
      _availableUpdate!.versionCode != _skippedVersionCode;

  Future<void> _check() async {
    try {
      _skippedVersionCode = await _settings.getSkippedVersionCode();
      final current = await _service.currentVersionCode();
      final release = await _service.fetchLatestUpdate(
        currentVersionCode: current,
      );
      if (release != null) {
        _availableUpdate = release;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[UPDATE] state check error: $e');
    }
  }

  /// Manual check from Settings. Returns the release even when it was
  /// previously skipped ([force] bypasses the skip flag).
  Future<AppRelease?> checkForUpdate({bool force = false}) async {
    final current = await _service.currentVersionCode();
    final release = await _service.fetchLatestUpdate(
      currentVersionCode: current,
    );
    if (release != null) {
      _availableUpdate = release;
      if (force) _skippedVersionCode = 0;
      notifyListeners();
    }
    return release;
  }

  /// Stops auto-prompting for the current available release.
  Future<void> skipCurrentRelease() async {
    final release = _availableUpdate;
    if (release == null) return;
    _skippedVersionCode = release.versionCode;
    await _settings.setSkippedVersionCode(release.versionCode);
    notifyListeners();
  }
}
