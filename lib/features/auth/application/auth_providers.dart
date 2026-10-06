import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase, SupabaseClient;

import '../../../core/errors/app_exception.dart';
import '../../../data/repositories/groupes_repository.dart';
import '../../../data/repositories/supabase_groupes_repository.dart';
import '../../../data/repositories/supabase_tontine_repository.dart';
import '../../../data/repositories/tontine_repository.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/inscription_service.dart';
import '../../../data/services/preferences_session.dart';
import '../../../data/services/supabase_auth_service.dart';
import '../../../data/supabase/stockage_preuves.dart';
import '../../../data/supabase/supabase_config.dart';
import '../../../data/supabase/table_changes.dart';
import '../../../domain/entities/app_user.dart';
import '../../../domain/entities/session.dart';
import '../../../domain/entities/tontine.dart';
import '../../onboarding/application/onboarding_provider.dart';

/// Client Supabase initialisé au démarrage (`main.dart`). Lève
/// [ServeurNonConfigureException] si le build n'a pas reçu
/// `SUPABASE_URL` / `SUPABASE_ANON_KEY`.
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  if (!SupabaseConfig.estConfigure) throw const ServeurNonConfigureException();
  return Supabase.instance.client;
});

/// Source unique de l'utilisateur authentifié.
///
/// `loading` pendant la restauration de la session, `null` après
/// déconnexion, un [AppUser] une fois connecté.
final authStateProvider = StreamProvider<AppUser?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final authServiceProvider = Provider<AuthService>((ref) {
  return SupabaseAuthService(
    ref.watch(supabaseClientProvider).auth,
    googleServerClientId: const String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID').isEmpty
        ? null
        : const String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID'),
  );
});

final tableChangesProvider = Provider<TableChanges>((ref) {
  return SupabaseTableChanges(ref.watch(supabaseClientProvider));
});

final stockagePreuvesProvider = Provider<StockagePreuves>((ref) {
  return SupabaseStockagePreuves(ref.watch(supabaseClientProvider));
});

/// Données des tontines (membres, noms, tours, cotisations...).
final tontineRepositoryProvider = Provider<TontineRepository>((ref) {
  return SupabaseTontineRepository(
    db: ref.watch(supabaseClientProvider).rest,
    changes: ref.watch(tableChangesProvider),
    stockage: ref.watch(stockagePreuvesProvider),
  );
});

/// Groupes du compte : appartenances, création, adhésion.
final groupesRepositoryProvider = Provider<GroupesRepository>((ref) {
  return SupabaseGroupesRepository(
    db: ref.watch(supabaseClientProvider).rest,
    changes: ref.watch(tableChangesProvider),
  );
});

final preferencesSessionProvider = Provider<PreferencesSession>((ref) {
  return SharedPreferencesSession(ref.watch(sharedPreferencesProvider));
});

/// Orchestre authentification, groupes et groupe affiché.
final inscriptionServiceProvider = Provider<InscriptionService>((ref) {
  return InscriptionService(
    authService: ref.watch(authServiceProvider),
    groupes: ref.watch(groupesRepositoryProvider),
    preferences: ref.watch(preferencesSessionProvider),
  );
});

/// Session : utilisateur, ses groupes, et le groupe affiché
/// ([Session.profil], `null` tant qu'il n'appartient à aucun groupe — le
/// routeur l'oriente alors vers la création ou l'adhésion).
final sessionProvider = StreamProvider<Session?>((ref) {
  return ref.watch(inscriptionServiceProvider).session;
});

/// Tontine du groupe affiché, utile notamment aux gardes de route.
final currentTontineProvider = FutureProvider<Tontine?>((ref) async {
  final session = await ref.watch(sessionProvider.future);
  final profil = session?.profil;
  if (profil == null) return null;

  return ref.watch(tontineRepositoryProvider).getTontine(profil.tontineId);
});

/// `true` si le compte connecté fait partie du bureau (propriétaire,
/// président ou trésorier) du groupe affiché. Les écrans partagés masquent
/// leurs actions réservées pour les autres membres ; le serveur refuse de
/// toute façon ces actions (RLS).
final isAdminProvider = Provider<bool>((ref) {
  return ref.watch(sessionProvider).value?.profil?.estGestionnaire ?? false;
});

/// Aperçu (nom du groupe, nombre de membres) du groupe désigné par un code
/// d'invitation, `null` si le code est introuvable.
final apercuInvitationProvider =
    FutureProvider.autoDispose.family<ApercuInvitation?, String>((ref, code) {
  return ref.watch(inscriptionServiceProvider).apercuInvitation(code);
});
