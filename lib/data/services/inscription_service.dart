import 'dart:async';

import '../../core/errors/app_exception.dart';
import '../../domain/entities/adhesion.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/profil.dart';
import '../../domain/entities/session.dart';
import '../../domain/entities/tontine.dart';
import '../../domain/rules/validation_tontine.dart';
import '../repositories/groupes_repository.dart';
import 'auth_service.dart';
import 'preferences_session.dart';

/// Ce qu'il advient après une inscription par email.
enum IssueInscription {
  /// Compte créé et connecté.
  connecte,

  /// Compte créé ; la connexion se fera après ouverture du lien de
  /// confirmation reçu par email.
  confirmationRequise,
}

/// Orchestre l'authentification et les groupes du compte : inscription,
/// connexion, création de tontine, adhésion par code, choix du groupe
/// affiché, et session courante.
class InscriptionService {
  InscriptionService({
    required this.authService,
    required this.groupes,
    required this.preferences,
  });

  final AuthService authService;
  final GroupesRepository groupes;
  final PreferencesSession preferences;

  /// Session courante, en direct : `null` si déconnecté ; sinon
  /// l'utilisateur, tous ses groupes et le groupe affiché ([Session.profil],
  /// `null` tant qu'il n'appartient à aucun groupe).
  ///
  /// À la première session après une inscription avec code d'invitation,
  /// réclame automatiquement l'invitation mise de côté.
  Stream<Session?> get session {
    late final StreamController<Session?> controleur;
    StreamSubscription<AppUser?>? abonnementAuth;
    StreamSubscription<List<Adhesion>>? abonnementAdhesions;
    StreamSubscription<String>? abonnementChoix;

    void suivre(AppUser? utilisateur) {
      abonnementAdhesions?.cancel();
      abonnementChoix?.cancel();
      abonnementAdhesions = null;
      abonnementChoix = null;
      if (utilisateur == null) {
        controleur.add(null);
        return;
      }

      var adhesions = const <Adhesion>[];
      void emettre() => controleur.add(_session(utilisateur, adhesions));

      unawaited(_reclamerCodeEnAttente());
      abonnementAdhesions = groupes.watchAdhesions(utilisateur.uid).listen(
        (valeur) {
          adhesions = valeur;
          emettre();
        },
        onError: controleur.addError,
      );
      abonnementChoix = preferences.changementsGroupe
          .where((uid) => uid == utilisateur.uid)
          .listen((_) => emettre());
    }

    controleur = StreamController<Session?>.broadcast(
      onListen: () {
        abonnementAuth = authService.authStateChanges.listen(suivre, onError: controleur.addError);
      },
      onCancel: () {
        abonnementAuth?.cancel();
        abonnementAdhesions?.cancel();
        abonnementChoix?.cancel();
      },
    );
    return controleur.stream;
  }

  Session _session(AppUser utilisateur, List<Adhesion> adhesions) {
    final adhesion = groupeAffiche(adhesions, preferences.groupeCourant(utilisateur.uid));
    return Session(
      utilisateur: utilisateur,
      adhesions: adhesions,
      profil: adhesion == null
          ? null
          : Profil(
              uid: utilisateur.uid,
              tontineId: adhesion.groupeId,
              membreId: adhesion.membreId,
              roles: adhesion.roles,
            ),
    );
  }

  /// Groupe affiché : celui choisi en dernier s'il fait toujours partie
  /// des groupes du compte, sinon le premier.
  static Adhesion? groupeAffiche(List<Adhesion> adhesions, String? choisi) {
    if (adhesions.isEmpty) return null;
    for (final adhesion in adhesions) {
      if (adhesion.groupeId == choisi) return adhesion;
    }
    return adhesions.first;
  }

  Future<void> _reclamerCodeEnAttente() async {
    final code = preferences.codeInvitationEnAttente;
    if (code == null) return;
    try {
      await rejoindreAvecCode(code);
    } on AppException {
      // Code devenu invalide ou déjà utilisé : la personne pourra en saisir
      // un autre depuis l'écran d'adhésion.
    } finally {
      await preferences.setCodeInvitationEnAttente(null);
    }
  }

  /// Inscription par email, avec ou sans code d'invitation. Si une
  /// confirmation d'email est exigée, le code est mis de côté et réclamé
  /// automatiquement à la première connexion.
  Future<IssueInscription> inscrire({
    required String email,
    required String password,
    String? codeInvitation,
  }) async {
    final code = codeInvitation?.trim().toUpperCase();
    if (code != null && code.isNotEmpty) {
      final apercu = await groupes.apercuInvitation(code);
      if (apercu == null) throw const InvitationIntrouvableException();
      if (apercu.dejaUtilisee) throw const InvitationDejaUtiliseeException();
    }

    final resultat = await authService.signUp(email: email, password: password);
    if (!resultat.connecte) {
      if (code != null && code.isNotEmpty) await preferences.setCodeInvitationEnAttente(code);
      return IssueInscription.confirmationRequise;
    }
    if (code != null && code.isNotEmpty) await rejoindreAvecCode(code);
    return IssueInscription.connecte;
  }

  Future<AppUser> connecter({required String email, required String password}) =>
      authService.signIn(email: email, password: password);

  /// `null` si l'utilisateur annule.
  Future<AppUser?> connecterAvecGoogle() => authService.signInWithGoogle();

  /// `null` si l'utilisateur annule.
  Future<AppUser?> connecterAvecApple() => authService.signInWithApple();

  /// Crée une tontine dont le compte connecté devient propriétaire et
  /// trésorier, et l'affiche.
  ///
  /// [tontineSansId] porte les champs métier ; `id` et `adminUid` sont
  /// ignorés (fixés par le serveur).
  Future<String> creerTontine({
    required String nomCompletAdmin,
    required Tontine tontineSansId,
  }) async {
    final utilisateur = authService.currentUser;
    if (utilisateur == null) throw const SignInRequiredException();
    const ValidationTontine().valider(tontineSansId);

    final groupeId = await groupes.creerTontine(
      tontine: tontineSansId,
      nomCompletAdmin: nomCompletAdmin.trim(),
    );
    await preferences.choisirGroupe(utilisateur.uid, groupeId);
    return groupeId;
  }

  /// Aperçu (nom du groupe, nombre de membres) d'un code d'invitation,
  /// `null` si le code est inconnu. Accessible sans compte.
  Future<ApercuInvitation?> apercuInvitation(String codeInvitation) =>
      groupes.apercuInvitation(codeInvitation.trim().toUpperCase());

  /// Rattache le compte connecté au membre désigné par le code, et affiche
  /// ce groupe.
  Future<String> rejoindreAvecCode(String codeInvitation) async {
    final utilisateur = authService.currentUser;
    if (utilisateur == null) throw const SignInRequiredException();
    final resultat = await groupes.rejoindre(codeInvitation.trim().toUpperCase());
    await preferences.choisirGroupe(utilisateur.uid, resultat.groupeId);
    return resultat.groupeId;
  }

  /// Change le groupe affiché.
  Future<void> choisirGroupe(String groupeId) async {
    final utilisateur = authService.currentUser;
    if (utilisateur == null) throw const SignInRequiredException();
    await preferences.choisirGroupe(utilisateur.uid, groupeId);
  }

  Future<void> renvoyerConfirmation(String email) => authService.resendConfirmation(email);

  /// Recharge le compte et indique si son email est confirmé.
  Future<bool> verifierEmailVerifie() async {
    final utilisateur = await authService.reloadUser();
    return utilisateur?.emailVerified ?? false;
  }

  Future<void> changerMotDePasse(String motDePasse) => authService.updatePassword(motDePasse);

  Future<void> deconnecter() => authService.signOut();

  Future<void> reinitialiserMotDePasse(String email) => authService.sendPasswordResetEmail(email);
}
