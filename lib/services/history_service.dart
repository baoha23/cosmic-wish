import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/wish_category.dart';
import '../models/wish_history_entry.dart';

class HistoryService {
  HistoryService({Random? random}) : _random = random ?? Random();

  final Random _random;

  static const _key = 'cosmic_wish_history_v1';
  static const _maxEntries = 50;
  static const minCountdownDays = 7;
  static const maxCountdownDays = 30;
  static const wishLifetime = Duration(days: 30);

  /// Generate a unique id combining timestamp with a random suffix so
  /// two entries created in the same millisecond don't collide.
  String _newId() {
    final ts = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    final suffix = _random.nextInt(1 << 24).toRadixString(36).padLeft(5, '0');
    return '$ts-$suffix';
  }

  Duration rollCountdown() {
    final span = maxCountdownDays - minCountdownDays + 1;
    final days = minCountdownDays + _random.nextInt(span);
    return Duration(days: days);
  }

  Future<List<WishHistoryEntry>> loadAll({bool pruneExpired = true}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.isEmpty) return [];
      final list = jsonDecode(raw) as List<dynamic>;
      final all = list
          .map((e) => WishHistoryEntry.fromJson(e as Map<String, dynamic>))
          .toList();
      final active = pruneExpired
          ? all.where((e) => !e.isExpired).toList()
          : all;
      active.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      if (pruneExpired && active.length != all.length) {
        // Only persist the pruned list when at least 3 entries have
        // expired since the last prune — avoids a write on every app
        // open when the user has just a few stale entries trickling out.
        final expiredCount = all.length - active.length;
        if (expiredCount >= 3 || active.length > _maxEntries) {
          await _save(active);
        }
      }
      return active;
    } catch (_) {
      return [];
    }
  }

  Future<WishHistoryEntry> add({
    required WishCategory category,
    required String transcript,
    required String response,
    DateTime? notifyAt,
    DateTime? expiresAt,
    DateTime? timestamp,
  }) async {
    final entries = await loadAll();
    final now = DateTime.now();
    final ts = timestamp ?? now;
    final entry = WishHistoryEntry(
      id: _newId(),
      category: category,
      transcript: transcript,
      response: response,
      timestamp: ts,
      notifyAt: notifyAt,
      expiresAt: expiresAt ?? ts.add(wishLifetime),
    );
    entries.insert(0, entry);
    if (entries.length > _maxEntries) {
      entries.removeRange(_maxEntries, entries.length);
    }
    await _save(entries);
    return entry;
  }

  /// Insert a batch of entries in a single read+write. Used by
  /// `BackupService.importFromFile` so importing N entries is O(n)
  /// instead of O(n²) reads/writes.
  Future<int> insertAll(Iterable<WishHistoryEntry> incoming) async {
    final existing = await loadAll();
    final existingIds = existing.map((e) => e.id).toSet();
    final fresh = <WishHistoryEntry>[];
    final freshIds = <String>{};
    for (final raw in incoming) {
      if (existingIds.contains(raw.id)) continue;
      if (raw.isExpired) continue;
      // Re-stamp id & timestamp to avoid collision after merge.
      final newId = _newId();
      fresh.add(
        WishHistoryEntry(
          id: newId,
          category: raw.category,
          transcript: raw.transcript,
          response: raw.response,
          timestamp: raw.timestamp,
          notifyAt: raw.notifyAt,
          expiresAt: raw.expiresAt,
          reflectionNote: raw.reflectionNote,
          reflectionAt: raw.reflectionAt,
          mood: raw.mood,
          outcome: raw.outcome,
        ),
      );
      freshIds.add(newId);
      existingIds.add(raw.id);
    }
    if (fresh.isEmpty) return 0;
    final merged = [...fresh, ...existing];
    merged.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    if (merged.length > _maxEntries) {
      merged.removeRange(_maxEntries, merged.length);
    }
    await _save(merged);
    return merged.where((e) => freshIds.contains(e.id)).length;
  }

  Future<void> remove(String id) async {
    final entries = await loadAll();
    entries.removeWhere((e) => e.id == id);
    await _save(entries);
  }

  /// Update an existing entry's reflection fields in place. No-op if
  /// the id is not found. Returns the updated entry, or null.
  Future<WishHistoryEntry?> saveReflection({
    required String id,
    String? reflectionNote,
    WishMood mood = WishMood.unknown,
    WishOutcome outcome = WishOutcome.unknown,
  }) async {
    final entries = await loadAll();
    final idx = entries.indexWhere((e) => e.id == id);
    if (idx < 0) return null;
    final existing = entries[idx];
    final updated = existing.copyWith(
      reflectionNote: reflectionNote,
      clearReflectionNote: reflectionNote == null,
      reflectionAt: DateTime.now(),
      mood: mood,
      outcome: outcome,
    );
    entries[idx] = updated;
    await _save(entries);
    return updated;
  }

  /// Entries older than [minAge] that the user hasn't reflected on yet.
  /// Used by the daily reflection reminder / nudge UI.
  Future<List<WishHistoryEntry>> entriesNeedingReflection({
    Duration minAge = const Duration(days: 3),
    Duration maxAge = const Duration(days: 25),
  }) async {
    final entries = await loadAll();
    final now = DateTime.now();
    return entries.where((e) {
      if (e.hasReflection) return false;
      final age = now.difference(e.timestamp);
      return age >= minAge && age <= maxAge;
    }).toList();
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  Future<void> _save(List<WishHistoryEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(entries.map((e) => e.toJson()).toList());
    await prefs.setString(_key, json);
  }
}
