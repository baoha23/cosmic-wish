import 'package:flutter/foundation.dart';
import '../models/wish_category.dart';
import '../models/wish_history_entry.dart';
import '../services/backup_service.dart';
import '../services/history_service.dart';
import '../services/notification_service.dart';

class HistoryState extends ChangeNotifier {
  HistoryState({
    HistoryService? service,
    BackupService? backupService,
    NotificationService? notifications,
  }) : _service = service ?? HistoryService(),
       _backup = backupService ?? BackupService(),
       _notifications = notifications ?? NotificationService() {
    _load();
  }

  final HistoryService _service;
  final BackupService _backup;
  final NotificationService _notifications;

  /// Exposed so screens (e.g. ResultScreen) can roll countdown
  /// offsets using the same `Random` instance the service uses.
  HistoryService get service => _service;

  List<WishHistoryEntry> _entries = [];
  bool _loading = true;

  List<WishHistoryEntry> get entries => List.unmodifiable(_entries);
  bool get isLoading => _loading;
  bool get isEmpty => !_loading && _entries.isEmpty;

  Future<void> _load() async {
    _entries = await _service.loadAll();
    _loading = false;
    notifyListeners();
  }

  Future<void> reload() async {
    _loading = true;
    notifyListeners();
    await _load();
  }

  /// Save a new wish entry. Returns the entry so callers can schedule
  /// follow-up notifications keyed off the entry id.
  Future<WishHistoryEntry> addEntry({
    required WishCategory category,
    required String transcript,
    required String response,
    DateTime? notifyAt,
  }) async {
    final entry = await _service.add(
      category: category,
      transcript: transcript,
      response: response,
      notifyAt: notifyAt,
    );
    await reload();
    return entry;
  }

  Future<void> remove(String id) async {
    await _service.remove(id);
    final baseId = NotificationService.idForEntry(id);
    await _notifications.cancelResponseCountdown(baseId);
    await _notifications.cancelExpiry(baseId);
    await reload();
  }

  /// Record or update a reflection (note / mood / outcome) for a wish
  /// entry. Returns the updated entry, or null if the id wasn't found.
  Future<WishHistoryEntry?> saveReflection({
    required String id,
    String? reflectionNote,
    WishMood mood = WishMood.unknown,
    WishOutcome outcome = WishOutcome.unknown,
  }) async {
    final updated = await _service.saveReflection(
      id: id,
      reflectionNote: reflectionNote,
      mood: mood,
      outcome: outcome,
    );
    if (updated != null) await reload();
    return updated;
  }

  /// Returns up to [maxResults] entries that are old enough to reflect
  /// on but the user hasn't reflected yet. Used by the home-screen
  /// nudge.
  Future<List<WishHistoryEntry>> entriesNeedingReflection({
    int maxResults = 3,
  }) async {
    final all = await _service.entriesNeedingReflection();
    if (all.length <= maxResults) return all;
    return all.sublist(0, maxResults);
  }

  Future<void> clear() async {
    final old = List<WishHistoryEntry>.from(_entries);
    await _service.clear();
    for (final e in old) {
      final baseId = NotificationService.idForEntry(e.id);
      await _notifications.cancelResponseCountdown(baseId);
      await _notifications.cancelExpiry(baseId);
    }
    await reload();
  }

  Future<void> exportToFile() => _backup.exportAndShare();
  Future<int> importFromPicker() async {
    final n = await _backup.importFromPicker();
    if (n > 0) await reload();
    return n;
  }
}
