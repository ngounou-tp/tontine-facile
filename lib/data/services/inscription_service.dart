import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart' show FirebaseException;

import '../../core/errors/app_exception.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/invitation.dart';
import '../../domain/entities/membre.dart';
import '../../domain/entities/profil.dart';
import '../../domain/entities/session.dart';
import '../../domain/entities/tontine.dart';
import '../../domain/rules/validation_tontine.dart';
import '../repositories/profil_repository.dart';
import '../repositories/tontine_repository.dart';
import 'auth_service.dart';

/// Orchestre Inscription, Connexion, Déconnexion, réinitialisation de mot de
/// passe et session, en composant [AuthService] (Firebase Auth) avec
/// [TontineRepository] et [ProfilRepository] (Firestore).
///
/// Deux parcours d'inscription :
/// - [inscrireAdmin] : crée le compte, la tontine, le membre de
///   l'administratrice elle-même, et son profil.
/// - [inviterMembre] puis, côté invité, [inscrireMembre] : l'administratrice
///   crée un membre placeholder (sans `uid`) et une invitation nominative ;
///   la personne invitée s'inscrit avec le code reçu, ce qui réclame le
///   placeholder et crée son profil.
class InscriptionService {
  const InscriptionService({
    required this.authService,
    required this.tontineRepository,
    required this.profilRepository,
  });

  final AuthService authService;
  final TontineRepository tontineRepository;
  final ProfilRepository profilRepository;

  /// Session courante : `null` si déconnecté, sinon l'utilisateur Firebase
  /// Auth accompagné de son profil (`null` si l'inscription n'a pas abouti).
  ///
  /// Suit le profil Firestore EN DIRECT (pas seulement l'état Firebase Auth) :
  /// juste après avoir rejoint une tontine ou créé un compte, l'utilisateur
  /// reste le même du point de vue de Firebase Auth (aucune nouvelle
  /// émission de `authStateChanges`), alors que le profil, lui, vient
  /// d'apparaître. Sans ce suivi séparé, le routeur ne serait jamais
  /// notifié du nouveau profil et resterait bloqué sur un écran destiné aux
  /// comptes sans tontine (voir `AppRouter.redirect`).
  Stream<Session?> get session {
    late StreamController<Session?> controleur;
    StreamSubscription<Profil?>? abonnementProfil;
    StreamSubscription<AppUser?>? abonnementAuth;

    void suivreProfil(AppUser? utilisateur) {
      abonnementProfil?.cancel();
      if (utilisateur == null) {
        abonnementProfil = null;
        controleur.add(null);
        return;
      }
      abonnementProfil = profilRepository.watchProfil(utilisateur.uid).listen(
            (profil) => controleur.add(Session(utilisateur: utilisateur, profil: profil)),
            onError: controleur.addError,
          );
    }

    controleur = StreamController<Session?>.broadcast(
      onListen: () {
        abonnementAuth = authService.authStateChanges.listen(
          suivreProfil,
          onError: controleur.addError,
        );
      },
      onCancel: () {
        abonnementAuth?.cancel();
        abonnementProfil?.cancel();
      },
    );
    return controleur.stream;
  }

  /// Inscription de l'administratrice : crée le compte, la tontine, son
  /// propre membre, et le profil qui les relie.
  ///
  /// [tontineSansId] doit avoir tous les champs métier déjà renseignés
  /// (nom, montant, périodicité, pénalité, mode de parts...) ; `id`,
  /// `adminUid` et `codeInvitation` sont ignorés et régénérés ici.
  Future<Session> inscrireAdmin({
    required String email,
    required String password,
    required String nomCompletAdmin,
    required Tontine tontineSansId,
  }) async {
    final utilisateur = await authService.signUp(
      email: email,
      password: password,
    );
    await _envoyerVerificationSansEchec();

    return _creerTontineEtProfilAdmin(
      utilisateur: utilisateur,
      nomCompletAdmin: nomCompletAdmin,
      tontineSansId: tontineSansId,
    );
  }

  /// Crée la tontine, le membre de l'administratrice et son profil, pour un
  /// compte déjà authentifié mais sans profil (arrivé via
  /// [creerCompteSansTontine]). Reprend la même logique que la fin de
  /// [inscrireAdmin], sans l'étape de création de compte.
  Future<Session> creerTontinePourAdmin({
    required String nomCompletAdmin,
    required Tontine tontineSansId,
  }) async {
    final utilisateur = authService.currentUser;
    if (utilisateur == null) {
      throw const SignInRequiredException();
    }

    return _creerTontineEtProfilAdmin(
      utilisateur: utilisateur,
      nomCompletAdmin: nomCompletAdmin,
      tontineSansId: tontineSansId,
    );
  }

  /// Construit la tontine (id et code d'invitation régénérés, validée via
  /// [ValidationTontine]), le membre de l'administratrice, son invitation
  /// auto-réclamée (exigée par les règles Firestore — voir [inviterMembre])
  /// et son profil.
  ///
  /// [tontineSansId] doit avoir tous les champs métier déjà renseignés
  /// (nom, montant, périodicité, pénalité, mode de parts...) ; `id`,
  /// `adminUid` et `codeInvitation` sont ignorés et régénérés ici.
  Future<Session> _creerTontineEtProfilAdmin({
    required AppUser utilisateur,
    required String nomCompletAdmin,
    required Tontine tontineSansId,
  }) async {
    final tontine = Tontine(
      id: tontineRepository.nouvelIdTontine(),
      nom: tontineSansId.nom,
      adminUid: utilisateur.uid,
      montantParNom: tontineSansId.montantParNom,
      nombreDeNoms: tontineSansId.nombreDeNoms,
      datePremiereEcheance: tontineSansId.datePremiereEcheance,
      periodicite: tontineSansId.periodicite,
      reglePenalite: tontineSansId.reglePenalite,
      delaiGraceJours: tontineSansId.delaiGraceJours,
      valeurPenalite: tontineSansId.valeurPenalite,
      modeParts: tontineSansId.modeParts,
      codeInvitation: _genererCode(),
    );
    const ValidationTontine().valider(tontine);
    await tontineRepository.saveTontine(tontine);

    final membre = await tontineRepository.creerMembrePlaceholder(
      tontine.id,
      nomComplet: nomCompletAdmin,
      email: utilisateur.email,
    );

    // Les règles Firestore exigent, pour réclamer un membre, une invitation
    // correspondante dans `invitations/{code}` — y compris pour
    // l'administratrice qui se réclame elle-même via `tontine.codeInvitation`.
    await profilRepository.saveInvitation(
      Invitation(
        code: tontine.codeInvitation,
        tontineId: tontine.id,
        membreId: membre.id,
        nomTontine: tontine.nom,
        nombreMembres: 1,
      ),
    );
    await tontineRepository.saveMembre(
      tontine.id,
      Membre(
        id: membre.id,
        nomComplet: membre.nomComplet,
        email: membre.email,
        whatsapp: membre.whatsapp,
        uid: membre.uid,
        actif: membre.actif,
        codeInvitation: tontine.codeInvitation,
      ),
    );
    await tontineRepository.claimMembre(
      tontineId: tontine.id,
      membreId: membre.id,
      uid: utilisateur.uid,
      codeInvitation: tontine.codeInvitation,
    );

    final profil = Profil(
      uid: utilisateur.uid,
      tontineId: tontine.id,
      membreId: membre.id,
    );
    await profilRepository.saveProfil(profil);

    return Session(utilisateur: utilisateur, profil: profil);
  }

  /// Ajoute un membre placeholder (sans `uid`) et génère son invitation
  /// nominative. Réservé à l'administratrice de [tontineId] : les règles
  /// Firestore refusent la création de l'invitation sinon.
  Future<Invitation> inviterMembre({
    required String tontineId,
    required String nomComplet,
    String? email,
    String? whatsapp,
  }) async {
    final membre = await tontineRepository.creerMembrePlaceholder(
      tontineId,
      nomComplet: nomComplet,
      email: email,
      whatsapp: whatsapp,
    );

    final tontine = await tontineRepository.getTontine(tontineId);
    if (tontine == null) {
      throw StateError('Tontine "$tontineId" introuvable.');
    }
    final membres = await tontineRepository.getMembres(tontineId);

    for (var tentative = 0; tentative < 5; tentative++) {
      final code = _genererCode();
      if (await profilRepository.getInvitation(code) != null) continue;
      final invitation = Invitation(
        code: code,
        tontineId: tontineId,
        membreId: membre.id,
        nomTontine: tontine.nom,
        nombreMembres: membres.length,
      );
      await profilRepository.saveInvitation(invitation);
      // Dénormalisé sur la fiche pour rester consultable depuis
      // `FicheMembrePage` après la création (l'écran d'ajout ne le montre
      // qu'une fois).
      await tontineRepository.saveMembre(
        tontineId,
        Membre(
          id: membre.id,
          nomComplet: membre.nomComplet,
          email: membre.email,
          whatsapp: membre.whatsapp,
          uid: membre.uid,
          actif: membre.actif,
          codeInvitation: code,
        ),
      );
      return invitation;
    }
    throw StateError("Impossible de générer un code d'invitation unique.");
  }

  /// Inscription d'un membre invité : crée le compte et réclame le
  /// placeholder désigné par [codeInvitation].
  ///
  /// Lance [InvitationIntrouvableException] si le code n'existe pas, ou
  /// [InvitationDejaUtiliseeException] si le placeholder a déjà été réclamé.
  Future<Session> inscrireMembre({
    required String email,
    required String password,
    required String codeInvitation,
  }) async {
    final code = codeInvitation.trim().toUpperCase();
    final invitation = await profilRepository.getInvitation(code);
    if (invitation == null) {
      throw const InvitationIntrouvableException();
    }

    final utilisateur = await authService.signUp(
      email: email,
      password: password,
    );
    await _envoyerVerificationSansEchec();

    try {
      await tontineRepository.claimMembre(
        tontineId: invitation.tontineId,
        membreId: invitation.membreId,
        uid: utilisateur.uid,
        codeInvitation: invitation.code,
      );
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') {
        throw const InvitationDejaUtiliseeException();
      }
      rethrow;
    }

    final profil = Profil(
      uid: utilisateur.uid,
      tontineId: invitation.tontineId,
      membreId: invitation.membreId,
    );
    await profilRepository.saveProfil(profil);

    return Session(utilisateur: utilisateur, profil: profil);
  }

  /// Crée un compte avant le choix de créer ou rejoindre une tontine.
  Future<Session> creerCompteSansTontine({
    required String email,
    required String password,
  }) async {
    final utilisateur = await authService.signUp(email: email, password: password);
    await _envoyerVerificationSansEchec();
    return Session(utilisateur: utilisateur);
  }

  /// Connexion (ou création implicite de compte) via Google. Les comptes
  /// Google sont considérés vérifiés par Firebase : aucun email de
  /// vérification n'est nécessaire.
  ///
  /// Renvoie `null` si l'utilisateur annule la sélection de compte.
  Future<Session?> connecterAvecGoogle() async {
    final utilisateur = await authService.signInWithGoogle();
    if (utilisateur == null) return null;
    final profil = await profilRepository.getProfil(utilisateur.uid);
    return Session(utilisateur: utilisateur, profil: profil);
  }

  /// Renvoie l'email de vérification à l'utilisateur actuellement connecté.
  Future<void> renvoyerEmailVerification() => authService.sendEmailVerification();

  /// Recharge l'utilisateur courant (par exemple après un clic sur le lien de
  /// vérification) et renvoie `true` si son email est désormais vérifié.
  Future<bool> verifierEmailVerifie() async {
    final utilisateur = await authService.reloadUser();
    return utilisateur?.emailVerified ?? false;
  }

  /// Best-effort : un échec d'envoi de l'email de vérification ne doit pas
  /// faire échouer l'inscription elle-même.
  Future<void> _envoyerVerificationSansEchec() async {
    try {
      await authService.sendEmailVerification();
    } catch (_) {
      // Ignoré volontairement : l'utilisateur pourra toujours redemander
      // l'envoi depuis l'écran de vérification.
    }
  }

  /// Aperçu (nom de la tontine, nombre de membres) pour un code d'invitation,
  /// ou `null` si le code est introuvable. Utilisé par l'écran d'adhésion
  /// pour prévisualiser la tontine avant même la création d'un compte.
  ///
  /// Lit uniquement `invitations/{code}` (accessible sans authentification) :
  /// [Invitation.nomTontine] et [Invitation.nombreMembres] sont un instantané
  /// dénormalisé pris à la création de l'invitation, pas une lecture en
  /// direct de `tontines/{id}` (réservée aux membres).
  Future<({String nom, int nombreMembres})?> apercuInvitation(
    String codeInvitation,
  ) async {
    final code = codeInvitation.trim().toUpperCase();
    final invitation = await profilRepository.getInvitation(code);
    if (invitation == null) return null;
    return (nom: invitation.nomTontine, nombreMembres: invitation.nombreMembres);
  }

  /// Rattache le compte déjà connecté au membre désigné par un code.
  Future<Session> rejoindreAvecCode(String codeInvitation) async {
    final utilisateur = authService.currentUser;
    if (utilisateur == null) {
      throw const SignInRequiredException();
    }

    final code = codeInvitation.trim().toUpperCase();
    final invitation = await profilRepository.getInvitation(code);
    if (invitation == null) throw const InvitationIntrouvableException();

    try {
      await tontineRepository.claimMembre(
        tontineId: invitation.tontineId,
        membreId: invitation.membreId,
        uid: utilisateur.uid,
        codeInvitation: invitation.code,
      );
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') {
        throw const InvitationDejaUtiliseeException();
      }
      rethrow;
    }

    final profil = Profil(
      uid: utilisateur.uid,
      tontineId: invitation.tontineId,
      membreId: invitation.membreId,
    );
    await profilRepository.saveProfil(profil);
    return Session(utilisateur: utilisateur, profil: profil);
  }

  /// Connexion : authentifie, puis charge le profil existant s'il y en a un.
  Future<Session> connecter({
    required String email,
    required String password,
  }) async {
    final utilisateur = await authService.signIn(
      email: email,
      password: password,
    );
    final profil = await profilRepository.getProfil(utilisateur.uid);
    return Session(utilisateur: utilisateur, profil: profil);
  }

  /// Crée un compte avant le choix de créer ou rejoindre une tontine.
  Future<void> deconnecter() => authService.signOut();

  Future<void> reinitialiserMotDePasse(String email) =>
      authService.sendPasswordResetEmail(email);

  static const _alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  String _genererCode() {
    final random = Random.secure();
    return List.generate(
      6,
      (_) => _alphabet[random.nextInt(_alphabet.length)],
    ).join();
  }
}
