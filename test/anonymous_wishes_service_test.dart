import 'dart:convert';

import 'package:cosmic_wish/config/supabase_config.dart';
import 'package:cosmic_wish/models/wish_category.dart';
import 'package:cosmic_wish/services/anonymous_wishes_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('community shares go through the validated Edge Function', () async {
    late http.Request captured;
    final client = MockClient((request) async {
      captured = request;
      return http.Response('{"shared":true}', 200);
    });
    final service = AnonymousWishesService(
      client: client,
      anonKey: 'test-anon-key',
    );

    await service.share(
      category: WishCategory.family,
      transcript: 'Mong gia đình bình an',
    );

    final body = jsonDecode(captured.body) as Map<String, dynamic>;
    expect(captured.url.toString(), SupabaseConfig.generateWishUrl);
    expect(captured.headers['Authorization'], 'Bearer test-anon-key');
    expect(body['action'], 'share-anonymous');
    expect(body['category'], 'family');
    service.dispose();
  });
}
