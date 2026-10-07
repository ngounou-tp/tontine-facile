import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tontinefacile/app/router.dart';
import 'package:tontinefacile/domain/entities/adhesion.dart';
import 'package:tontinefacile/domain/entities/app_user.dart';
import 'package:tontinefacile/domain/enums/role_membre.dart';
import 'package:tontinefacile/domain/enums/type_groupe.dart';
import 'package:tontinefacile/features/auth/application/auth_providers.dart';
import 'package:tontinefacile/features/auth/presentation/pages/nouveau_mot_de_passe_page.dart';
import 'package:tontinefacile/features/groupes/presentation/pages/mes_groupes_page.dart';

import '../../support/fakes.dart';

const _uid = 'uid-1';

void main() {
  late FakeAuthService auth;
  late FakeGroupesRepository groupes;
  late FakePreferencesSession preferences;

  setUp(() {
    auth = FakeAuthService(utilisateur: const AppUser(uid: _uid, email: 'a@b.c', emailVerified: true));
    groupes = FakeGroupesRepository(auth: auth)
      ..ajouterAdhesion(
        _uid,
        const Adhesion(
          groupeId: 'g1',
          membreId: 'm1',
          nomGroupe: 'Tontine des Dames',
          type: TypeGroupe.tontine,
          roles: {RoleMembre.proprietaire, RoleMembre.tresorier},
        ),
      )
      ..ajouterAdhesion(
        _uid,
        const Adhesion(
          groupeId: 'g2',
          membreId: 'm2',
          nomGroupe: 'Njangi du quartier',
          type: TypeGroupe.tontine,
          roles: {RoleMembre.membre},
        ),
      );
    preferences = FakePreferencesSession();
  });

  Future<GoRouter> pump(WidgetTester tester, String initialLocation) async {
    final container = ProviderContainer(
      overrides: [
        authServiceProvider.overrideWithValue(auth),
        groupesRepositoryProvider.overrideWithValue(groupes),
        preferencesSessionProvider.overrideWithValue(preferences),
      ],
    );
    addTearDown(container.dispose);
    container.listen(sessionProvider, (_, _) {});
    final router = GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(path: AppRouter.rootPath, builder: (_, _) => const Text('ACCUEIL')),
        GoRoute(path: AppRouter.groupesPath, builder: (_, _) => const MesGroupesPage()),
        GoRoute(path: AppRouter.creerTontinePath, builder: (_, _) => const Text('CREER')),
        GoRoute(path: AppRouter.rejoindrePath, builder: (_, _) => const Text('REJOINDRE')),
        GoRoute(path: AppRouter.nouveauMotDePassePath, builder: (_, _) => const NouveauMotDePassePage()),
      ],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: MaterialApp.router(routerConfig: router)),
    );
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('liste les groupes avec les rôles, et marque le groupe affiché', (tester) async {
    await pump(tester, AppRouter.groupesPath);

    expect(find.text('Tontine des Dames'), findsOneWidget);
    expect(find.text('Propriétaire · Trésorier(ère)'), findsOneWidget);
    expect(find.text('Njangi du quartier'), findsOneWidget);
    expect(find.text('Membre'), findsOneWidget);
    expect(find.text('Affiché'), findsOneWidget);
  });

  testWidgets('toucher un groupe le rend affiché et ramène à l’accueil', (tester) async {
    await pump(tester, AppRouter.groupesPath);

    await tester.tap(find.text('Njangi du quartier'));
    await tester.pumpAndSettle();

    expect(preferences.groupeCourant(_uid), 'g2');
    expect(find.text('ACCUEIL'), findsOneWidget);
  });

  testWidgets('on peut créer ou rejoindre un autre groupe', (tester) async {
    await pump(tester, AppRouter.groupesPath);

    await tester.tap(find.text('Rejoindre avec un code'));
    await tester.pumpAndSettle();
    expect(find.text('REJOINDRE'), findsOneWidget);
  });

  testWidgets('nouveau mot de passe : confirmation obligatoire, puis enregistrement', (tester) async {
    await pump(tester, AppRouter.nouveauMotDePassePath);

    await tester.enterText(find.byType(TextFormField).at(0), 'nouveau-secret');
    await tester.enterText(find.byType(TextFormField).at(1), 'autre-chose');
    await tester.ensureVisible(find.text('Enregistrer le mot de passe'));
    await tester.tap(find.text('Enregistrer le mot de passe'));
    await tester.pumpAndSettle();
    expect(find.text('Les mots de passe ne correspondent pas.'), findsOneWidget);
    expect(auth.dernierMotDePasse, isNull);

    await tester.enterText(find.byType(TextFormField).at(1), 'nouveau-secret');
    await tester.ensureVisible(find.text('Enregistrer le mot de passe'));
    await tester.tap(find.text('Enregistrer le mot de passe'));
    await tester.pumpAndSettle();
    expect(auth.dernierMotDePasse, 'nouveau-secret');
    expect(find.text('ACCUEIL'), findsOneWidget);
  });
}
