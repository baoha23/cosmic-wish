import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cosmic_wish/models/wish_category.dart';
import 'package:cosmic_wish/models/wish_history_entry.dart';
import 'package:cosmic_wish/services/history_service.dart';
import 'package:cosmic_wish/state/history_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('HistoryState', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('starts empty', () async {
      final state = HistoryState(service: HistoryService());
      await Future.delayed(const Duration(milliseconds: 50));
      expect(state.entries, isEmpty);
      expect(state.isEmpty, true);
      expect(state.isLoading, false);
    });

    test('addEntry inserts at front', () async {
      final state = HistoryState(service: HistoryService());
      await Future.delayed(const Duration(milliseconds: 50));
      await state.addEntry(
        category: WishCategory.love,
        transcript: 'Test 1',
        response: 'Response 1',
      );
      expect(state.entries.length, 1);
      expect(state.entries.first.transcript, 'Test 1');
    });

    test('remove deletes entry', () async {
      final service = HistoryService();
      await service.add(
        category: WishCategory.love,
        transcript: 'A',
        response: 'B',
      );
      final state = HistoryState(service: service);
      await Future.delayed(const Duration(milliseconds: 50));
      expect(state.entries.length, 1);
      final id = state.entries.first.id;
      await state.remove(id);
      expect(state.entries, isEmpty);
    });

    test('clear empties all', () async {
      final service = HistoryService();
      await service.add(
        category: WishCategory.love,
        transcript: 'A',
        response: 'B',
      );
      final state = HistoryState(service: service);
      await Future.delayed(const Duration(milliseconds: 50));
      await state.clear();
      expect(state.entries, isEmpty);
    });

    group('reflection flow', () {
      test('newly added entry has no reflection', () async {
        final state = HistoryState(service: HistoryService());
        await Future.delayed(const Duration(milliseconds: 50));
        final entry = await state.addEntry(
          category: WishCategory.career,
          transcript: 'wish',
          response: 'prophecy',
        );
        expect(entry.hasReflection, isFalse);
        expect(entry.reflectionAt, isNull);
        expect(entry.mood, WishMood.unknown);
        expect(entry.outcome, WishOutcome.unknown);
      });

      test('saveReflection updates entry in state', () async {
        final state = HistoryState(service: HistoryService());
        await Future.delayed(const Duration(milliseconds: 50));
        final entry = await state.addEntry(
          category: WishCategory.health,
          transcript: 'wish',
          response: 'prophecy',
        );
        final updated = await state.saveReflection(
          id: entry.id,
          reflectionNote: 'Đã thấy dấu hiệu nhỏ.',
          mood: WishMood.grateful,
          outcome: WishOutcome.partial,
        );
        expect(updated, isNotNull);
        expect(updated!.hasReflection, isTrue);
        expect(updated.reflectionNote, 'Đã thấy dấu hiệu nhỏ.');
        expect(updated.mood, WishMood.grateful);
        expect(updated.outcome, WishOutcome.partial);
        expect(updated.reflectionAt, isNotNull);
        // State reload — same entry is now reflected.
        final reloaded = state.entries.firstWhere((e) => e.id == entry.id);
        expect(reloaded.hasReflection, isTrue);
        expect(reloaded.mood, WishMood.grateful);
      });

      test('saveReflection can clear an existing note', () async {
        final state = HistoryState(service: HistoryService());
        await Future.delayed(const Duration(milliseconds: 50));
        final entry = await state.addEntry(
          category: WishCategory.other,
          transcript: 'wish',
          response: 'prophecy',
        );
        await state.saveReflection(id: entry.id, reflectionNote: 'Ghi chú cũ');

        await state.saveReflection(id: entry.id, reflectionNote: null);

        expect(state.entries.first.reflectionNote, isNull);
        expect(state.entries.first.hasReflection, isFalse);
      });

      test(
        'saveReflection with unknown mood/outcome strips hasReflection',
        () async {
          final state = HistoryState(service: HistoryService());
          await Future.delayed(const Duration(milliseconds: 50));
          final entry = await state.addEntry(
            category: WishCategory.family,
            transcript: 'wish',
            response: 'prophecy',
          );
          // First, set a mood.
          await state.saveReflection(id: entry.id, mood: WishMood.sad);
          expect(state.entries.first.hasReflection, isTrue);
          // Now clear mood and outcome; no note → hasReflection false.
          await state.saveReflection(
            id: entry.id,
            reflectionNote: null,
            mood: WishMood.unknown,
            outcome: WishOutcome.unknown,
          );
          expect(state.entries.first.hasReflection, isFalse);
        },
      );

      test('saveReflection returns null for unknown id', () async {
        final state = HistoryState(service: HistoryService());
        await Future.delayed(const Duration(milliseconds: 50));
        final r = await state.saveReflection(
          id: 'does-not-exist',
          mood: WishMood.hopeful,
        );
        expect(r, isNull);
      });

      test('entriesNeedingReflection respects age window', () async {
        final service = HistoryService();
        final now = DateTime.now();
        // 2-day-old entry: too fresh to reflect on.
        await service.add(
          category: WishCategory.love,
          transcript: 'fresh',
          response: 'r',
          timestamp: now.subtract(const Duration(days: 2)),
        );
        // 10-day-old entry: should appear.
        final mid = await service.add(
          category: WishCategory.career,
          transcript: 'mid',
          response: 'r',
          timestamp: now.subtract(const Duration(days: 10)),
        );
        // 10-day-old entry, already reflected: should be filtered out.
        await service.add(
          category: WishCategory.health,
          transcript: 'reflected',
          response: 'r',
          timestamp: now.subtract(const Duration(days: 10)),
        );
        await service.saveReflection(
          id: (await service.loadAll())
              .firstWhere((e) => e.transcript == 'reflected')
              .id,
          mood: WishMood.grateful,
        );
        // 40-day-old entry: too old (> 25 days), filtered out.
        await service.add(
          category: WishCategory.family,
          transcript: 'old',
          response: 'r',
          timestamp: now.subtract(const Duration(days: 40)),
        );
        final pending = await service.entriesNeedingReflection();
        expect(pending.length, 1);
        expect(pending.first.id, mid.id);
      });

      test('JSON roundtrip preserves reflection fields', () async {
        final service = HistoryService();
        final added = await service.add(
          category: WishCategory.love,
          transcript: 'wish',
          response: 'prophecy',
        );
        await service.saveReflection(
          id: added.id,
          reflectionNote: 'Ghi chú.',
          mood: WishMood.hopeful,
          outcome: WishOutcome.fulfilled,
        );
        final loaded = (await service.loadAll()).first;
        expect(loaded.reflectionNote, 'Ghi chú.');
        expect(loaded.mood, WishMood.hopeful);
        expect(loaded.outcome, WishOutcome.fulfilled);
        expect(loaded.reflectionAt, isNotNull);
      });

      test(
        'JSON roundtrip works on legacy entries without reflection',
        () async {
          // Simulate an entry saved before reflection fields existed —
          // should still parse cleanly with all fields defaulting to
          // unknown / null.
          SharedPreferences.setMockInitialValues({
            'cosmic_wish_history_v1':
                '[{'
                '"id":"legacy-1",'
                '"category":"love",'
                '"transcript":"x",'
                '"response":"y",'
                '"timestamp":"2026-06-01T10:00:00.000Z",'
                '"expiresAt":"2026-07-01T10:00:00.000Z"'
                '}]',
          });
          final service = HistoryService();
          final loaded = await service.loadAll(pruneExpired: false);
          expect(loaded, hasLength(1));
          expect(loaded.first.reflectionNote, isNull);
          expect(loaded.first.mood, WishMood.unknown);
          expect(loaded.first.outcome, WishOutcome.unknown);
          expect(loaded.first.hasReflection, isFalse);
        },
      );
    });
  });
}
