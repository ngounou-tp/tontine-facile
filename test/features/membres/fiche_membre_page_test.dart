import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tontinefacile/domain/entities/membre.dart';
import 'package:tontinefacile/domain/entities/nom.dart';
import 'package:tontinefacile/domain/entities/part.dart';
import 'package:tontinefacile/domain/entities/tontine.dart';
import 'package:tontinefacile/domain/enums/mode_parts.dart';
import 'package:tontinefacile/domain/enums/regle_penalite.dart';
import 'package:tontinefacile/domain/value_objects/regle_periodicite.dart';
import 'package:tontinefacile/features/auth/application/auth_providers.dart';
import 'package:tontinefacile/features/membres/presentation/pages/fiche_membre_page.dart';
import 'package:tontinefacile/features/membres/presentation/pages/membres_page.dart';
import 'package:tontinefacile/features/tontine/application/tontine_providers.dart';

import 'membres_controller_test.dart' show FakeTontineRepository;

/// Reproduit la taille d'un écran de téléphone standard (Pixel 5) : les
/// débordements de mise en page ("RenderFlex overflowed") n'apparaissent
/// souvent qu'à cette taille, pas à la taille par défaut des tests widgets
/// (800x600), beaucoup plus large.
void _tailleTelephone(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Tontine _tontine() => Tontine(
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

void main() {
  late FakeTontineRepository tontines;

  overrides() => [
        tontineRepositoryProvider.overrideWithValue(tontines),
        currentTontineIdProvider.overrideWithValue('t-1'),
        // Ces tests exercent les actions réservées à l'administratrice
        // (attribuer des noms, modifier les coordonnées) : sans wiring
        // complet de la session/tontine courante, `isAdminProvider`
        // résoudrait à `false` par défaut et les masquerait.
        isAdminProvider.overrideWithValue(true),
      ];

  setUp(() {
    tontines = FakeTontineRepository();
    tontines.saved['t-1'] = _tontine();
  });

  testWidgets(
    'FicheMembrePage affiche un membre inscrit avec code, contact et noms '
    'sans exception ni débordement',
    (tester) async {
      _tailleTelephone(tester);
      tontines.membres['m-1'] = const Membre(
        id: 'm-1',
        nomComplet: 'Rose Domche Ateba',
        email: 'rose.domche.ateba@example.com',
        whatsapp: '+237 6 00 00 00 00',
        uid: 'uid-1',
        codeInvitation: 'ABCDEF',
      );
      tontines.noms['n-1'] = const Nom(
        id: 'n-1',
        position: 1,
        libelle: 'Nom 1',
        parts: [Part(membreId: 'm-1', fraction: 1)],
      );

      final router = GoRouter(
        initialLocation: '/membres/m-1',
        routes: [
          GoRoute(
            path: '/membres/:membreId',
            builder: (_, state) =>
                FicheMembrePage(membreId: state.pathParameters['membreId']!),
          ),
          GoRoute(path: '/membres', builder: (_, _) => const Text('MEMBRES_PAGE')),
          GoRoute(
            path: '/membres/noms/:nomId',
            builder: (_, _) => const Text('NOM_PAGE'),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: overrides(),
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Rose Domche Ateba'), findsWidgets);
      expect(find.text('ABCDEF'), findsOneWidget);
      expect(find.text('Nom 1'), findsOneWidget);

      // Ouvrir la feuille d'attribution de noms supplémentaires (la section
      // « Noms détenus » suit la carte du montant dû : on y fait défiler).
      await tester.ensureVisible(find.text('Attribuer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Attribuer'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Attribuer des noms'), findsOneWidget);

      await tester.tap(find.text('Attribuer').last);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Tapoter sur le nom détenu navigue vers sa page dédiée.
      await tester.ensureVisible(find.text('Nom 1'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nom 1'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('NOM_PAGE'), findsOneWidget);
    },
  );

  testWidgets(
    'FicheMembrePage affiche un membre en attente sans code ni contact '
    'sans exception',
    (tester) async {
      _tailleTelephone(tester);
      tontines.membres['m-2'] = const Membre(id: 'm-2', nomComplet: 'Alice Pouth');

      final router = GoRouter(
        initialLocation: '/membres/m-2',
        routes: [
          GoRoute(
            path: '/membres/:membreId',
            builder: (_, state) =>
                FicheMembrePage(membreId: state.pathParameters['membreId']!),
          ),
          GoRoute(path: '/membres', builder: (_, _) => const Text('MEMBRES_PAGE')),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: overrides(),
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Alice Pouth'), findsWidgets);
      expect(find.text("En attente d'inscription"), findsOneWidget);
      expect(find.text('Aucun nom attribué pour le moment.'), findsOneWidget);

      // Passer en mode modification puis revenir.
      await tester.tap(find.text('Modifier les coordonnées'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(TextFormField), findsWidgets);
    },
  );

  testWidgets(
    'MembresPage affiche membres et noms sans exception ni débordement',
    (tester) async {
      _tailleTelephone(tester);
      tontines.membres['m-1'] = const Membre(
        id: 'm-1',
        nomComplet: 'Rose Domche Ateba',
        whatsapp: '+237600000000',
        uid: 'uid-1',
        codeInvitation: 'ABCDEF',
      );
      tontines.membres['m-2'] = const Membre(
        id: 'm-2',
        nomComplet: 'Alice Pouth',
        actif: false,
      );
      tontines.noms['n-1'] = const Nom(
        id: 'n-1',
        position: 1,
        libelle: 'Nom 1',
        parts: [Part(membreId: 'm-1', fraction: 1)],
      );

      final router = GoRouter(
        initialLocation: '/membres',
        routes: [
          GoRoute(path: '/membres', builder: (_, _) => const MembresPage()),
          GoRoute(
            path: '/membres/ajouter',
            builder: (_, _) => const Text('AJOUTER_MEMBRE_PAGE'),
          ),
          GoRoute(
            path: '/membres/noms/nouveau',
            builder: (_, _) => const Text('ATTRIBUER_NOM_PAGE'),
          ),
          GoRoute(
            path: '/membres/noms/:nomId',
            builder: (_, _) => const Text('NOM_PAGE'),
          ),
          GoRoute(
            path: '/membres/:membreId',
            builder: (_, state) =>
                FicheMembrePage(membreId: state.pathParameters['membreId']!),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: overrides(),
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      // Onglet « Noms » actif par défaut.
      expect(find.text('Nom 1'), findsOneWidget);

      await tester.tap(find.text('Membres (2)'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Rose Domche Ateba'), findsOneWidget);
      expect(find.text('Alice Pouth', skipOffstage: false), findsOneWidget);
      expect(find.text('Membres désactivés (1)', skipOffstage: false), findsOneWidget);

      await tester.tap(find.text('Rose Domche Ateba'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('ABCDEF'), findsOneWidget);
    },
  );
}
