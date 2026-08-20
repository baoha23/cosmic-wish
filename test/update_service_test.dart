import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:cosmic_wish/services/update_service.dart';

void main() {
  group('AppRelease', () {
    test('parses a release row', () {
      final r = AppRelease.fromJson({
        'version_code': 2,
        'version_name': '1.2.0',
        'apk_url': 'https://example.com/app.apk',
        'notes': 'Bug fixes',
      });
      expect(r.versionCode, 2);
      expect(r.versionName, '1.2.0');
      expect(r.apkUrl, 'https://example.com/app.apk');
      expect(r.notes, 'Bug fixes');
    });

    test('tolerates missing optional fields', () {
      final r = AppRelease.fromJson({'version_code': 3});
      expect(r.notes, isNull);
      expect(r.versionName, '');
    });
  });

  group('fetchLatestUpdate', () {
    test('returns release when version_code is newer', () async {
      final mock = MockClient(
        (req) async => http.Response.bytes(
          utf8.encode(
            '[{"version_code":5,"version_name":"1.2.0",'
            '"apk_url":"https://x/app.apk","notes":null}]',
          ),
          200,
        ),
      );
      final service = UpdateService(client: mock, anonKey: "test-anon-key");
      final r = await service.fetchLatestUpdate(currentVersionCode: 2);
      expect(r, isNotNull);
      expect(r!.versionCode, 5);
    });

    test('returns null when already up to date', () async {
      final mock = MockClient(
        (req) async => http.Response.bytes(
          utf8.encode('[{"version_code":2,"version_name":"1.1.0",'
              '"apk_url":"https://x/app.apk"}]'),
          200,
        ),
      );
      final service = UpdateService(client: mock, anonKey: "test-anon-key");
      expect(await service.fetchLatestUpdate(currentVersionCode: 2), isNull);
    });

    test('returns null on empty table', () async {
      final mock = MockClient(
        (req) async => http.Response.bytes(utf8.encode('[]'), 200),
      );
      final service = UpdateService(client: mock, anonKey: "test-anon-key");
      expect(await service.fetchLatestUpdate(currentVersionCode: 1), isNull);
    });

    test('returns null on malformed JSON', () async {
      final mock = MockClient(
        (req) async => http.Response.bytes(utf8.encode('not json'), 200),
      );
      final service = UpdateService(client: mock, anonKey: "test-anon-key");
      expect(await service.fetchLatestUpdate(currentVersionCode: 1), isNull);
    });

    test('returns null on server error', () async {
      final mock = MockClient(
        (req) async => http.Response.bytes(utf8.encode('boom'), 500),
      );
      final service = UpdateService(client: mock, anonKey: "test-anon-key");
      expect(await service.fetchLatestUpdate(currentVersionCode: 1), isNull);
    });

    test('returns null on network failure', () async {
      final mock = MockClient((req) async => throw Exception('refused'));
      final service = UpdateService(client: mock, anonKey: "test-anon-key");
      expect(await service.fetchLatestUpdate(currentVersionCode: 1), isNull);
    });

    test('returns null without making a request when anon key empty', () async {
      var requested = false;
      final mock = MockClient((req) async {
        requested = true;
        return http.Response.bytes(utf8.encode('[]'), 200);
      });
      final service = UpdateService(client: mock, anonKey: "");
      expect(await service.fetchLatestUpdate(currentVersionCode: 1), isNull);
      expect(requested, isFalse);
    });
  });

  group('UpdateDownloadException', () {
    test('carries its message', () {
      const e = UpdateDownloadException('Tải về thất bại.');
      expect(e.toString(), 'Tải về thất bại.');
    });
  });
}
