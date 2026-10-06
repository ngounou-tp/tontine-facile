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
import 'package:tontinefacile/domain/entities/part.dart';
import 'package:tontinefacile/domain/entities/preuve.dart';
import 'package:tontinefacile/domain/entities/profil.dart';
import 'package:tontinefacile/domain/entities/tontine.dart';
import 'package:tontinefacile/domain/entities/tour.dart';
import 'package:tontinefacile/domain/enums/mode_parts.dart';
import 'package:tontinefacile/domain/enums/regle_penalite.dart';
import 'package:tontinefacile/domain/value_objects/regle_periodicite.dart';
import 'package:tontinefacile/features/auth/application/auth_providers.dart';
import 'package:tontinefacile/features/membres/application/membres_controller.dart';

void main() {
  late FakeTontineRepository tontines;
  late FakeProfilRepository profils;
  late ProviderContainer container;

  setUp(() {
    tontines = FakeTontineRepository();
    profils = FakeProfilRepository();
    tontines.saved['t-1'] = Tontine(
      id: 't-1',
      nom: 'Cercle des amies',
      adminUid: 'admin',
      montantParNom: 25000,
      nombreDeNoms: 10,
      datePremiereEcheance: DateTime(2026, 1, 10),
      periodicite: ReglePeriodicite.tousLesNJours(7),
      reglePenalite: ReglePenalite.aucune,
      delaiGraceJours: 0,
      valeurPenalite: null,
      modeParts: ModeParts.montantFixe,
      codeInvitation: 'ABCDEF',
    );
    container = ProviderContainer(
      overrides: [
        tontineRepositoryProvider.overrideWithValue(tontines),
        inscriptionServiceProvider.overrideWithValue(
          InscriptionService(
            authService: FakeAuthService(),
            tontineRepository: tontines,
            profilRepository: profils,
          ),
        ),
      ],
    );
  });

  tearDown(() => container.dispose());

  test('ajouterMembre crée un membre placeholder', () async {
    final notifier = container.read(membresControllerProvider.notifier);

    final membre = await notifier.ajouterMembre(
      tontineId: 't-1',
      nomComplet: 'Marie Ngo',
    );

    expect(membre.nomComplet, 'Marie Ngo');
    expect(membre.uid, isNull);
    expect(tontines.membres[membre.id]?.nomComplet, 'Marie Ngo');
  });

  test(
    'modifierMembre met à jour les coordonnées en conservant id/uid/actif',
    () async {
      tontines.membres['m-1'] = const Membre(
        id: 'm-1',
        nomComplet: 'Ancien nom',
        uid: 'uid-1',
      );
      final notifier = container.read(membresControllerProvider.notifier);

      await notifier.modifierMembre(
        tontineId: 't-1',
        membre: tontines.membres['m-1']!,
        nomComplet: 'Nouveau nom',
        email: 'nouveau@example.com',
      );

      final maj = tontines.membres['m-1']!;
      expect(maj.nomComplet, 'Nouveau nom');
      expect(maj.email, 'nouveau@example.com');
      expect(maj.uid, 'uid-1');
      expect(maj.actif, isTrue);
    },
  );

  test('desactiverMembre puis reactiverMembre basculent le statut actif',
      () async {
    tontines.membres['m-1'] = const Membre(id: 'm-1', nomComplet: 'Marie');
    final notifier = container.read(membresControllerProvider.notifier);

    await notifier.desactiverMembre(
      tontineId: 't-1',
      membre: tontines.membres['m-1']!,
    );
    expect(tontines.membres['m-1']!.actif, isFalse);

    await notifier.reactiverMembre(
      tontineId: 't-1',
      membre: tontines.membres['m-1']!,
    );
    expect(tontines.membres['m-1']!.actif, isTrue);
  });

  test('creerNom valide les parts puis les enregistre', () async {
    final notifier = container.read(membresControllerProvider.notifier);

    final nom = await notifier.creerNom(
      tontineId: 't-1',
      position: 1,
      parts: const [Part(membreId: 'm-1', fraction: 1)],
    );

    expect(tontines.noms[nom.id]?.libelle, 'Nom 1');
    expect(tontines.noms[nom.id]?.parts.single.membreId, 'm-1');
  });

  test("creerNom rejette des parts dont la somme n'est pas 1", () async {
    final notifier = container.read(membresControllerProvider.notifier);

    await expectLater(
      () => notifier.creerNom(
        tontineId: 't-1',
        position: 1,
        parts: const [Part(membreId: 'm-1', fraction: 0.5)],
      ),
      throwsArgumentError,
    );
    expect(tontines.noms, isEmpty);
  });

  test("assignerParts réassigne les détenteurs d'un nom existant", () async {
    tontines.noms['n-1'] = const Nom(
      id: 'n-1',
      position: 1,
      libelle: 'Nom 1',
      parts: [Part(membreId: 'm-1', fraction: 1)],
    );
    final notifier = container.read(membresControllerProvider.notifier);

    await notifier.assignerParts(
      tontineId: 't-1',
      nom: tontines.noms['n-1']!,
      parts: const [
        Part(membreId: 'm-2', fraction: 0.5),
        Part(membreId: 'm-3', fraction: 0.5),
      ],
    );

    final parts = tontines.noms['n-1']!.parts;
    expect(parts.map((p) => p.membreId), containsAll(['m-2', 'm-3']));
  });

  test("assignerParts rejette des parts invalides sans modifier le nom",
      () async {
    const nomInitial = Nom(
      id: 'n-1',
      position: 1,
      libelle: 'Nom 1',
      parts: [Part(membreId: 'm-1', fraction: 1)],
    );
    tontines.noms['n-1'] = nomInitial;
    final notifier = container.read(membresControllerProvider.notifier);

    await expectLater(
      () => notifier.assignerParts(
        tontineId: 't-1',
        nom: nomInitial,
        parts: const [], // liste vide : ValidationParts doit refuser.
      ),
      throwsArgumentError,
    );
    expect(tontines.noms['n-1'], nomInitial);
  });

  test('inviterMembreAvecNoms(1) crée un nom entier lui appartenant seul',
      () async {
    final notifier = container.read(membresControllerProvider.notifier);

    await notifier.inviterMembreAvecNoms(
      tontineId: 't-1',
      nomComplet: 'Rose Domche',
      whatsapp: '+237600000000',
      nombreDeNoms: 1,
    );

    expect(tontines.noms, hasLength(1));
    final nom = tontines.noms.values.single;
    expect(nom.libelle, 'Nom 1');
    expect(nom.parts.single.fraction, 1);
  });

  test('inviterMembreAvecNoms(0.5) ouvre un nom en attente d\'un second '
      'détenteur', () async {
    final notifier = container.read(membresControllerProvider.notifier);

    await notifier.inviterMembreAvecNoms(
      tontineId: 't-1',
      nomComplet: 'Rose Domche',
      whatsapp: '+237600000000',
      nombreDeNoms: 0.5,
    );

    expect(tontines.noms, hasLength(1));
    final nom = tontines.noms.values.single;
    expect(nom.parts.single.fraction, 0.5);
  });

  test(
    'inviterMembreAvecNoms(0.5) complète un nom déjà à moitié attribué '
    'plutôt que d\'en ouvrir un nouveau',
    () async {
      final notifier = container.read(membresControllerProvider.notifier);
      await notifier.inviterMembreAvecNoms(
        tontineId: 't-1',
        nomComplet: 'Rose Domche',
        whatsapp: '+237600000000',
        nombreDeNoms: 0.5,
      );

      await notifier.inviterMembreAvecNoms(
        tontineId: 't-1',
        nomComplet: 'Alice Pouth',
        whatsapp: '+237611111111',
        nombreDeNoms: 0.5,
      );

      expect(tontines.noms, hasLength(1));
      final nom = tontines.noms.values.single;
      expect(nom.parts, hasLength(2));
      expect(
        nom.parts.fold<double>(0, (total, part) => total + part.fraction),
        1,
      );
    },
  );

  test('inviterMembreAvecNoms(1.5) crée un nom entier et un nom en attente',
      () async {
    final notifier = container.read(membresControllerProvider.notifier);

    await notifier.inviterMembreAvecNoms(
      tontineId: 't-1',
      nomComplet: 'Rose Domche',
      whatsapp: '+237600000000',
      nombreDeNoms: 1.5,
    );

    expect(tontines.noms, hasLength(2));
    final fractions = tontines.noms.values.map((n) => n.parts.single.fraction).toList()
      ..sort();
    expect(fractions, [0.5, 1.0]);
  });

  test(
    'attribuerNomsSupplementaires ajoute des noms à un membre déjà enregistré',
    () async {
      tontines.membres['m-1'] = const Membre(id: 'm-1', nomComplet: 'Rose Domche');
      final notifier = container.read(membresControllerProvider.notifier);

      await notifier.attribuerNomsSupplementaires(
        tontineId: 't-1',
        membreId: 'm-1',
        nombreDeNoms: 2,
      );

      expect(tontines.noms, hasLength(2));
      expect(
        tontines.noms.values.every((n) => n.parts.single.membreId == 'm-1'),
        isTrue,
      );
    },
  );

  test(
    'attribuerNomsSupplementaires refuse de dépasser le nombre de noms de '
    'la tontine',
    () async {
      // La tontine du setUp() prévoit nombreDeNoms: 10.
      tontines.membres['m-1'] = const Membre(id: 'm-1', nomComplet: 'Rose Domche');
      final notifier = container.read(membresControllerProvider.notifier);

      await expectLater(
        () => notifier.attribuerNomsSupplementaires(
          tontineId: 't-1',
          membreId: 'm-1',
          nombreDeNoms: 11,
        ),
        throwsA(isA<NamesQuotaExceededException>()),
      );
      expect(tontines.noms, isEmpty);
    },
  );

  test(
    'attribuerNomsSupplementaires accepte exactement le quota restant',
    () async {
      tontines.membres['m-1'] = const Membre(id: 'm-1', nomComplet: 'Rose Domche');
      final notifier = container.read(membresControllerProvider.notifier);

      await notifier.attribuerNomsSupplementaires(
        tontineId: 't-1',
        membreId: 'm-1',
        nombreDeNoms: 10,
      );

      expect(tontines.noms, hasLength(10));
    },
  );

  test(
    'modifierMembre et desactiverMembre conservent le codeInvitation existant',
    () async {
      tontines.membres['m-1'] = const Membre(
        id: 'm-1',
        nomComplet: 'Rose Domche',
        codeInvitation: 'ABC123',
      );
      final notifier = container.read(membresControllerProvider.notifier);

      await notifier.modifierMembre(
        tontineId: 't-1',
        membre: tontines.membres['m-1']!,
        nomComplet: 'Rose D.',
      );
      expect(tontines.membres['m-1']!.codeInvitation, 'ABC123');

      await notifier.desactiverMembre(tontineId: 't-1', membre: tontines.membres['m-1']!);
      expect(tontines.membres['m-1']!.codeInvitation, 'ABC123');
      expect(tontines.membres['m-1']!.actif, isFalse);
    },
  );
}

class FakeTontineRepository implements TontineRepository {
  final Map<String, Tontine> saved = {};
  final Map<String, Membre> membres = {};
  final Map<String, Nom> noms = {};
  final Map<String, Tour> tours = {};
  var _nextId = 0;

  @override
  String nouvelIdTontine() => 'tontine-${_nextId++}';

  @override
  Future<List<Tontine>> getTontines() async => saved.values.toList();

  @override
  Future<Tontine?> getTontine(String tontineId) async => saved[tontineId];

  @override
  Future<void> saveTontine(Tontine tontine) async => saved[tontine.id] = tontine;

  @override
  Future<List<Membre>> getMembres(String tontineId) async => membres.values.toList();

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
  }) async {}

  @override
  Future<List<Nom>> getNoms(String tontineId) async => noms.values.toList();

  @override
  String nouvelIdNom(String tontineId) => 'nom-${_nextId++}';

  @override
  Future<void> saveNom(String tontineId, Nom nom) async => noms[nom.id] = nom;

  @override
  Stream<Tontine?> watchTontine(String tontineId) => Stream.value(saved[tontineId]);
  @override
  Stream<List<Membre>> watchMembres(String tontineId) =>
      Stream.value(membres.values.toList());
  @override
  Stream<List<Nom>> watchNoms(String tontineId) => Stream.value(noms.values.toList());
  @override
  Stream<List<Tour>> watchTours(String tontineId) => Stream.value(tours.values.toList());

  @override
  Future<List<Tour>> getTours(String tontineId) async => tours.values.toList();
  @override
  Future<void> saveTour(String tontineId, Tour tour) async => tours[tour.id] = tour;

  final Map<String, Cotisation> cotisations = {};
  @override
  String nouvelIdCotisation(String tontineId) => 'cotisation-${_nextId++}';
  @override
  Future<List<Cotisation>> getCotisations(String tontineId) async =>
      cotisations.values.toList();
  @override
  Future<void> saveCotisation(String tontineId, Cotisation cotisation) async =>
      cotisations[cotisation.id] = cotisation;
  @override
  Stream<List<Cotisation>> watchCotisations(String tontineId) =>
      Stream.value(cotisations.values.toList());

  final Map<String, Declaration> declarations = {};
  @override
  String nouvelIdDeclaration(String tontineId) => 'declaration-${_nextId++}';
  @override
  Future<List<Declaration>> getDeclarations(String tontineId) async =>
      declarations.values.toList();
  @override
  Future<void> saveDeclaration(String tontineId, Declaration declaration) async =>
      declarations[declaration.id] = declaration;
  @override
  Stream<List<Declaration>> watchDeclarations(String tontineId) =>
      Stream.value(declarations.values.toList());

  final Map<String, Preuve> preuves = {};
  @override
  String nouvelIdPreuve(String tontineId) => 'preuve-${_nextId++}';
  @override
  Future<List<Preuve>> getPreuves(String tontineId) async => preuves.values.toList();
  @override
  Future<void> savePreuve(String tontineId, Preuve preuve) async =>
      preuves[preuve.id] = preuve;

  final Map<String, Changement> changements = {};
  @override
  Future<List<Changement>> getChangements(String tontineId) async => changements.values.toList();
  @override
  Future<void> saveChangement(String tontineId, Changement changement) async =>
      changements[changement.id] = changement;
  @override
  Stream<List<Changement>> watchChangements(String tontineId) =>
      Stream.value(changements.values.toList());
}

class FakeAuthService implements AuthService {
  AppUser? _currentUser;

  @override
  AppUser? get currentUser => _currentUser;

  @override
  Stream<AppUser?> get authStateChanges => Stream.value(_currentUser);

  @override
  Future<AppUser> signUp({required String email, required String password}) async {
    throw UnimplementedError();
  }

  @override
  Future<AppUser> signIn({required String email, required String password}) async {
    throw UnimplementedError();
  }

  @override
  Future<AppUser?> signInWithGoogle() async => null;

  @override
  Future<void> signOut() async {}

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<void> sendEmailVerification() async {}

  @override
  Future<AppUser?> reloadUser() async => _currentUser;
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
