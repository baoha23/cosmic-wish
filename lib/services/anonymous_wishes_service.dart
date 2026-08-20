import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/supabase_config.dart';
import '../models/wish_category.dart';

/// A single wish shared anonymously by someone, somewhere.
class AnonymousWish {
  AnonymousWish({
    required this.id,
    required this.category,
    required this.transcript,
  });

  final String id;
  final WishCategory category;
  final String transcript;
}

/// Service for the community "anonymous wishes" feature.
///
/// Backed by a Supabase table `anonymous_wishes` with RLS that allows
/// anyone to read and insert. Each new wish from a user is also pushed
/// here so others can see it.
class AnonymousWishesService {
  AnonymousWishesService({
    http.Client? client,
    Random? random,
    String anonKey = SupabaseConfig.anonKey,
  }) : _client = client ?? http.Client(),
       _random = random ?? Random(),
       _anonKey = anonKey;

  final http.Client _client;
  final Random _random;

  // Anon key falls back to empty string for debug builds; those
  // silently skip the network call so the app stays usable offline.
  final String _anonKey;

  static const _table = 'anonymous_wishes';
  static const _fetchLimit = 60;

  Future<bool> _hasKey() async {
    return _anonKey.isNotEmpty;
  }

  Future<List<AnonymousWish>> fetchSample({int count = 10}) async {
    if (!await _hasKey()) {
      debugPrint('AnonymousWishesService: no anon key, returning empty');
      return const [];
    }
    try {
      final uri = Uri.parse(
        '${SupabaseConfig.restUrl}/$_table'
        '?select=id,category,transcript'
        '&order=created_at.desc'
        '&limit=$_fetchLimit',
      );
      final res = await _client
          .get(uri, headers: _headers())
          .timeout(const Duration(seconds: 6));
      if (res.statusCode != 200) {
        debugPrint(
          'AnonymousWishesService fetch failed: ${res.statusCode} ${res.body.substring(0, res.body.length.clamp(0, 200))}',
        );
        return const [];
      }
      final list = jsonDecode(res.body) as List<dynamic>;
      final all = list
          .map((e) {
            final catName = (e as Map<String, dynamic>)['category'] as String?;
            final category = WishCategory.values.firstWhere(
              (c) => c.name == catName,
              orElse: () => WishCategory.other,
            );
            return AnonymousWish(
              id: e['id'] as String,
              category: category,
              transcript: e['transcript'] as String? ?? '',
            );
          })
          .where((w) => w.transcript.isNotEmpty)
          .toList();
      all.shuffle(_random);
      return all.take(count).toList();
    } catch (e) {
      debugPrint('AnonymousWishesService fetch error: $e');
      return const [];
    }
  }

  /// Push the user's own wish anonymously. Best-effort; failures are
  /// silently logged so they never block the result screen.
  Future<void> share({
    required WishCategory category,
    required String transcript,
  }) async {
    if (!await _hasKey()) return;
    final trimmed = transcript.trim();
    if (trimmed.isEmpty || trimmed.length > 500) return;
    try {
      final uri = Uri.parse(SupabaseConfig.generateWishUrl);
      final response = await _client
          .post(
            uri,
            headers: _headers(),
            body: jsonEncode({
              'action': 'share-anonymous',
              'category': category.name,
              'transcript': trimmed,
            }),
          )
          .timeout(const Duration(seconds: 4));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        debugPrint(
          'AnonymousWishesService share failed: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('AnonymousWishesService share error: $e');
    }
  }

  Map<String, String> _headers() => {
    'apikey': _anonKey,
    'Authorization': 'Bearer $_anonKey',
    'Content-Type': 'application/json',
  };

  void dispose() => _client.close();
}
