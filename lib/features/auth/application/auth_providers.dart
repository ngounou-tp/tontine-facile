import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/datasources/profil_firestore_datasource.dart';
import '../../../data/datasources/tontine_firestore_datasource.dart';
import '../../../data/repositories/profil_repository.dart';
import '../../../data/repositories/profil_repository_impl.dart';
import '../../../data/repositories/tontine_repository.dart';
import '../../../data/repositories/tontine_repository_impl.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/firebase_auth_service.dart';
import '../../../data/services/inscription_service.dart';
import '../../../domain/entities/app_user.dart';
import '../../../domain/entities/session.dart';
import '../../../domain/entities/tontine.dart';

/// Source unique de l'utilisateur authentifié Firebase.
///
/// L'état est `loading` pendant la restauration de la session, `null` après
/// déconnexion et contient un [AppUser] une fois connecté.
final authStateProvider = StreamProvider<AppUser?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

/// Adaptateur Firebase Auth utilisé par les écrans et le service d'inscription.
final authServiceProvider = Provider<AuthService>((ref) {
  return FirebaseAuthService();
});

final _profilDataSourceProvider = Provider<ProfilDataSource>((ref) {
  return FirestoreProfilDataSource();
});

/// Accès aux profils qui relient un compte à une tontine et à un membre.
final profilRepositoryProvider = Provider<ProfilRepository>((ref) {
  return FirestoreProfilRepository(
    dataSource: ref.watch(_profilDataSourceProvider),
  );
});

final _tontineDataSourceProvider = Provider<TontineDataSource>((ref) {
  return FirestoreTontineDataSource();
});

/// Dépendance nécessaire aux parcours d'inscription et d'adhésion.
final tontineRepositoryProvider = Provider<TontineRepository>((ref) {
  return FirestoreTontineRepository(
    dataSource: ref.watch(_tontineDataSourceProvider),
  );
});

/// Orchestre Firebase Auth, profils, invitations et tontines.
final inscriptionServiceProvider = Provider<InscriptionService>((ref) {
  return InscriptionService(
    authService: ref.watch(authServiceProvider),
    tontineRepository: ref.watch(tontineRepositoryProvider),
    profilRepository: ref.watch(profilRepositoryProvider),
  );
});

/// Session applicative enrichie du profil Firestore éventuel.
///
/// Un compte authentifié sans profil produit une [Session] dont `profil` est
/// `null`; le routeur pourra ainsi l'orienter vers la création ou l'adhésion à
/// une tontine plutôt que vers l'espace administrateur ou membre.
final sessionProvider = StreamProvider<Session?>((ref) {
  return ref.watch(inscriptionServiceProvider).session;
});

/// Tontine associée à la session courante, utile notamment aux gardes de route
/// pour distinguer l'administratrice des membres.
final currentTontineProvider = FutureProvider<Tontine?>((ref) async {
  final session = await ref.watch(sessionProvider.future);
  final profil = session?.profil;
  if (profil == null) return null;

  return ref.watch(tontineRepositoryProvider).getTontine(profil.tontineId);
});

/// `true` si le compte connecté est l'administratrice de la tontine
/// courante, `false` pour un membre ou tant que l'un ou l'autre n'a pas
/// résolu. Les écrans partagés (Accueil, Membres, Échéancier, Réglages,
/// Déclarations) sont ouverts en lecture seule aux membres par le routeur ;
/// c'est ce provider qui leur permet de masquer localement leurs actions
/// réservées (ajouter/modifier/désactiver un membre, générer ou réorganiser
/// l'échéancier, traiter une déclaration...).
final isAdminProvider = Provider<bool>((ref) {
  final session = ref.watch(sessionProvider).value;
  final tontine = ref.watch(currentTontineProvider).value;
  if (session == null || tontine == null) return false;
  return tontine.adminUid == session.utilisateur.uid;
});

/// Aperçu (nom, nombre de membres) de la tontine désignée par un code
/// d'invitation, `null` si le code est introuvable. Une instance par code
/// grâce à `.family` : l'écran d'adhésion la relance à chaque frappe.
final apercuInvitationProvider = FutureProvider.autoDispose
    .family<({String nom, int nombreMembres})?, String>((ref, code) {
  return ref.watch(inscriptionServiceProvider).apercuInvitation(code);
});
