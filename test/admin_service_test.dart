import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:cosmic_wish/services/admin_service.dart';

void main() {
  group('AdminService', () {
    test('login stores token and sends it on later requests', () async {
      late Map<String, dynamic> requestBody;
      late Map<String, String> requestHeaders;
      final mock = MockClient((req) async {
        requestBody = jsonDecode(utf8.decode(req.bodyBytes));
        requestHeaders = req.headers;
        if (requestBody['action'] == 'login') {
          return http.Response.bytes(
            utf8.encode('{"token":"v1.123.sig","expiresAt":9999999999999}'),
            200,
          );
        }
        return http.Response.bytes(
          utf8.encode(
            '{"mode":"fallback","baseUrl":"https://api.minimax.io/v1/chat/completions",'
            '"model":"MiniMax-M2.7","apiKeyMasked":"••••abcd"}',
          ),
          200,
        );
      });
      final service = AdminService(client: mock);

      expect(service.isLoggedIn, isFalse);
      await service.login('correct-password');
      expect(service.isLoggedIn, isTrue);

      final config = await service.getConfig();
      expect(config.mode, 'fallback');
      expect(config.model, 'MiniMax-M2.7');
      expect(config.apiKeyMasked, '••••abcd');
      expect(requestBody['action'], 'get-config');
      expect(requestHeaders['Authorization'], 'Bearer v1.123.sig');
    });

    test('wrong password surfaces AdminException', () async {
      final mock = MockClient(
        (req) async => http.Response.bytes(
          utf8.encode('{"error":"invalid-password"}'),
          401,
        ),
      );
      final service = AdminService(client: mock);
      await expectLater(
        service.login('wrong'),
        throwsA(
          isA<AdminException>().having((e) => e.code, 'code', 'invalid-password'),
        ),
      );
      expect(service.isLoggedIn, isFalse);
    });

    test('expired token on an authed action throws AdminAuthException', () async {
      final mock = MockClient(
        (req) async => http.Response.bytes(
          utf8.encode('{"error":"invalid-token"}'),
          401,
        ),
      );
      final service = AdminService(client: mock);
      await expectLater(
        service.getConfig(),
        throwsA(isA<AdminAuthException>()),
      );
    });

    test('save-config omits blank apiKey (keep stored key)', () async {
      late Map<String, dynamic> requestBody;
      final mock = MockClient((req) async {
        requestBody = jsonDecode(utf8.decode(req.bodyBytes));
        return http.Response.bytes(utf8.encode('{"ok":true}'), 200);
      });
      final service = AdminService(client: mock);

      await service.saveConfig(
        baseUrl: 'https://openrouter.ai/api/v1/chat/completions',
        model: 'anthropic/claude-sonnet-4.5',
        apiKey: '   ',
      );

      expect(requestBody['action'], 'save-config');
      expect(requestBody.containsKey('apiKey'), isFalse);
      expect(requestBody['model'], 'anthropic/claude-sonnet-4.5');
    });

    test('test-connection parses ok outcome', () async {
      final mock = MockClient(
        (req) async => http.Response.bytes(
          utf8.encode(
            '{"ok":true,"latencyMs":840,"replyPreview":"pong","model":"gpt-4o-mini"}',
          ),
          200,
        ),
      );
      final service = AdminService(client: mock);
      final result = await service.testConnection();

      expect(result.ok, isTrue);
      expect(result.latencyMs, 840);
      expect(result.replyPreview, 'pong');
    });

    test('test-connection parses failed outcome with status', () async {
      // A failed upstream test is a *successful* admin call — the
      // outcome envelope comes back with HTTP 200 and ok:false.
      final mock = MockClient((req) async {
        final body = jsonDecode(utf8.decode(req.bodyBytes));
        if (body['action'] == 'test-connection') {
          return http.Response.bytes(
            utf8.encode('{"ok":false,"latencyMs":120,"status":401,"error":"bad key"}'),
            200,
          );
        }
        return http.Response.bytes(utf8.encode('{"token":"v1.1.x"}'), 200);
      });
      final service = AdminService(client: mock);
      await service.login('pw');
      final result = await service.testConnection();

      expect(result.ok, isFalse);
      expect(result.status, 401);
      expect(result.error, 'bad key');
    });

    test('backend error codes map to AdminException with code', () async {
      final mock = MockClient(
        (req) async => http.Response.bytes(
          utf8.encode('{"error":"rate-limit-exceeded"}'),
          429,
        ),
      );
      final service = AdminService(client: mock);
      await expectLater(
        service.resetConfig(),
        throwsA(
          isA<AdminException>().having((e) => e.code, 'code', 'rate-limit-exceeded'),
        ),
      );
    });
  });
}
