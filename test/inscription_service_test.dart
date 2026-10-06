import 'package:flutter_test/flutter_test.dart';
import 'package:tontinefacile/core/errors/app_exception.dart';
import 'package:tontinefacile/data/services/inscription_service.dart';
import 'package:tontinefacile/domain/entities/adhesion.dart';
import 'package:tontinefacile/domain/entities/app_user.dart';
import 'package:tontinefacile/domain/entities/session.dart';
import 'package:tontinefacile/domain/entities/tontine.dart';
import 'package:tontinefacile/domain/enums/mode_parts.dart';
import 'package:tontinefacile/domain/enums/regle_penalite.dart';
import 'package:tontinefacile/domain/enums/role_membre.dart';
import 'package:tontinefacile/domain/enums/type_groupe.dart';
import 'package:tontinefacile/domain/value_objects/regle_periodicite.dart';

import 'support/fakes.dart';

Tontine _brouillon({String nom = 'Cercle des amies'}) => Tontine(
      id: 'ignore',
      nom: nom,
      adminUid: 'ignore',
      montantParNom: 25000,
      nombreDeNoms: 10,
      datePremiereEcheance: DateTime(2026, 11, 1),
      periodicite: ReglePeriodicite.tousLesNJours(7),
      reglePenalite: ReglePenalite.aucune,
      delaiGraceJours: 0,
      valeurPenalite: null,
      modeParts: ModeParts.montantFixe,
    );

const _adele = AppUser(uid: 'uid-adele', email: 'adele@example.com', emailVerified: true);

Adhesion _adhesion(String groupeId, {Set<RoleMembre> roles = const {RoleMembre.membre}}) => Adhesion(
      groupeId: groupeId,
      membreId: 'membre-$groupeId',
      nomGroupe: 'Groupe $groupeId',
      type: TypeGroupe.tontine,
      roles: roles,
    );

void main() {
  late FakeAuthService auth;
  late FakeGroupesRepository groupes;
  late FakePreferencesSession preferences;
  late InscriptionService service;

  void creerService({AppUser? utilisateur, bool confirmationRequise = false}) {
    auth = FakeAuthService(utilisateur: utilisateur, confirmationRequise: confirmationRequise);
    groupes = FakeGroupesRepository(auth: auth);
    preferences = FakePreferencesSession();
    service = InscriptionService(authService: auth, groupes: groupes, preferences: preferences);
  }

  /// Première session émise qui satisfait [condition].
  Future<Session?> sessionOu(bool Function(Session? session) condition) =>
      service.session.firstWhere(condition).timeout(const Duration(seconds: 2));

  setUp(creerService);

  group('création de tontine', () {
    test('le compte connecté devient propriétaire et trésorier, et la tontine est affichée', () async {
      creerService(utilisateur: _adele);

      final groupeId = await service.creerTontine(
        nomCompletAdmin: '  Adèle Tchoumi ',
        tontineSansId: _brouillon(),
      );

      final session = await sessionOu((s) => s?.profil != null);
      expect(session!.profil!.tontineId, groupeId);
      expect(session.profil!.estGestionnaire, isTrue);
      expect(session.profil!.roles, {RoleMembre.proprietaire, RoleMembre.tresorier});
      expect(preferences.groupeCourant(_adele.uid), groupeId);
    });

    test('une tontine invalide est refusée avant tout appel au serveur', () async {
      creerService(utilisateur: _adele);

      await expectLater(
        () => service.creerTontine(nomCompletAdmin: 'Adèle', tontineSansId: _brouillon(nom: 'x')),
        throwsArgumentError,
      );
      expect(groupes.adhesionsParUid, isEmpty);
    });

    test('sans session, la création est refusée', () async {
      await expectLater(
        () => service.creerTontine(nomCompletAdmin: 'Adèle', tontineSansId: _brouillon()),
        throwsA(isA<SignInRequiredException>()),
      );
    });
  });

  group('inscription', () {
    test('sans code : compte créé et connecté', () async {
      final issue = await service.inscrire(email: 'bruno@example.com', password: 'secret1');

      expect(issue, IssueInscription.connecte);
      expect(auth.currentUser?.email, 'bruno@example.com');
    });

    test("avec un code : le compte rejoint aussitôt le groupe, qui devient l'affiché", () async {
      groupes.invitations['ABC123'] = (groupeId: 'g1', membreId: 'm-bruno', nomGroupe: 'Njangi');

      await service.inscrire(email: 'bruno@example.com', password: 'secret1', codeInvitation: ' abc123 ');

      final session = await sessionOu((s) => s?.profil != null);
      expect(session!.profil!.tontineId, 'g1');
      expect(session.profil!.membreId, 'm-bruno');
      expect(session.profil!.estGestionnaire, isFalse);
    });

    test('email à confirmer : le code est mis de côté puis réclamé à la première connexion', () async {
      creerService(confirmationRequise: true);
      groupes.invitations['ABC123'] = (groupeId: 'g1', membreId: 'm-bruno', nomGroupe: 'Njangi');

      final issue =
          await service.inscrire(email: 'bruno@example.com', password: 'secret1', codeInvitation: 'ABC123');

      expect(issue, IssueInscription.confirmationRequise);
      expect(auth.currentUser, isNull);
      expect(preferences.codeInvitationEnAttente, 'ABC123');

      // Le lien de confirmation ouvre une session.
      final premiereSession = sessionOu((s) => s?.profil != null);
      auth.connecterDirectement(const AppUser(uid: 'uid-bruno', email: 'bruno@example.com', emailVerified: true));

      final session = await premiereSession;
      expect(session!.profil!.tontineId, 'g1');
      expect(preferences.codeInvitationEnAttente, isNull);
    });

    test("un code inconnu est signalé avant de créer le compte", () async {
      await expectLater(
        () => service.inscrire(email: 'bruno@example.com', password: 'secret1', codeInvitation: 'ZZZZZZ'),
        throwsA(isA<InvitationIntrouvableException>()),
      );
      expect(auth.comptes, isEmpty);
    });

    test('un code déjà utilisé est signalé avant de créer le compte', () async {
      groupes.invitations['ABC123'] = (groupeId: 'g1', membreId: 'm-bruno', nomGroupe: 'Njangi');
      groupes.codesUtilises.add('ABC123');

      await expectLater(
        () => service.inscrire(email: 'bruno@example.com', password: 'secret1', codeInvitation: 'ABC123'),
        throwsA(isA<InvitationDejaUtiliseeException>()),
      );
      expect(auth.comptes, isEmpty);
    });
  });

  group('adhésion par code', () {
    test('normalise casse et espaces, puis affiche le groupe rejoint', () async {
      creerService(utilisateur: _adele);
      groupes.invitations['ABC123'] = (groupeId: 'g1', membreId: 'm-adele', nomGroupe: 'Njangi');

      final groupeId = await service.rejoindreAvecCode('  abc123 ');

      expect(groupeId, 'g1');
      expect(preferences.groupeCourant(_adele.uid), 'g1');
    });

    test('rejoindre deux fois le même groupe est refusé', () async {
      creerService(utilisateur: _adele);
      groupes.invitations['ABC123'] = (groupeId: 'g1', membreId: 'm-1', nomGroupe: 'Njangi');
      groupes.invitations['DEF456'] = (groupeId: 'g1', membreId: 'm-2', nomGroupe: 'Njangi');
      await service.rejoindreAvecCode('ABC123');

      await expectLater(() => service.rejoindreAvecCode('DEF456'), throwsA(isA<DejaMembreException>()));
    });

    test("sans session, l'adhésion est refusée", () async {
      await expectLater(() => service.rejoindreAvecCode('ABC123'), throwsA(isA<SignInRequiredException>()));
    });

    test("l'aperçu donne le nom du groupe, ou null pour un code inconnu", () async {
      groupes.invitations['ABC123'] = (groupeId: 'g1', membreId: 'm-1', nomGroupe: 'Njangi');

      expect((await service.apercuInvitation(' abc123'))?.nomGroupe, 'Njangi');
      expect(await service.apercuInvitation('ZZZZZZ'), isNull);
    });
  });

  group('session et groupes multiples', () {
    test('affiche le dernier groupe choisi, et en change à la demande', () async {
      creerService(utilisateur: _adele);
      groupes.ajouterAdhesion(_adele.uid, _adhesion('g1', roles: const {RoleMembre.proprietaire}));
      groupes.ajouterAdhesion(_adele.uid, _adhesion('g2'));

      final initiale = await sessionOu((s) => s?.adhesions.length == 2);
      expect(initiale!.profil!.tontineId, 'g1', reason: 'premier groupe par défaut');
      expect(initiale.profil!.estGestionnaire, isTrue);

      final apresChoix = sessionOu((s) => s?.profil?.tontineId == 'g2');
      await service.choisirGroupe('g2');
      final session = await apresChoix;
      expect(session!.profil!.estGestionnaire, isFalse, reason: 'les rôles suivent le groupe affiché');
    });

    test("un groupe choisi qui n'est plus accessible est remplacé par le premier", () {
      final adhesions = [_adhesion('g1'), _adhesion('g2')];

      expect(InscriptionService.groupeAffiche(adhesions, 'g2')?.groupeId, 'g2');
      expect(InscriptionService.groupeAffiche(adhesions, 'g-supprime')?.groupeId, 'g1');
      expect(InscriptionService.groupeAffiche(const [], 'g1'), isNull);
    });

    test('sans groupe, la session existe mais sans groupe affiché', () async {
      creerService(utilisateur: _adele);

      final session = await sessionOu((s) => s != null);
      expect(session!.profil, isNull);
      expect(session.adhesions, isEmpty);
    });

    test('la déconnexion émet une session nulle', () async {
      creerService(utilisateur: _adele);
      await sessionOu((s) => s != null);

      final deconnexion = sessionOu((s) => s == null);
      await service.deconnecter();
      expect(await deconnexion, isNull);
    });
  });
}
