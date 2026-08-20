import 'dart:async';
import 'dart:convert';
import 'dart:io' show SocketException;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/supabase_config.dart';
import '../models/wish_category.dart';
import '../models/wish_prophecy.dart';

export '../models/wish_prophecy.dart' show WishProphecy;

/// Thrown when the user submits an empty wish or the AI returns no
/// usable text. We deliberately do NOT fall back to any local pool —
/// the user opted in to hear from the AI specifically, so anything
/// else would be a lie.
class WishEmptyException implements Exception {
  const WishEmptyException();
  @override
  String toString() => 'Vũ trụ chưa nghe thấy gì. Hãy viết điều ước của bạn.';
}

/// Thrown when the AI proxy is unreachable, returns a non-200, or
/// returns something that doesn't look like a real prophecy. The
/// caller should show an error to the user — we never substitute a
/// local reply.
class WishProxyException implements Exception {
  const WishProxyException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Result of the first request. New backends ask one personalized question
/// before producing a prophecy; older deployments may return the prophecy
/// immediately, so both outcomes are supported during rollout.
class WishInitialResponse {
  const WishInitialResponse._({this.question, this.prophecy});

  const WishInitialResponse.question(String text) : this._(question: text);
  const WishInitialResponse.prophecy(WishProphecy value)
    : this._(prophecy: value);

  final String? question;
  final WishProphecy? prophecy;

  bool get needsReflection => question != null;
}

class WishService {
  WishService({
    this.proxyUrl = SupabaseConfig.generateWishUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String proxyUrl;
  final http.Client _client;

  /// Begin the two-turn ritual. A current backend returns a reflection
  /// question; a legacy single-turn backend is accepted and returns a
  /// prophecy directly.
  Future<WishInitialResponse> beginWish({
    required WishCategory category,
    required String transcript,
    String locale = 'vi',
  }) async {
    if (transcript.trim().isEmpty) throw const WishEmptyException();
    try {
      final data = await _request(
        category: category,
        transcript: transcript,
        locale: locale,
      );
      final text = _extractText(data);
      if (text == null || text.isEmpty || _looksLikeError(text)) {
        throw const WishProxyException(
          'Vũ trụ không hồi đáp. Hãy thử lại sau ít phút.',
        );
      }
      if (data['type'] == 'question') {
        return WishInitialResponse.question(text);
      }
      return WishInitialResponse.prophecy(WishProphecy(text: text));
    } on TimeoutException {
      throw const WishProxyException(
        'Vũ trụ hồi đáp chậm. Hãy thử lại sau ít phút.',
      );
    } on SocketException {
      throw const WishProxyException(
        'Không có kết nối mạng. Kiểm tra WiFi/data rồi thử lại.',
      );
    } on http.ClientException catch (e) {
      throw WishProxyException('Không thể kết nối với vũ trụ. ${e.message}');
    } on FormatException {
      throw const WishProxyException('Phản hồi từ vũ trụ bị lỗi. Hãy thử lại.');
    } catch (e) {
      if (e is WishEmptyException || e is WishProxyException) rethrow;
      throw const WishProxyException(
        'Không thể kết nối với vũ trụ. Kiểm tra mạng và thử lại.',
      );
    }
  }

  /// Send the wish to the upstream model. We do NOT fall back to
  /// any local pool — if the AI is unreachable or returns junk,
  /// we throw so the UI can show an error.
  Future<WishProphecy> generateProphecy({
    required WishCategory category,
    required String transcript,
    String? question,
    String? reflection,
    String locale = 'vi',
  }) async {
    if (transcript.trim().isEmpty) {
      throw const WishEmptyException();
    }
    try {
      final prophecy = await _callProxy(
        category: category,
        transcript: transcript,
        question: question,
        reflection: reflection,
        locale: locale,
      );
      debugPrint('[WISH] model returned ${prophecy.text.length} chars');
      if (prophecy.text.isEmpty || _looksLikeError(prophecy.text)) {
        throw const WishProxyException(
          'Vũ trụ không hồi đáp. Hãy thử lại sau ít phút.',
        );
      }
      return prophecy;
    } on TimeoutException {
      debugPrint('[WISH] timeout after ${_callTimeout.inSeconds}s');
      throw const WishProxyException(
        'Vũ trụ hồi đáp chậm. Hãy thử lại sau ít phút.',
      );
    } on SocketException catch (e) {
      debugPrint('[WISH] socket error: $e');
      throw const WishProxyException(
        'Không có kết nối mạng. Kiểm tra WiFi/data rồi thử lại.',
      );
    } on http.ClientException catch (e) {
      debugPrint('[WISH] client error: $e');
      throw WishProxyException('Không thể kết nối với vũ trụ. ${e.message}');
    } on FormatException catch (e) {
      debugPrint('[WISH] json parse error: $e');
      throw const WishProxyException('Phản hồi từ vũ trụ bị lỗi. Hãy thử lại.');
    } catch (e) {
      if (e is WishEmptyException) rethrow;
      if (e is WishProxyException) rethrow;
      debugPrint('[WISH] unexpected error: $e');
      throw WishProxyException(
        'Không thể kết nối với vũ trụ. Kiểm tra mạng và thử lại.',
      );
    }
  }

  /// Total time we wait for the backend to respond. Generous enough to
  /// cover both Supabase cold-start (5-15s) and a slow upstream model
  /// call (15-30s). The backend also aborts its upstream fetch at 30s
  /// so this never fires from a stuck server.
  static const _callTimeout = Duration(seconds: 45);

  Future<WishProphecy> _callProxy({
    required WishCategory category,
    required String transcript,
    String? question,
    String? reflection,
    String locale = 'vi',
  }) async {
    final data = await _request(
      category: category,
      transcript: transcript,
      question: question,
      reflection: reflection,
      locale: locale,
    );
    return _parseProphecy(data);
  }

  Future<Map<String, dynamic>> _request({
    required WishCategory category,
    required String transcript,
    String? question,
    String? reflection,
    String locale = 'vi',
  }) async {
    final uri = Uri.parse(proxyUrl);
    debugPrint(
      '[WISH] POST $uri category=${category.name} '
      'transcriptLen=${transcript.length}',
    );
    final r = await _client
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json; charset=utf-8',
            if (SupabaseConfig.anonKey.isNotEmpty) ...{
              'apikey': SupabaseConfig.anonKey,
              'Authorization': 'Bearer ${SupabaseConfig.anonKey}',
            },
          },
          body: utf8.encode(
            jsonEncode({
              'category': category.name,
              'transcript': transcript,
              'question': ?question,
              'reflection': ?reflection,
              'locale': locale == 'en' ? 'en' : 'vi',
            }),
          ),
        )
        .timeout(_callTimeout);
    if (r.statusCode != 200) {
      debugPrint('=== PROXY ERROR ${r.statusCode} ===');
      debugPrint('body: ${r.body.substring(0, r.body.length.clamp(0, 300))}');
      debugPrint('==========================');
      throw const WishProxyException(
        'Vũ trụ không hồi đáp. Hãy thử lại sau ít phút.',
      );
    }
    final data = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
    debugPrint('[WISH] proxy response status=200 bytes=${r.bodyBytes.length}');
    return data;
  }

  /// Build a [WishProphecy] from any backend response shape we know about:
  ///   - current:        { "text": "..." }
  ///   - older flat:     { "type": "prophecy", "text": "...", "source": "minimax" }
  ///   - legacy:         { "response": "..." }
  ///   - Anthropic:      { "content": [{"type": "text", "text": "..."}] }
  /// `text` is always populated when the response carries a real reply.
  WishProphecy _parseProphecy(Map<String, dynamic> data) {
    if (data['type'] == 'question') {
      throw const WishProxyException('Phản hồi chưa hoàn tất. Hãy thử lại.');
    }
    final text = _extractText(data);
    if (text == null || text.isEmpty) {
      return const WishProphecy(text: '');
    }
    return WishProphecy(text: text);
  }

  /// Accepts the various shapes the edge function has shipped over time:
  ///   - new (our code):    { "text": "..." }
  ///   - previous:          { "type": "prophecy", "text": "...", "source": "minimax" }
  ///   - legacy flat:       { "response": "..." }
  ///   - legacy Anthropic:  { "content": [{"type": "text", "text": "..."}] }
  /// All return the cleaned prophecy string, or null if nothing usable.
  String? _extractText(Map<String, dynamic> data) {
    // Try every known shape, in order of likelihood.
    final candidates = <String?>[
      data['text'] as String?,
      data['response'] as String?,
      _legacyExtract(data['content']),
      _legacyExtract(data['data']),
    ];
    for (final raw in candidates) {
      if (raw == null || raw.isEmpty) continue;
      final cleaned = _stripThinking(_fixEncoding(raw));
      if (cleaned.isNotEmpty) return cleaned;
    }
    return null;
  }

  String? _legacyExtract(dynamic raw) {
    if (raw == null) return null;
    if (raw is String) return raw;
    if (raw is List) {
      final parts = <String>[];
      for (final item in raw) {
        if (item is Map) {
          final type = item['type'];
          if (type == 'text' && item['text'] is String) {
            parts.add(item['text'] as String);
          }
        }
      }
      if (parts.isNotEmpty) return parts.join('\n');
    }
    return null;
  }

  String _stripThinking(String s) {
    // Strip <think>...</think> blocks. Use a non-greedy match so an
    // unterminated tag (model error) doesn't swallow the rest of the
    // response — cap the runaway at 2k chars to be safe.
    final tagged = RegExp(r'<think>[\s\S]*?</think>\s*', caseSensitive: false);
    final unterminated = RegExp(r'<think>[\s\S]{0,2000}', caseSensitive: false);
    var cleaned = s.replaceAll(tagged, '').replaceAll(unterminated, '');
    final lines = cleaned.split('\n');
    final seen = <String>{};
    final kept = <String>[];
    final pattern = RegExp(
      r'^(The user|Linh vuc|Dieu uoc|CATEGOR|Please|Bạn nên|Let me|Now I|I need|My response|I should|My approach|I will|I can|Let me respond|Let me offer|Người dùng|Bạn ơi)',
      caseSensitive: false,
    );
    for (final raw in lines) {
      final l = raw.trim();
      if (l.isEmpty) continue;
      if (pattern.hasMatch(l)) continue;
      if (seen.add(l)) kept.add(l);
    }
    return kept.join('\n').trim();
  }

  /// Best-effort fix for mojibake coming back from upstream. Some
  /// intermediate proxies encode UTF-8 as latin-1 then re-encode the
  /// resulting string as UTF-8, which turns "Sợ" into "Sá»£".
  ///
  /// We reverse the round-trip: take each char as a byte, then
  /// decode the byte sequence as UTF-8. If that produces more
  /// mojibake-y text, do it again (double-double-encoding). We
  /// stop as soon as the result no longer contains any of the
  /// tell-tale latin-1 high bytes used as separators.
  String _fixEncoding(String s) {
    if (!_looksLikeMojibake(s)) return s;
    for (var round = 0; round < 3; round++) {
      try {
        final bytes = s.codeUnits.map((c) => c & 0xff).toList();
        final decoded = utf8.decode(bytes, allowMalformed: false);
        if (!_looksLikeMojibake(decoded) || decoded == s) {
          return decoded;
        }
        s = decoded;
      } catch (_) {
        return s;
      }
    }
    return s;
  }

  /// Heuristic: string likely came from latin-1-then-utf-8 encoding
  /// if it contains the typical double-encoded sequences. Vietnamese
  /// text never has 'Ã' followed by another char, 'á»' sequences, etc.
  bool _looksLikeMojibake(String s) {
    if (s.contains('Ã')) return true;
    if (s.contains('á»')) return true;
    if (s.contains('â ')) return true;
    if (s.contains('Ä')) return true;
    if (s.contains('Æ')) return true;
    return false;
  }

  bool _looksLikeError(String s) {
    final t = s.trim().toLowerCase();
    if (t.length > 200) return false;
    return t.startsWith('error:') ||
        t.startsWith('error ') ||
        t.startsWith('lỗi:') ||
        t.startsWith('lỗi ') ||
        t.startsWith('unauthorized') ||
        t.startsWith('http 4') ||
        t.startsWith('http 5') ||
        t.startsWith('429 ') ||
        t.startsWith('401 ') ||
        t.startsWith('500 ') ||
        t == 'failed' ||
        t == 'failed!';
  }

  void dispose() => _client.close();
}
