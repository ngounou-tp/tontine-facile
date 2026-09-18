import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import 'package:tontinefacile/features/auth/application/auth_controller.dart';
import 'package:tontinefacile/features/auth/application/auth_providers.dart';
import 'package:tontinefacile/features/auth/presentation/widgets/auth_form.dart';

void main() {
  late FakeAuthService auth;
  late FakeTontineRepository tontines;
  late FakeProfilRepository profils;
  late ProviderContainer container;

  setUp(() {
    auth = FakeAuthService();
    tontines = FakeTontineRepository();
    profils = FakeProfilRepository();
    container = ProviderContainer(
      overrides: [
        inscriptionServiceProvider.overrideWithValue(
          InscriptionService(
            authService: auth,
            tontineRepository: tontines,
            profilRepository: profils,
          ),
        ),
      ],
    );
  });

  tearDown(() => container.dispose());

  test('un nouvel administrateur peut créer un compte', () async {
    final notifier = container.read(authControllerProvider.notifier);

    final session = await notifier.inscrireAdmin(
      email: 'admin@example.com',
      password: 'secret123',
      nomCompletAdmin: 'Aïcha Ndiaye',
      tontineSansId: _brouillonTontine(),
    );

    expect(session.utilisateur.email, 'admin@example.com');
    expect(session.profil, isNotNull);
    expect(
      tontines.saved[session.profil!.tontineId]?.adminUid,
      session.utilisateur.uid,
    );
    expect(container.read(authControllerProvider).hasValue, isTrue);
    expect(container.read(authControllerProvider).hasError, isFalse);
  });

  test(
    'une administratrice déjà inscrite peut se connecter puis se déconnecter',
    () async {
      final notifier = container.read(authControllerProvider.notifier);
      await notifier.inscrireAdmin(
        email: 'admin@example.com',
        password: 'secret123',
        nomCompletAdmin: 'Aïcha Ndiaye',
        tontineSansId: _brouillonTontine(),
      );
      await auth.signOut();
      expect(auth.currentUser, isNull);

      final session = await notifier.connecter(
        email: 'admin@example.com',
        password: 'secret123',
      );

      expect(session.profil, isNotNull);
      expect(auth.currentUser, isNotNull);

      await notifier.deconnecter();

      expect(auth.currentUser, isNull);
    },
  );

  test("un code d'invitation invalide renvoie un message français", () async {
    await auth.signUp(email: 'x@example.com', password: 'secret123');
    final notifier = container.read(authControllerProvider.notifier);

    await expectLater(
      () => notifier.rejoindreAvecCode('ZZZZZZ'),
      throwsA(isA<InvitationIntrouvableException>()),
    );

    final controllerState = container.read(authControllerProvider);
    expect(controllerState.hasError, isTrue);
    expect(
      messageErreurAuth(controllerState.error!),
      "Ce code d'invitation est introuvable.",
    );
  });

  test(
    'la connexion Google crée une session sans profil pour un nouveau compte',
    () async {
      final notifier = container.read(authControllerProvider.notifier);

      final session = await notifier.connecterAvecGoogle();

      expect(session, isNotNull);
      expect(session!.profil, isNull);
      expect(session.utilisateur.emailVerified, isTrue);
    },
  );

  test(
    "la connexion Google renvoie null si l'utilisateur annule sans erreur",
    () async {
      auth.annulerProchainGoogle = true;
      final notifier = container.read(authControllerProvider.notifier);

      final session = await notifier.connecterAvecGoogle();

      expect(session, isNull);
      expect(container.read(authControllerProvider).hasError, isFalse);
    },
  );

  test(
    "l'inscription envoie automatiquement un email de vérification",
    () async {
      final notifier = container.read(authControllerProvider.notifier);
      await notifier.creerCompteSansTontine(
        email: 'nouveau@example.com',
        password: 'secret123',
      );

      expect(auth.emailsVerificationEnvoyes, 1);
    },
  );

  test('renvoyerEmailVerification délègue au service', () async {
    await auth.signUp(email: 'x@example.com', password: 'secret123');
    final notifier = container.read(authControllerProvider.notifier);
    final envoisAvant = auth.emailsVerificationEnvoyes;

    await notifier.renvoyerEmailVerification();

    expect(auth.emailsVerificationEnvoyes, envoisAvant + 1);
  });

  test('verifierEmailVerifie renvoie true une fois le compte rechargé vérifié',
      () async {
    await auth.signUp(email: 'x@example.com', password: 'secret123');
    final notifier = container.read(authControllerProvider.notifier);

    expect(await notifier.verifierEmailVerifie(), isFalse);

    auth.prochainRechargeVerifie = true;
    expect(await notifier.verifierEmailVerifie(), isTrue);
  });
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
  Future<void> sendPasswordResetEmail(String email) async {}

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

  @override
  Future<Profil?> getProfil(String uid) async => profils[uid];
  @override
  Stream<Profil?> watchProfil(String uid) => Stream.value(profils[uid]);

  @override
  Future<void> saveProfil(Profil profil) async => profils[profil.uid] = profil;

  @override
  Future<Invitation?> getInvitation(String code) async => invitations[code];

  @override
  Future<void> saveInvitation(Invitation invitation) async =>
      invitations[invitation.code] = invitation;
}
