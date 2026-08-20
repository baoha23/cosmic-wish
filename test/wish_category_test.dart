import 'package:flutter_test/flutter_test.dart';
import 'package:cosmic_wish/models/wish_category.dart';
import 'package:cosmic_wish/models/wish_history_entry.dart';

void main() {
  group('WishHistoryEntry', () {
    test('roundtrip JSON preserves fields', () {
      final entry = WishHistoryEntry(
        id: '123',
        category: WishCategory.love,
        transcript: 'Em muốn tìm tình yêu',
        response: 'Trái tim ngươi sẽ tìm thấy',
        timestamp: DateTime.utc(2026, 1, 15, 10, 30),
      );
      final json = entry.toJson();
      final restored = WishHistoryEntry.fromJson(json);
      expect(restored.id, entry.id);
      expect(restored.category, entry.category);
      expect(restored.transcript, entry.transcript);
      expect(restored.response, entry.response);
      expect(restored.timestamp, entry.timestamp);
    });

    test('fromJson falls back to other for unknown category', () {
      final json = {
        'id': '456',
        'category': 'unknown',
        'transcript': '',
        'response': 'X',
        'timestamp': DateTime.utc(2026).toIso8601String(),
      };
      final entry = WishHistoryEntry.fromJson(json);
      expect(entry.category, WishCategory.other);
    });
  });
}
