import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tontinefacile/data/services/inscription_service.dart';
import 'package:tontinefacile/features/auth/application/auth_providers.dart';
import 'package:tontinefacile/features/tontine/presentation/pages/creer_tontine_page.dart';

import '../../support/fakes.dart';

void main() {
  late FakeAuthService auth;
  late FakeTontineRepository tontines;
  late FakeGroupesRepository groupes;

  Future<GoRouter> pumpPage(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/creer-tontine',
      routes: [
        GoRoute(path: '/creer-tontine', builder: (_, _) => const CreerTontinePage()),
        GoRoute(path: '/membres', builder: (_, _) => const Text('MEMBRES_PAGE')),
        GoRoute(path: '/bienvenue', builder: (_, _) => const Text('BIENVENUE_PAGE')),
      ],
    );
    final container = ProviderContainer(
      overrides: [
        inscriptionServiceProvider.overrideWithValue(
          InscriptionService(authService: auth, groupes: groupes, preferences: FakePreferencesSession()),
        ),
        tontineRepositoryProvider.overrideWithValue(tontines),
      ],
    );
    addTearDown(container.dispose);
    // `CreerTontinePage._attendreTontine` `ref.read`/`listenManual` la
    // session et `currentTontineProvider` : sans un abonnement actif établi
    // dès le départ, ces StreamProvider/FutureProvider ne quittent jamais
    // `AsyncLoading` sous `flutter_test` (voir le même commentaire dans
    // `router_test.dart`).
    container.listen(sessionProvider, (_, _) {});
    container.listen(currentTontineProvider, (_, _) {});
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  setUp(() async {
    auth = FakeAuthService();
    tontines = FakeTontineRepository();
    groupes = FakeGroupesRepository(tontines: tontines, auth: auth);
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
