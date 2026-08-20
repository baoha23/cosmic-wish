import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cosmic_wish/services/settings_service.dart';
import 'package:cosmic_wish/state/app_state.dart';

void main() {
  group('AppState', () {
    late SettingsService settings;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      settings = SettingsService();
    });

    test('defaults match SettingsService defaults', () async {
      final state = AppState(settingsService: settings);
      await Future.delayed(const Duration(milliseconds: 50));
      expect(state.soundEnabled, true);
      expect(state.hapticsEnabled, true);
      expect(state.starCount, 200);
      expect(state.animationSpeed, 1.0);
      expect(state.shareAnonymousWishes, false);
      expect(state.isLoaded, true);
    });

    test('anonymous sharing is opt-in and persists', () async {
      final state = AppState(settingsService: settings);
      await Future.delayed(const Duration(milliseconds: 50));

      await state.setShareAnonymousWishes(true);

      expect(state.shareAnonymousWishes, true);
      expect(await settings.getShareAnonymousWishes(), true);
    });

    test('setSoundEnabled persists and notifies', () async {
      final state = AppState(settingsService: settings);
      await Future.delayed(const Duration(milliseconds: 50));
      var notified = 0;
      state.addListener(() => notified++);

      await state.setSoundEnabled(false);
      expect(state.soundEnabled, false);
      expect(notified, 1);
      expect(await settings.getSoundEnabled(), false);
    });

    test('setStarCount persists and notifies', () async {
      final state = AppState(settingsService: settings);
      await Future.delayed(const Duration(milliseconds: 50));
      var notified = 0;
      state.addListener(() => notified++);

      await state.setStarCount(350);
      expect(state.starCount, 350);
      expect(notified, 1);
      expect(await settings.getStarCount(), 350);
    });

    test('setAnimationSpeed persists and notifies', () async {
      final state = AppState(settingsService: settings);
      await Future.delayed(const Duration(milliseconds: 50));
      var notified = 0;
      state.addListener(() => notified++);

      await state.setAnimationSpeed(1.5);
      expect(state.animationSpeed, 1.5);
      expect(notified, 1);
      expect(await settings.getAnimationSpeed(), 1.5);
    });

    test('no-op updates do not notify', () async {
      final state = AppState(settingsService: settings);
      await Future.delayed(const Duration(milliseconds: 50));
      var notified = 0;
      state.addListener(() => notified++);

      await state.setSoundEnabled(true);
      expect(notified, 0);
    });
  });
}
