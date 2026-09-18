import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tontinefacile/core/errors/app_exception.dart';
import 'package:tontinefacile/data/repositories/profil_repository.dart';
import 'package:tontinefacile/data/repositories/tontine_repository.dart';
import 'package:tontinefacile/data/services/auth_service.dart';
import 'package:tontinefacile/data/services/inscription_service.dart';
import 'package:tontinefacile/domain/entities/app_user.dart';
import 'package:tontinefacile/domain/entities/changement.dart';
import 'package:tontinefacile/domain/entities/cotisation.dart';
import 'package:tontinefacile/domain/entities/declaration.dart';
import 'package:tontinefacile/domain/entities/invitation.dart';
import 'package:tontinefacile/domain/entities/membre.dart';
import 'package:tontinefacile/domain/entities/nom.dart';
import 'package:tontinefacile/domain/entities/preuve.dart';
import 'package:tontinefacile/domain/entities/profil.dart';
import 'package:tontinefacile/domain/entities/tontine.dart';
import 'package:tontinefacile/domain/entities/tour.dart';
import 'package:tontinefacile/domain/enums/mode_parts.dart';
import 'package:tontinefacile/domain/enums/regle_penalite.dart';
import 'package:tontinefacile/domain/value_objects/regle_periodicite.dart';

void main() {
  late FakeAuthService auth;
  late FakeTontineRepository tontines;
  late FakeProfilRepository profils;
  late InscriptionService service;

  setUp(() {
    auth = FakeAuthService();
    tontines = FakeTontineRepository();
    profils = FakeProfilRepository();
    service = InscriptionService(
      authService: auth,
      tontineRepository: tontines,
      profilRepository: profils,
    );
  });

  test('inscrireAdmin crée le compte, la tontine, le membre et le profil',
      () async {
    final session = await service.inscrireAdmin(
      email: 'admin@example.com',
      password: 'secret123',
      nomCompletAdmin: 'Aïcha Ndiaye',
      tontineSansId: _brouillonTontine(),
    );

    expect(session.utilisateur.email, 'admin@example.com');
    expect(session.profil, isNotNull);

    final tontine = tontines.saved[session.profil!.tontineId];
    expect(tontine, isNotNull);
    expect(tontine!.adminUid, session.utilisateur.uid);
    expect(tontine.codeInvitation, hasLength(6));

    final membre = tontines.membres[session.profil!.membreId];
    expect(membre?.nomComplet, 'Aïcha Ndiaye');
    expect(membre?.uid, session.utilisateur.uid);
  });

  test('inscrireAdmin rejette une tontine invalide sans créer aucun compte',
      () async {
    final brouillon = _brouillonTontine();
    final tontineInvalide = Tontine(
      id: brouillon.id,
      nom: 'x', // moins de 2 caractères : ValidationTontine doit refuser.
      adminUid: brouillon.adminUid,
      montantParNom: brouillon.montantParNom,
      nombreDeNoms: brouillon.nombreDeNoms,
      datePremiereEcheance: brouillon.datePremiereEcheance,
      periodicite: brouillon.periodicite,
      reglePenalite: brouillon.reglePenalite,
      delaiGraceJours: brouillon.delaiGraceJours,
      valeurPenalite: brouillon.valeurPenalite,
      modeParts: brouillon.modeParts,
      codeInvitation: brouillon.codeInvitation,
    );

    expect(
      () => service.inscrireAdmin(
        email: 'admin@example.com',
        password: 'secret123',
        nomCompletAdmin: 'Aïcha Ndiaye',
        tontineSansId: tontineInvalide,
      ),
      throwsArgumentError,
    );
    expect(tontines.saved, isEmpty);
  });

  test(
    'creerTontinePourAdmin crée la tontine pour un compte déjà connecté',
    () async {
      await auth.signUp(email: 'admin@example.com', password: 'secret123');

      final session = await service.creerTontinePourAdmin(
        nomCompletAdmin: 'Aïcha Ndiaye',
        tontineSansId: _brouillonTontine(),
      );

      expect(session.profil, isNotNull);
      final tontine = tontines.saved[session.profil!.tontineId];
      expect(tontine, isNotNull);
      expect(tontine!.adminUid, session.utilisateur.uid);

      final membre = tontines.membres[session.profil!.membreId];
      expect(membre?.nomComplet, 'Aïcha Ndiaye');
      expect(membre?.uid, session.utilisateur.uid);
    },
  );

  test(
    'creerTontinePourAdmin échoue si personne n’est connecté',
    () async {
      expect(
        () => service.creerTontinePourAdmin(
          nomCompletAdmin: 'Aïcha Ndiaye',
          tontineSansId: _brouillonTontine(),
        ),
        throwsA(isA<UnknownAuthException>()),
      );
    },
  );

  test('inviterMembre puis inscrireMembre relie le nouveau compte au '
      'placeholder', () async {
    final admin = await service.inscrireAdmin(
      email: 'admin@example.com',
      password: 'secret123',
      nomCompletAdmin: 'Aïcha Ndiaye',
      tontineSansId: _brouillonTontine(),
    );
    final tontineId = admin.profil!.tontineId;

    final invitation = await service.inviterMembre(
      tontineId: tontineId,
      nomComplet: 'Marie Ngo',
    );
    expect(invitation.code, hasLength(6));
    expect(tontines.membres[invitation.membreId]?.uid, isNull);

    final session = await service.inscrireMembre(
      email: 'marie@example.com',
      password: 'secret123',
      codeInvitation: invitation.code,
    );

    expect(session.profil?.tontineId, tontineId);
    expect(session.profil?.membreId, invitation.membreId);
    expect(tontines.membres[invitation.membreId]?.uid, session.utilisateur.uid);
  });

  test('inscrireMembre normalise la casse et les espaces du code', () async {
    final admin = await service.inscrireAdmin(
      email: 'admin@example.com',
      password: 'secret123',
      nomCompletAdmin: 'Aïcha Ndiaye',
      tontineSansId: _brouillonTontine(),
    );
    final invitation = await service.inviterMembre(
      tontineId: admin.profil!.tontineId,
      nomComplet: 'Marie Ngo',
    );

    final session = await service.inscrireMembre(
      email: 'marie@example.com',
      password: 'secret123',
      codeInvitation: '  ${invitation.code.toLowerCase()}  ',
    );

    expect(session.profil?.membreId, invitation.membreId);
  });

  test('inscrireMembre avec un code inconnu lance '
      'InvitationIntrouvableException', () async {
    expect(
      () => service.inscrireMembre(
        email: 'x@example.com',
        password: 'secret123',
        codeInvitation: 'ZZZZZZ',
      ),
      throwsA(isA<InvitationIntrouvableException>()),
    );
    expect(auth.comptesCrees, isEmpty);
  });

  test('inscrireMembre sur un placeholder déjà réclamé lance '
      'InvitationDejaUtiliseeException', () async {
    final admin = await service.inscrireAdmin(
      email: 'admin@example.com',
      password: 'secret123',
      nomCompletAdmin: 'Aïcha Ndiaye',
      tontineSansId: _brouillonTontine(),
    );
    final invitation = await service.inviterMembre(
      tontineId: admin.profil!.tontineId,
      nomComplet: 'Marie Ngo',
    );
    tontines.rejetterProchainClaim();

    expect(
      () => service.inscrireMembre(
        email: 'marie@example.com',
        password: 'secret123',
        codeInvitation: invitation.code,
      ),
      throwsA(isA<InvitationDejaUtiliseeException>()),
    );
  });

  test('connecter charge le profil existant', () async {
    auth.comptes['membre@example.com'] = 'uid-membre';
    await profils.saveProfil(
      const Profil(uid: 'uid-membre', tontineId: 't-1', membreId: 'm-1'),
    );

    final session = await service.connecter(
      email: 'membre@example.com',
      password: 'secret123',
    );

    expect(session.utilisateur.uid, 'uid-membre');
    expect(session.profil?.tontineId, 't-1');
  });

  test('connecter sans profil renvoie une session sans tontine', () async {
    auth.comptes['nouveau@example.com'] = 'uid-nouveau';

    final session = await service.connecter(
      email: 'nouveau@example.com',
      password: 'secret123',
    );

    expect(session.profil, isNull);
  });

  test('deconnecter délègue à authService.signOut', () async {
    await auth.signUp(email: 'a@example.com', password: 'secret123');
    expect(auth.currentUser, isNotNull);

    await service.deconnecter();

    expect(auth.currentUser, isNull);
  });

  test('reinitialiserMotDePasse délègue à authService', () async {
    await service.reinitialiserMotDePasse('oubli@example.com');

    expect(auth.dernierResetEmail, 'oubli@example.com');
  });

  test('apercuInvitation renvoie le nom et le nombre de membres', () async {
    final admin = await service.inscrireAdmin(
      email: 'admin@example.com',
      password: 'secret123',
      nomCompletAdmin: 'Aïcha Ndiaye',
      tontineSansId: _brouillonTontine(),
    );
    final invitation = await service.inviterMembre(
      tontineId: admin.profil!.tontineId,
      nomComplet: 'Marie Ngo',
    );

    final apercu = await service.apercuInvitation(invitation.code);

    expect(apercu?.nom, 'Cercle des amies');
    expect(apercu?.nombreMembres, 2); // l'admin elle-même + le placeholder
  });

  test('apercuInvitation renvoie null pour un code inconnu', () async {
    expect(await service.apercuInvitation('ZZZZZZ'), isNull);
  });

  test('session émet un utilisateur avec profil puis null à la déconnexion',
      () async {
    final session = await service.inscrireAdmin(
      email: 'admin@example.com',
      password: 'secret123',
      nomCompletAdmin: 'Aïcha Ndiaye',
      tontineSansId: _brouillonTontine(),
    );

    final evenements = <bool>[];
    final sub = service.session.listen((value) {
      evenements.add(value != null);
    });

    await auth.signOut();
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();

    expect(session.profil, isNotNull);
    expect(evenements, contains(false));
  });

  test(
    'session émet le profil dès qu\'il apparaît, sans nouvel événement '
    'Firebase Auth (rejoindre une tontine sans se reconnecter)',
    () async {
      // Compte déjà authentifié mais sans profil — le cas exact d'une
      // personne qui vient de saisir un code d'invitation sur un compte
      // existant : `rejoindreAvecCode` crée le profil, mais Firebase Auth
      // ne réémet rien puisque l'utilisateur reste connecté.
      //
      // On s'abonne à `session` AVANT `signUp` : `authStateChanges` est un
      // flux broadcast qui ne rejoue rien aux abonnés tardifs, donc un
      // abonnement après coup manquerait l'émission initiale.
      final profilsEmis = <Profil?>[];
      final sub = service.session.listen((value) => profilsEmis.add(value?.profil));
      await Future<void>.delayed(Duration.zero);

      final utilisateur = await auth.signUp(email: 'membre@example.com', password: 'secret123');
      await Future<void>.delayed(Duration.zero);
      expect(profilsEmis.last, isNull);

      await profils.saveProfil(
        Profil(uid: utilisateur.uid, tontineId: 't-1', membreId: 'm-1'),
      );
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(profilsEmis.last, isNotNull);
      expect(profilsEmis.last!.tontineId, 't-1');
    },
  );
}

Tontine _brouillonTontine() => Tontine(
      id: 'ignore',
      nom: 'Cercle des amies',
      adminUid: 'ignore',
      montantParNom: 25000,
      nombreDeNoms: 10,
      datePremiereEcheance: DateTime(2026, 1, 10),
      periodicite: ReglePeriodicite.tousLesNJours(7),
      reglePenalite: ReglePenalite.aucune,
      delaiGraceJours: 0,
      valeurPenalite: null,
      modeParts: ModeParts.montantFixe,
      codeInvitation: 'IGNORE',
    );

class FakeAuthService implements AuthService {
  final Map<String, String> comptes = {}; // email -> uid
  final List<String> comptesCrees = [];
  String? dernierResetEmail;
  int emailsVerificationEnvoyes = 0;
  bool annulerProchainGoogle = false;
  bool prochainRechargeVerifie = false;
  AppUser? _currentUser;
  var _nextUid = 0;

  @override
  AppUser? get currentUser => _currentUser;

  final _controller = StreamController<AppUser?>.broadcast();

  @override
  Stream<AppUser?> get authStateChanges => _controller.stream;

  void _notify(AppUser? user) => _controller.add(user);

  @override
  Future<AppUser> signUp({
    required String email,
    required String password,
  }) async {
    final uid = comptes[email] ?? 'uid-${_nextUid++}';
    comptes[email] = uid;
    comptesCrees.add(email);
    final user = AppUser(uid: uid, email: email);
    _currentUser = user;
    _notify(user);
    return user;
  }

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final uid = comptes[email];
    if (uid == null) {
      throw const InvalidCredentialsException();
    }
    final user = AppUser(uid: uid, email: email);
    _currentUser = user;
    _notify(user);
    return user;
  }

  @override
  Future<AppUser?> signInWithGoogle() async {
    if (annulerProchainGoogle) {
      annulerProchainGoogle = false;
      return null;
    }
    final uid = 'uid-google-${_nextUid++}';
    final user = AppUser(uid: uid, email: 'google@example.com', emailVerified: true);
    _currentUser = user;
    _notify(user);
    return user;
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    _notify(null);
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    dernierResetEmail = email;
  }

  @override
  Future<void> sendEmailVerification() async {
    emailsVerificationEnvoyes++;
  }

  @override
  Future<AppUser?> reloadUser() async {
    final utilisateur = _currentUser;
    if (utilisateur == null) return null;
    if (prochainRechargeVerifie) {
      _currentUser = AppUser(
        uid: utilisateur.uid,
        email: utilisateur.email,
        emailVerified: true,
      );
    }
    return _currentUser;
  }
}

class FakeTontineRepository implements TontineRepository {
  final Map<String, Tontine> saved = {};
  final Map<String, Membre> membres = {};
  var _nextId = 0;
  var _rejeterProchainClaim = false;

  void rejetterProchainClaim() => _rejeterProchainClaim = true;

  @override
  String nouvelIdTontine() => 'tontine-${_nextId++}';

  @override
  Future<List<Tontine>> getTontines() async => saved.values.toList();

  @override
  Future<Tontine?> getTontine(String tontineId) async => saved[tontineId];

  @override
  Future<void> saveTontine(Tontine tontine) async =>
      saved[tontine.id] = tontine;

  @override
  Future<List<Membre>> getMembres(String tontineId) async =>
      membres.values.toList();

  @override
  Future<void> saveMembre(String tontineId, Membre membre) async =>
      membres[membre.id] = membre;

  @override
  Future<Membre> creerMembrePlaceholder(
    String tontineId, {
    required String nomComplet,
    String? email,
    String? whatsapp,
  }) async {
    final membre = Membre(
      id: 'membre-${_nextId++}',
      nomComplet: nomComplet,
      email: email,
      whatsapp: whatsapp,
    );
    membres[membre.id] = membre;
    return membre;
  }

  @override
  Future<void> claimMembre({
    required String tontineId,
    required String membreId,
    required String uid,
    required String codeInvitation,
  }) async {
    if (_rejeterProchainClaim) {
      _rejeterProchainClaim = false;
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
      );
    }
    final actuel = membres[membreId]!;
    membres[membreId] = Membre(
      id: actuel.id,
      nomComplet: actuel.nomComplet,
      email: actuel.email,
      whatsapp: actuel.whatsapp,
      uid: uid,
      actif: actuel.actif,
    );
  }

  @override
  Future<List<Nom>> getNoms(String tontineId) async => const [];
  @override
  Future<void> saveNom(String tontineId, Nom nom) async {}
  @override
  String nouvelIdNom(String tontineId) => 'nom-${_nextId++}';
  @override
  Stream<Tontine?> watchTontine(String tontineId) => Stream.value(saved[tontineId]);
  @override
  Stream<List<Membre>> watchMembres(String tontineId) => Stream.value(membres.values.toList());
  @override
  Stream<List<Nom>> watchNoms(String tontineId) => Stream.value(const []);
  @override
  Stream<List<Tour>> watchTours(String tontineId) => Stream.value(const []);
  @override
  Future<List<Tour>> getTours(String tontineId) async => const [];
  @override
  Future<void> saveTour(String tontineId, Tour tour) async {}
  @override
  Future<List<Cotisation>> getCotisations(String tontineId) async => const [];
  @override
  Future<void> saveCotisation(String tontineId, Cotisation cotisation) async {}
  @override
  String nouvelIdCotisation(String tontineId) => 'cotisation-${_nextId++}';
  @override
  Stream<List<Cotisation>> watchCotisations(String tontineId) => Stream.value(const []);
  @override
  Future<List<Declaration>> getDeclarations(String tontineId) async =>
      const [];
  @override
  Future<void> saveDeclaration(
    String tontineId,
    Declaration declaration,
  ) async {}
  @override
  Future<List<Preuve>> getPreuves(String tontineId) async => const [];
  @override
  Future<void> savePreuve(String tontineId, Preuve preuve) async {}
  @override
  String nouvelIdDeclaration(String tontineId) => 'declaration-${_nextId++}';
  @override
  Stream<List<Declaration>> watchDeclarations(String tontineId) => Stream.value(const []);
  @override
  String nouvelIdPreuve(String tontineId) => 'preuve-${_nextId++}';
  @override
  Future<List<Changement>> getChangements(String tontineId) async => const [];
  @override
  Future<void> saveChangement(
    String tontineId,
    Changement changement,
  ) async {}
  @override
  Stream<List<Changement>> watchChangements(String tontineId) => Stream.value(const []);
}

class FakeProfilRepository implements ProfilRepository {
  final Map<String, Profil> profils = {};
  final Map<String, Invitation> invitations = {};

  // Un vrai flux (pas Stream.value, qui n'émettrait qu'une fois) : nécessaire
  // pour vérifier que `InscriptionService.session` réagit bien à un profil
  // qui apparaît/change SANS nouvel événement Firebase Auth (voir le test de
  // régression ci-dessous).
  final _controller = StreamController<Profil?>.broadcast();

  @override
  Future<Profil?> getProfil(String uid) async => profils[uid];
  @override
  Stream<Profil?> watchProfil(String uid) async* {
    yield profils[uid];
    yield* _controller.stream.map((_) => profils[uid]);
  }

  @override
  Future<void> saveProfil(Profil profil) async {
    profils[profil.uid] = profil;
    _controller.add(profil);
  }

  @override
  Future<Invitation?> getInvitation(String code) async => invitations[code];

  @override
  Future<void> saveInvitation(Invitation invitation) async =>
      invitations[invitation.code] = invitation;
}
