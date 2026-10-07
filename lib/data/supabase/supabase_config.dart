/// Paramètres de connexion au projet Supabase, fournis au build :
///
/// ```
/// flutter run --dart-define-from-file=env/live.json
/// ```
///
/// avec `SUPABASE_URL` et `SUPABASE_ANON_KEY` (clé publique « anon » :
/// elle n'ouvre rien d'elle-même, toutes les tables sont protégées par RLS).
abstract final class SupabaseConfig {
  static const url = String.fromEnvironment('SUPABASE_URL');
  static const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  /// Lien de retour après confirmation d'email ou connexion externe
  /// (déclaré dans `supabase/config.toml`, Android et iOS).
  static const redirectUrl = 'djanguibook://login-callback';

  static bool get estConfigure => url.isNotEmpty && anonKey.isNotEmpty;
}
