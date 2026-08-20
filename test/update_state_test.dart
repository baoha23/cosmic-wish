import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cosmic_wish/services/settings_service.dart';
import 'package:cosmic_wish/services/update_service.dart';
import 'package:cosmic_wish/state/update_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    PackageInfo.setMockInitialValues(
      appName: 'Cosmic Wish',
      packageName: 'com.cosmic.cosmic_wish',
      version: '1.1.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  UpdateService fakeService({int releaseCode = 5}) {
    final mock = MockClient(
      (req) async => http.Response.bytes(
        utf8.encode(
          '[{"version_code":$releaseCode,"version_name":"1.2.0",'
          '"apk_url":"https://x/app.apk","notes":null}]',
        ),
        200,
      ),
    );
    return UpdateService(client: mock, anonKey: 'test-anon-key');
  }

  test('silent check surfaces a newer release', () async {
    SharedPreferences.setMockInitialValues({});
    final state = UpdateState(
      service: fakeService(releaseCode: 5),
      settings: SettingsService(),
    );
    // The constructor-launched check is fire-and-forget; pump the
    // microtask queue until the release appears (or fail on timeout).
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(state.availableUpdate?.versionCode, 5);
    expect(state.shouldPrompt, isTrue);
  });

  test('shouldPrompt is false for a skipped release', () async {
    SharedPreferences.setMockInitialValues({'skipped_version_code': 5});
    final state = UpdateState(
      service: fakeService(releaseCode: 5),
      settings: SettingsService(),
    );
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(state.availableUpdate?.versionCode, 5);
    expect(state.shouldPrompt, isFalse);
  });

  test('skipCurrentRelease persists the versionCode', () async {
    SharedPreferences.setMockInitialValues({});
    final state = UpdateState(
      service: fakeService(releaseCode: 5),
      settings: SettingsService(),
    );
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(state.shouldPrompt, isTrue);

    await state.skipCurrentRelease();
    expect(state.shouldPrompt, isFalse);
    expect(await SettingsService().getSkippedVersionCode(), 5);
  });

  test('checkForUpdate(force) overrides the skip flag', () async {
    SharedPreferences.setMockInitialValues({'skipped_version_code': 5});
    final state = UpdateState(
      service: fakeService(releaseCode: 5),
      settings: SettingsService(),
    );
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(state.shouldPrompt, isFalse);

    final release = await state.checkForUpdate(force: true);
    expect(release?.versionCode, 5);
    expect(state.shouldPrompt, isTrue);
  });
}
