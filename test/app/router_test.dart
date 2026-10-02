import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tontinefacile/app/router.dart';
import 'package:tontinefacile/core/errors/app_exception.dart';
import 'package:tontinefacile/data/repositories/profil_repository.dart';
import 'package:tontinefacile/data/repositories/tontine_repository.dart';
import 'package:tontinefacile/data/services/auth_service.dart';
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
import 'package:tontinefacile/features/auth/application/auth_providers.dart';
import 'package:tontinefacile/features/onboarding/application/onboarding_provider.dart';

void main() {
  Future<GoRouter> pumpRouter(
    WidgetTester tester, {
    required ProviderContainer container,
  }) async {
    // `AppRouter.redirect` only `ref.read`s `sessionProvider` and
    // `currentTontineProvider`; without an active container-level listener,
    // these StreamProvider/FutureProvider never leave `AsyncLoading` under
    // `flutter_test` (the internal `Ref.listen` in `_RouterRefreshNotifier`
    // isn't enough to kick off their scheduler on its own).
    container.listen(sessionProvider, (_, _) {});
    container.listen(currentTontineProvider, (_, _) {});

    final router = container.read(appRouterProvider);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  String currentPath(GoRouter router) =>
      router.routerDelegate.currentConfiguration.uri.path;

  testWidgets(
    'un visiteur non connecté ne peut pas ouvrir /accueil : il est renvoyé '
    'vers /connexion',
    (tester) async {
      final container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(FakeAuthService(null)),
          tontineRepositoryProvider.overrideWithValue(
            FakeTontineRepository(),
          ),
          profilRepositoryProvider.overrideWithValue(FakeProfilRepository()),
        ],
      );
      addTearDown(container.dispose);

      final router = await pumpRouter(tester, container: container);
      router.go(AppRouter.accueilPath);
      await tester.pumpAndSettle();

      expect(currentPath(router), AppRouter.connexionPath);
    },
  );

  testWidgets(
    "au premier lancement, un visiteur découvre l'app (/decouvrir) ; une fois "
    "l'onboarding vu, il n'y revient plus et atterrit sur /connexion",
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(FakeAuthService(null)),
          tontineRepositoryProvider.overrideWithValue(FakeTontineRepository()),
          profilRepositoryProvider.overrideWithValue(FakeProfilRepository()),
          sharedPreferencesProvider.overrideWithValue(preferences),
        ],
      );
      addTearDown(container.dispose);

      final router = await pumpRouter(tester, container: container);
      router.go(AppRouter.connexionPath);
      await tester.pumpAndSettle();
      expect(currentPath(router), AppRouter.onboardingPath);

      await container.read(onboardingVuProvider.notifier).terminer();
      router.go(AppRouter.onboardingPath);
      await tester.pumpAndSettle();
      expect(currentPath(router), AppRouter.connexionPath);
      expect(preferences.getBool('onboarding_vu_v1'), isTrue);
    },
  );

  testWidgets(
    'un compte non vérifié est renvoyé vers /verifier-email, même avec un '
    'profil valide (flutter test résout FIREBASE_ENV en "live" par défaut)',
    (tester) async {
      final tontines = FakeTontineRepository()
        ..saved['t-1'] = _tontine(adminUid: 'uid-admin');
      final profils = FakeProfilRepository()
        ..profils['uid-admin'] = const Profil(
          uid: 'uid-admin',
          tontineId: 't-1',
          membreId: 'm-1',
        );
      final container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(
            // emailVerified reste à sa valeur par défaut : false.
            FakeAuthService(const AppUser(uid: 'uid-admin')),
          ),
          tontineRepositoryProvider.overrideWithValue(tontines),
          profilRepositoryProvider.overrideWithValue(profils),
        ],
      );
      addTearDown(container.dispose);

      final router = await pumpRouter(tester, container: container);
      router.go(AppRouter.accueilPath);
      await tester.pumpAndSettle();

      expect(currentPath(router), AppRouter.verifyEmailPath);
    },
  );

  testWidgets(
    'un membre consulte Accueil, Membres, Échéancier, Réglages, '
    'Déclarations et Cotisations (qui a déjà contribué) en lecture seule, '
    'mais ne peut pas ouvrir /membres/ajouter : il est renvoyé vers '
    '/espace-membre',
    (tester) async {
      final tontines = FakeTontineRepository()
        ..saved['t-1'] = _tontine(adminUid: 'uid-admin');
      final profils = FakeProfilRepository()
        ..profils['uid-membre'] = const Profil(
          uid: 'uid-membre',
          tontineId: 't-1',
          membreId: 'm-1',
        );
      final container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(
            FakeAuthService(
              const AppUser(uid: 'uid-membre', emailVerified: true),
            ),
          ),
          tontineRepositoryProvider.overrideWithValue(tontines),
          profilRepositoryProvider.overrideWithValue(profils),
        ],
      );
      addTearDown(container.dispose);

      final router = await pumpRouter(tester, container: container);

      for (final lecture in [
        AppRouter.accueilPath,
        AppRouter.membresPath,
        AppRouter.echeancierPath,
        AppRouter.reglagesPath,
        AppRouter.declarationsPath,
        '${AppRouter.cotisationsPath}/tour-1',
      ]) {
        router.go(lecture);
        await tester.pumpAndSettle();
        expect(currentPath(router), lecture);
      }

      router.go('${AppRouter.membresPath}/ajouter');
      await tester.pumpAndSettle();
      expect(currentPath(router), AppRouter.espaceMembrePath);
    },
  );

  testWidgets(
    "à titre de comparaison, l'administratrice de la tontine peut ouvrir "
    '/membres',
    (tester) async {
      final tontines = FakeTontineRepository()
        ..saved['t-1'] = _tontine(adminUid: 'uid-admin');
      final profils = FakeProfilRepository()
        ..profils['uid-admin'] = const Profil(
          uid: 'uid-admin',
          tontineId: 't-1',
          membreId: 'm-1',
        );
      final container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(
            FakeAuthService(
              const AppUser(uid: 'uid-admin', emailVerified: true),
            ),
          ),
          tontineRepositoryProvider.overrideWithValue(tontines),
          profilRepositoryProvider.overrideWithValue(profils),
        ],
      );
      addTearDown(container.dispose);

      final router = await pumpRouter(tester, container: container);
      router.go(AppRouter.membresPath);
      await tester.pumpAndSettle();

      expect(currentPath(router), AppRouter.membresPath);
    },
  );

  testWidgets(
    'un compte qui vient de rejoindre une tontine (profil pas encore '
    "propagé au moment de la navigation) finit par atterrir sur "
    '/espace-membre sans navigation explicite supplémentaire',
    (tester) async {
      final tontines = FakeTontineRepository()
        ..saved['t-1'] = _tontine(adminUid: 'uid-admin');
      final profils = FakeProfilRepository();
      final container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(
            FakeAuthService(
              const AppUser(uid: 'uid-membre', emailVerified: true),
            ),
          ),
          tontineRepositoryProvider.overrideWithValue(tontines),
          profilRepositoryProvider.overrideWithValue(profils),
        ],
      );
      addTearDown(container.dispose);

      final router = await pumpRouter(tester, container: container);

      // Reproduit `InscriptionPage._inscrire` : navigation explicite vers
      // /espace-membre lancée juste après l'écriture Firestore du profil,
      // avant que celui-ci n'ait eu le temps de se propager au routeur (la
      // session ne le reflète pas encore à cet instant précis).
      router.go(AppRouter.espaceMembrePath);
      await tester.pumpAndSettle();
      expect(currentPath(router), AppRouter.choixPath);

      // Le profil apparaît ensuite (écriture Firestore désormais visible du
      // routeur) : la redirection réactive doit, seule, renvoyer vers
      // /espace-membre.
      await profils.saveProfil(
        const Profil(uid: 'uid-membre', tontineId: 't-1', membreId: 'm-1'),
      );
      await tester.pumpAndSettle();

      expect(currentPath(router), AppRouter.espaceMembrePath);
    },
  );
}

Tontine _tontine({required String adminUid}) => Tontine(
  id: 't-1',
  nom: 'Cercle des amies',
  adminUid: adminUid,
  montantParNom: 25000,
  nombreDeNoms: 10,
  datePremiereEcheance: DateTime(2026, 1, 10),
  periodicite: ReglePeriodicite.tousLesNJours(7),
  reglePenalite: ReglePenalite.aucune,
  delaiGraceJours: 0,
  valeurPenalite: null,
  modeParts: ModeParts.montantFixe,
  codeInvitation: 'IGNORE1',
);

/// Émet l'utilisateur courant dès l'abonnement (comme `FirebaseAuth`), afin
/// que `sessionProvider` sorte immédiatement de l'état `loading`.
class FakeAuthService implements AuthService {
  FakeAuthService(this._currentUser);

  AppUser? _currentUser;
  final _controller = StreamController<AppUser?>.broadcast();

  @override
  AppUser? get currentUser => _currentUser;

  @override
  Stream<AppUser?> get authStateChanges async* {
    yield _currentUser;
    yield* _controller.stream;
  }

  @override
  Future<AppUser> signUp({
    required String email,
    required String password,
  }) async {
    final user = AppUser(uid: 'uid-signup', email: email);
    _currentUser = user;
    _controller.add(user);
    return user;
  }

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    if (_currentUser == null) throw const InvalidCredentialsException();
    return _currentUser!;
  }

  @override
  Future<AppUser?> signInWithGoogle() async {
    final user = AppUser(uid: 'uid-google', email: 'google@example.com', emailVerified: true);
    _currentUser = user;
    _controller.add(user);
    return user;
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    _controller.add(null);
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<void> sendEmailVerification() async {}

  bool prochainRechargeVerifie = false;

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
      _controller.add(_currentUser);
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

  // Un vrai flux (pas `Stream.value`, qui n'émettrait qu'une fois) : sans
  // ça, un profil ajouté après le premier abonnement de `watchProfil`
  // (le cas exact d'une adhésion via code pendant que l'app est déjà sur un
  // écran "sans profil") ne serait jamais répercuté au routeur.
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
