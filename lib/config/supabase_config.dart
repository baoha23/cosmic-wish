/// Central Supabase configuration.
///
/// The project URL was previously hardcoded and duplicated across
/// `wish_service.dart` and `anonymous_wishes_service.dart`. Keeping it
/// in one place means a project migration is a single-line change.
class SupabaseConfig {
  SupabaseConfig._();

  /// Base project URL. Override at build time with
  ///   flutter build apk --dart-define=SUPABASE_URL=https://xxx.supabase.co
  /// Falls back to the shipped project when the define is absent.
  static const String projectUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://pjubjhrhyrtnnhavnkuk.supabase.co',
  );

  /// Anon key, supplied at build time with
  ///   flutter build apk --dart-define=SUPABASE_ANON_KEY=...
  /// Empty for debug builds; consumers skip network calls when empty.
  static const String anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  /// Edge Function that turns a wish into a prophecy.
  static const String generateWishUrl =
      '$projectUrl/functions/v1/generate-wish';

  /// Edge Function for the hidden admin console (provider config).
  static const String adminUrl = '$projectUrl/functions/v1/admin';

  /// REST base for the public `anonymous_wishes` table.
  static const String restUrl = '$projectUrl/rest/v1';
}
