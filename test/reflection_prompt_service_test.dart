import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:cosmic_wish/services/reflection_prompt_service.dart';

void main() {
  group('ReflectionPromptService', () {
    test('returns a non-empty Vietnamese prompt', () {
      final svc = ReflectionPromptService(random: Random(42));
      final p = svc.promptFor('vi');
      expect(p, isNotEmpty);
      expect(p.length, greaterThan(8));
    });

    test('returns a non-empty English prompt for non-vi locales', () {
      final svc = ReflectionPromptService(random: Random(42));
      final p = svc.promptFor('en');
      expect(p, isNotEmpty);
      expect(p.length, greaterThan(8));
    });

    test('system locale falls through to English', () {
      final svc = ReflectionPromptService(random: Random(1));
      final p = svc.promptFor('system');
      expect(p, isNotEmpty);
    });

    test(
      'different calls (with high iteration) can return different prompts',
      () {
        final svc = ReflectionPromptService(random: Random(0));
        final seen = <String>{};
        for (var i = 0; i < 30; i++) {
          seen.add(svc.promptFor('vi'));
        }
        // Pool has 7 prompts; with 30 draws we should hit > 1.
        expect(seen.length, greaterThan(1));
      },
    );
  });
}
