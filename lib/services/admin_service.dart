import 'dart:async';
import 'dart:convert';
import 'dart:io' show SocketException;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/supabase_config.dart';

/// Thrown when the admin token is missing, expired or invalid.
/// The caller should send the user back to the login screen.
class AdminAuthException implements Exception {
  const AdminAuthException();
  @override
  String toString() => 'Phiên đăng nhập đã hết hạn.';
}

/// Thrown for any other admin backend failure. [code] is the edge
/// function's machine-readable error for specific UI messaging.
class AdminException implements Exception {
  const AdminException(this.message, {this.code});
  final String message;
  final String? code;
  @override
  String toString() => message;
}

/// Current AI provider config as reported by the backend.
class AdminConfig {
  const AdminConfig({
    required this.mode,
    required this.baseUrl,
    required this.model,
    required this.apiKeyMasked,
    this.updatedAt,
  });

  /// "database" when a config row exists, "fallback" when the backend
  /// is running on env defaults.
  final String mode;
  final String baseUrl;
  final String model;
  final String? apiKeyMasked;
  final String? updatedAt;

  factory AdminConfig.fromJson(Map<String, dynamic> json) => AdminConfig(
    mode: json['mode'] as String? ?? 'fallback',
    baseUrl: json['baseUrl'] as String? ?? '',
    model: json['model'] as String? ?? '',
    apiKeyMasked: json['apiKeyMasked'] as String?,
    updatedAt: json['updatedAt'] as String?,
  );
}

/// Result of a test-connection call against the configured provider.
class AdminTestResult {
  const AdminTestResult({
    required this.ok,
    required this.latencyMs,
    this.status,
    this.error,
    this.replyPreview,
  });

  final bool ok;
  final int latencyMs;
  final int? status;
  final String? error;
  final String? replyPreview;

  factory AdminTestResult.fromJson(Map<String, dynamic> json) =>
      AdminTestResult(
        ok: json['ok'] == true,
        latencyMs: (json['latencyMs'] as num?)?.toInt() ?? 0,
        status: (json['status'] as num?)?.toInt(),
        error: json['error'] as String?,
        replyPreview: json['replyPreview'] as String?,
      );
}

/// Talks to the `admin` Edge Function: password login, provider
/// config read/write, live connection test. The session token is
/// held in memory only — restarting the app requires logging in
/// again, by design.
class AdminService {
  AdminService({this.baseUrl = SupabaseConfig.adminUrl, http.Client? client})
    : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  String? _token;

  static const _callTimeout = Duration(seconds: 20);

  /// A test call can include a cold-started upstream model, so it
  /// gets a longer budget than regular actions.
  static const _testTimeout = Duration(seconds: 30);

  bool get isLoggedIn => _token != null;

  void dispose() => _client.close();

  Future<Map<String, dynamic>> _request(
    Map<String, dynamic> body, {
    Duration timeout = _callTimeout,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=utf-8',
      if (SupabaseConfig.anonKey.isNotEmpty) 'apikey': SupabaseConfig.anonKey,
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
    final r = await _client
        .post(
          Uri.parse(baseUrl),
          headers: headers,
          body: utf8.encode(jsonEncode(body)),
        )
        .timeout(timeout);
    Map<String, dynamic> data;
    try {
      data = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
    } on FormatException {
      data = const {};
    }
    // login's own 401 means "wrong password", not "bad token" — the
    // caller (login) re-maps it below.
    if (r.statusCode == 401 && body['action'] != 'login') {
      if (_token != null) _token = null;
      throw const AdminAuthException();
    }
    // test-connection reports a failed upstream test as HTTP 200 with
    // {ok:false, error}; that's a successful admin call, not a server
    // error. Anything else with an `error` field (or non-200) is one.
    final isTestOutcome =
        body['action'] == 'test-connection' && data['ok'] != null;
    if (r.statusCode != 200 || (!isTestOutcome && data['error'] != null)) {
      final code = data['error'] as String?;
      throw AdminException(
        'Lỗi từ máy chủ${code != null ? ' ($code)' : ''}.',
        code: code,
      );
    }
    return data;
  }

  /// Exchange the admin password for a 30-minute session token.
  Future<void> login(String password) async {
    try {
      final data = await _request({'action': 'login', 'password': password});
      _token = data['token'] as String?;
    } on TimeoutException {
      throw const AdminException('Máy chủ phản hồi chậm. Thử lại sau.');
    } on SocketException {
      throw const AdminException('Không có kết nối mạng.');
    } on http.ClientException catch (e) {
      throw AdminException('Không thể kết nối máy chủ. ${e.message}');
    } on AdminAuthException {
      // The edge function returns 401 for a wrong password.
      throw const AdminException(
        'Mật khẩu không đúng.',
        code: 'invalid-password',
      );
    } on AdminException {
      rethrow;
    } catch (e) {
      debugPrint('[ADMIN] unexpected login error: $e');
      throw const AdminException('Không thể đăng nhập. Thử lại sau.');
    }
  }

  Future<AdminConfig> getConfig() async {
    final data = await _request({'action': 'get-config'});
    return AdminConfig.fromJson(data);
  }

  /// Saves provider settings. A blank [apiKey] keeps the stored one.
  Future<void> saveConfig({
    required String baseUrl,
    required String model,
    String? apiKey,
  }) async {
    await _request({
      'action': 'save-config',
      'baseUrl': baseUrl,
      'model': model,
      if (apiKey != null && apiKey.trim().isNotEmpty) 'apiKey': apiKey.trim(),
    });
  }

  /// Fires one tiny real chat completion against [baseUrl]/[model]
  /// (or the saved config when null) and reports the outcome.
  Future<AdminTestResult> testConnection({
    String? baseUrl,
    String? model,
    String? apiKey,
  }) async {
    final data = await _request({
      'action': 'test-connection',
      if (baseUrl != null && baseUrl.trim().isNotEmpty)
        'baseUrl': baseUrl.trim(),
      if (model != null && model.trim().isNotEmpty) 'model': model.trim(),
      if (apiKey != null && apiKey.trim().isNotEmpty) 'apiKey': apiKey.trim(),
    }, timeout: _testTimeout);
    return AdminTestResult.fromJson(data);
  }

  /// Deletes the config row; the backend returns to env defaults.
  Future<void> resetConfig() async {
    await _request({'action': 'reset-config'});
  }
}
