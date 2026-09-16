import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
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
import 'package:tontinefacile/features/auth/application/auth_providers.dart';
import 'package:tontinefacile/features/tontine/presentation/pages/creer_tontine_page.dart';

void main() {
  late FakeAuthService auth;
  late FakeTontineRepository tontines;
  late FakeProfilRepository profils;

  Future<GoRouter> pumpPage(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/creer-tontine',
      routes: [
        GoRoute(path: '/creer-tontine', builder: (_, _) => const CreerTontinePage()),
        GoRoute(path: '/membres', builder: (_, _) => const Text('MEMBRES_PAGE')),
        GoRoute(path: '/bienvenue', builder: (_, _) => const Text('BIENVENUE_PAGE')),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          inscriptionServiceProvider.overrideWithValue(
            InscriptionService(
              authService: auth,
              tontineRepository: tontines,
              profilRepository: profils,
            ),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  setUp(() async {
    auth = FakeAuthService();
    tontines = FakeTontineRepository();
    profils = FakeProfilRepository();
    await auth.signUp(email: 'admin@example.com', password: 'secret123');
  });

  testWidgets('affiche la première étape du formulaire', (tester) async {
    await pumpPage(tester);

    expect(find.text('Étape 1 sur 5'), findsOneWidget);
    expect(find.text('Le groupe'), findsOneWidget);
    expect(find.text('Suivant'), findsOneWidget);
  });

  testWidgets(
    'bloque le passage à l\'étape suivante tant que les champs obligatoires '
    'sont vides',
    (tester) async {
      await pumpPage(tester);

      await tester.tap(find.text('Suivant'));
      await tester.pumpAndSettle();

      expect(find.text('Étape 1 sur 5'), findsOneWidget);
      expect(find.textContaining('nom du groupe'), findsOneWidget);
    },
  );

  testWidgets(
    'parcours complet : remplir, avancer les 5 étapes puis créer la tontine',
    (tester) async {
      final router = await pumpPage(tester);

      await tester.enterText(find.byType(TextFormField).at(0), 'Cercle des amies');
      await tester.enterText(find.byType(TextFormField).at(1), 'Aïcha Ndiaye');
      await tester.enterText(find.byType(TextFormField).at(2), '25000');
      await tester.enterText(find.byType(TextFormField).at(3), '10');
      await tester.ensureVisible(find.text('Choisir une date'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Choisir une date'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Suivant'));
      await tester.pumpAndSettle();
      expect(find.text('Étape 2 sur 5'), findsOneWidget);

      await tester.tap(find.text('Suivant'));
      await tester.pumpAndSettle();
      expect(find.text('Étape 3 sur 5'), findsOneWidget);

      await tester.tap(find.text('Suivant'));
      await tester.pumpAndSettle();
      expect(find.text('Étape 4 sur 5'), findsOneWidget);

      await tester.tap(find.text('Suivant'));
      await tester.pumpAndSettle();
      expect(find.text('Étape 5 sur 5'), findsOneWidget);
      expect(find.text('Confirmation'), findsOneWidget);

      await tester.tap(find.text('Créer la tontine'));
      await tester.pumpAndSettle();

      expect(find.text('MEMBRES_PAGE'), findsOneWidget);
      expect(tontines.saved, hasLength(1));
      expect(tontines.saved.values.single.nom, 'Cercle des amies');
      expect(router.routerDelegate.currentConfiguration.uri.path, '/membres');
    },
  );
}

class FakeAuthService implements AuthService {
  final Map<String, String> comptes = {};
  AppUser? _currentUser;
  var _nextUid = 0;

  @override
  AppUser? get currentUser => _currentUser;

  final _controller = StreamController<AppUser?>.broadcast();

  @override
  Stream<AppUser?> get authStateChanges => _controller.stream;

  @override
  Future<AppUser> signUp({required String email, required String password}) async {
    final uid = comptes[email] ?? 'uid-${_nextUid++}';
    comptes[email] = uid;
    final user = AppUser(uid: uid, email: email);
    _currentUser = user;
    _controller.add(user);
    return user;
  }

  @override
  Future<AppUser> signIn({required String email, required String password}) async {
    throw UnimplementedError();
  }

  @override
  Future<AppUser?> signInWithGoogle() async => null;

  @override
  Future<void> signOut() async {
    _currentUser = null;
    _controller.add(null);
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<void> sendEmailVerification() async {}

  @override
  Future<AppUser?> reloadUser() async => _currentUser;
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
  Future<void> saveTontine(Tontine tontine) async => saved[tontine.id] = tontine;
  @override
  Future<List<Membre>> getMembres(String tontineId) async => membres.values.toList();
  @override
  Future<void> saveMembre(String tontineId, Membre membre) async => membres[membre.id] = membre;

  @override
  Future<Membre> creerMembrePlaceholder(
    String tontineId, {
    required String nomComplet,
    String? email,
    String? whatsapp,
  }) async {
    final membre = Membre(id: 'membre-${_nextId++}', nomComplet: nomComplet, email: email, whatsapp: whatsapp);
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
  String nouvelIdNom(String tontineId) => 'nom-${_nextId++}';
  @override
  Future<void> saveNom(String tontineId, Nom nom) async {}
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
  Future<List<Declaration>> getDeclarations(String tontineId) async => const [];
  @override
  Future<void> saveDeclaration(String tontineId, Declaration declaration) async {}
  @override
  Future<List<Preuve>> getPreuves(String tontineId) async => const [];
  @override
  Future<void> savePreuve(String tontineId, Preuve preuve) async {}
  @override
  Future<List<Changement>> getChangements(String tontineId) async => const [];
  @override
  Future<void> saveChangement(String tontineId, Changement changement) async {}
}

class FakeProfilRepository implements ProfilRepository {
  final Map<String, Profil> profils = {};
  final Map<String, Invitation> invitations = {};

  @override
  Future<Profil?> getProfil(String uid) async => profils[uid];
  @override
  Future<void> saveProfil(Profil profil) async => profils[profil.uid] = profil;
  @override
  Future<Invitation?> getInvitation(String code) async => invitations[code];
  @override
  Future<void> saveInvitation(Invitation invitation) async => invitations[invitation.code] = invitation;
}
