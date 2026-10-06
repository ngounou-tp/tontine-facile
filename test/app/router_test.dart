import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tontinefacile/app/router.dart';
import 'package:tontinefacile/domain/entities/adhesion.dart';
import 'package:tontinefacile/domain/entities/app_user.dart';
import 'package:tontinefacile/domain/entities/tontine.dart';
import 'package:tontinefacile/domain/enums/mode_parts.dart';
import 'package:tontinefacile/domain/enums/regle_penalite.dart';
import 'package:tontinefacile/domain/enums/role_membre.dart';
import 'package:tontinefacile/domain/enums/type_groupe.dart';
import 'package:tontinefacile/domain/value_objects/regle_periodicite.dart';
import 'package:tontinefacile/features/auth/application/auth_providers.dart';
import 'package:tontinefacile/features/onboarding/application/onboarding_provider.dart';

import '../support/fakes.dart';

const _uid = 'uid-1';
const _utilisateur = AppUser(uid: _uid, email: 'un@example.com', emailVerified: true);

Adhesion _adhesion(String groupeId, Set<RoleMembre> roles) => Adhesion(
      groupeId: groupeId,
      membreId: 'm-$groupeId',
      nomGroupe: 'Groupe $groupeId',
      type: TypeGroupe.tontine,
      roles: roles,
    );

Tontine _tontine(String id) => Tontine(
      id: id,
      nom: 'Tontine $id',
      adminUid: 'uid-admin',
      montantParNom: 25000,
      nombreDeNoms: 10,
      datePremiereEcheance: DateTime(2026, 1, 10),
      periodicite: ReglePeriodicite.tousLesNJours(7),
      reglePenalite: ReglePenalite.aucune,
      delaiGraceJours: 0,
      valeurPenalite: null,
      modeParts: ModeParts.montantFixe,
    );

void main() {
  late FakeTontineRepository tontines;
  late FakeGroupesRepository groupes;
  late FakePreferencesSession preferences;

  setUp(() {
    tontines = FakeTontineRepository()
      ..saved['g1'] = _tontine('g1')
      ..saved['g2'] = _tontine('g2');
    groupes = FakeGroupesRepository(tontines: tontines);
    preferences = FakePreferencesSession();
  });

  ProviderContainer conteneur({AppUser? utilisateur, SharedPreferences? sharedPreferences}) {
    final container = ProviderContainer(
      overrides: [
        authServiceProvider.overrideWithValue(FakeAuthService(utilisateur: utilisateur)),
        groupesRepositoryProvider.overrideWithValue(groupes),
        tontineRepositoryProvider.overrideWithValue(tontines),
        preferencesSessionProvider.overrideWithValue(preferences),
        if (sharedPreferences != null) sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  Future<GoRouter> pumpRouter(WidgetTester tester, ProviderContainer container) async {
    // `AppRouter.redirect` ne fait que `ref.read` ces providers : sans
    // abonnement actif au niveau du conteneur, ils ne quittent jamais
    // `AsyncLoading` sous `flutter_test`.
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

  String chemin(GoRouter router) => router.routerDelegate.currentConfiguration.uri.path;

  Future<void> aller(WidgetTester tester, GoRouter router, String location) async {
    router.go(location);
    await tester.pumpAndSettle();
  }

  testWidgets('un visiteur non connecté est renvoyé de /accueil vers /connexion', (tester) async {
    final router = await pumpRouter(tester, conteneur());

    await aller(tester, router, AppRouter.accueilPath);

    expect(chemin(router), AppRouter.connexionPath);
  });

  testWidgets(
    "au premier lancement, un visiteur découvre l'app (/decouvrir) ; ensuite il atterrit sur /connexion",
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final shared = await SharedPreferences.getInstance();
      final container = conteneur(sharedPreferences: shared);
      final router = await pumpRouter(tester, container);

      await aller(tester, router, AppRouter.connexionPath);
      expect(chemin(router), AppRouter.onboardingPath);

      await container.read(onboardingVuProvider.notifier).terminer();
      await aller(tester, router, AppRouter.onboardingPath);
      expect(chemin(router), AppRouter.connexionPath);
      expect(shared.getBool('onboarding_vu_v1'), isTrue);
    },
  );

  testWidgets("l'écran « confirmez votre email » s'ouvre sans être connecté", (tester) async {
    final router = await pumpRouter(tester, conteneur());

    await aller(tester, router, AppRouter.verifyEmailPath);

    expect(chemin(router), AppRouter.verifyEmailPath);
  });

  testWidgets('le choix du nouveau mot de passe passe avant tout, même sans groupe', (tester) async {
    final router = await pumpRouter(tester, conteneur(utilisateur: _utilisateur));

    await aller(tester, router, AppRouter.nouveauMotDePassePath);

    expect(chemin(router), AppRouter.nouveauMotDePassePath);
  });

  testWidgets('un compte sans groupe est orienté vers /bienvenue', (tester) async {
    final router = await pumpRouter(tester, conteneur(utilisateur: _utilisateur));

    await aller(tester, router, AppRouter.accueilPath);

    expect(chemin(router), AppRouter.choixPath);
  });

  testWidgets(
    'un membre consulte les sections en lecture seule mais ne peut pas ajouter de membre',
    (tester) async {
      groupes.ajouterAdhesion(_uid, _adhesion('g1', {RoleMembre.membre}));
      final router = await pumpRouter(tester, conteneur(utilisateur: _utilisateur));

      for (final lecture in [
        AppRouter.accueilPath,
        AppRouter.membresPath,
        AppRouter.echeancierPath,
        AppRouter.reglagesPath,
        AppRouter.declarationsPath,
        '${AppRouter.cotisationsPath}/tour-1',
      ]) {
        await aller(tester, router, lecture);
        expect(chemin(router), lecture);
      }

      await aller(tester, router, '${AppRouter.membresPath}/ajouter');
      expect(chemin(router), AppRouter.espaceMembrePath);
    },
  );

  testWidgets('un membre du bureau ouvre /membres/ajouter', (tester) async {
    groupes.ajouterAdhesion(_uid, _adhesion('g1', {RoleMembre.tresorier}));
    final router = await pumpRouter(tester, conteneur(utilisateur: _utilisateur));

    await aller(tester, router, '${AppRouter.membresPath}/ajouter');

    expect(chemin(router), '${AppRouter.membresPath}/ajouter');
  });

  testWidgets('avec des groupes, on peut toujours en créer, en rejoindre et en changer', (tester) async {
    groupes.ajouterAdhesion(_uid, _adhesion('g1', {RoleMembre.membre}));
    final router = await pumpRouter(tester, conteneur(utilisateur: _utilisateur));

    for (final location in [AppRouter.groupesPath, AppRouter.creerTontinePath, AppRouter.rejoindrePath]) {
      await aller(tester, router, location);
      expect(chemin(router), location);
    }
    await aller(tester, router, AppRouter.choixPath);
    expect(chemin(router), AppRouter.espaceMembrePath);
  });

  testWidgets('les droits suivent le groupe affiché', (tester) async {
    groupes
      ..ajouterAdhesion(_uid, _adhesion('g1', {RoleMembre.proprietaire}))
      ..ajouterAdhesion(_uid, _adhesion('g2', {RoleMembre.membre}));
    final router = await pumpRouter(tester, conteneur(utilisateur: _utilisateur));

    await aller(tester, router, '${AppRouter.membresPath}/ajouter');
    expect(chemin(router), '${AppRouter.membresPath}/ajouter', reason: 'propriétaire de g1');

    await preferences.choisirGroupe(_uid, 'g2');
    await tester.pumpAndSettle();
    await aller(tester, router, '${AppRouter.membresPath}/ajouter');
    expect(chemin(router), AppRouter.espaceMembrePath, reason: 'simple membre de g2');
  });

  testWidgets(
    "une adhésion qui arrive après la navigation redirige d'elle-même vers l'espace membre",
    (tester) async {
      final router = await pumpRouter(tester, conteneur(utilisateur: _utilisateur));

      await aller(tester, router, AppRouter.espaceMembrePath);
      expect(chemin(router), AppRouter.choixPath);

      groupes.ajouterAdhesion(_uid, _adhesion('g1', {RoleMembre.membre}));
      await tester.pumpAndSettle();

      expect(chemin(router), AppRouter.espaceMembrePath);
    },
  );
}
