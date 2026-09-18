import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tontinefacile/domain/entities/app_user.dart';
import 'package:tontinefacile/domain/entities/membre.dart';
import 'package:tontinefacile/domain/entities/nom.dart';
import 'package:tontinefacile/domain/entities/part.dart';
import 'package:tontinefacile/domain/entities/session.dart';
import 'package:tontinefacile/domain/entities/tontine.dart';
import 'package:tontinefacile/domain/entities/tour.dart';
import 'package:tontinefacile/domain/enums/mode_parts.dart';
import 'package:tontinefacile/domain/enums/regle_penalite.dart';
import 'package:tontinefacile/domain/enums/statut_tour.dart';
import 'package:tontinefacile/domain/value_objects/regle_periodicite.dart';
import 'package:tontinefacile/features/auth/application/auth_providers.dart';
import 'package:tontinefacile/features/cotisations/presentation/pages/saisir_cotisation_page.dart';
import 'package:tontinefacile/features/tontine/application/tontine_providers.dart';

import '../membres/membres_controller_test.dart' show FakeTontineRepository;

void _tailleTelephone(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 4000);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Tontine _tontine() => Tontine(
      id: 't-1',
      nom: 'Cercle des amies',
      adminUid: 'admin-uid',
      montantParNom: 25000,
      nombreDeNoms: 2,
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
  late Tour tour1;

  Future<GoRouter> pumpPage(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/cotisations/${tour1.id}',
      routes: [
        GoRoute(
          path: '/cotisations/:tourId',
          builder: (_, state) => SaisirCotisationPage(tourId: state.pathParameters['tourId']!),
        ),
        GoRoute(path: '/echeancier', builder: (_, _) => const Text('ECHEANCIER_PAGE')),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tontineRepositoryProvider.overrideWithValue(tontines),
          currentTontineIdProvider.overrideWithValue('t-1'),
          sessionProvider.overrideWith(
            (ref) => Stream.value(const Session(utilisateur: AppUser(uid: 'admin-uid'))),
          ),
          // Ces tests exercent la saisie de cotisation, réservée à
          // l'administratrice : sans wiring complet de `currentTontineProvider`,
          // `isAdminProvider` résoudrait à `false` par défaut et masquerait
          // l'action (voir la version lecture seule pour un membre).
          isAdminProvider.overrideWithValue(true),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  setUp(() {
    tontines = FakeTontineRepository();
    tontines.saved['t-1'] = _tontine();
    tontines.noms['n-1'] = const Nom(id: 'n-1', position: 1, libelle: 'Nom 1', parts: [Part(membreId: 'm-1', fraction: 1)]);
    tontines.noms['n-2'] = const Nom(id: 'n-2', position: 2, libelle: 'Nom 2', parts: [Part(membreId: 'm-2', fraction: 1)]);
    tontines.membres['m-1'] = const Membre(id: 'm-1', nomComplet: 'Rose Domche', uid: 'uid-1');
    tontines.membres['m-2'] = const Membre(id: 'm-2', nomComplet: 'Alice Pouth', uid: 'uid-2');
    tour1 = Tour(id: 't-1-tour-1', nomId: 'n-1', position: 1, datePrevue: DateTime.now(), statut: StatutTour.enCours);
    tontines.tours[tour1.id] = tour1;
    tontines.tours['t-1-tour-2'] = Tour(
      id: 't-1-tour-2',
      nomId: 'n-2',
      position: 2,
      datePrevue: DateTime.now().add(const Duration(days: 7)),
      statut: StatutTour.aVenir,
    );
  });

  testWidgets('affiche les détenteurs à collecter pour le tour en cours sans exception', (tester) async {
    _tailleTelephone(tester);
    await pumpPage(tester);

    expect(tester.takeException(), isNull);
    expect(find.textContaining('Collecte'), findsOneWidget);
    expect(find.text('Rose Domche'), findsOneWidget);
    expect(find.text('Alice Pouth'), findsOneWidget);
    expect(find.text('À collecter (2)', skipOffstage: false), findsOneWidget);
  });

  testWidgets('ouvre le formulaire et enregistre une cotisation intégrale', (tester) async {
    _tailleTelephone(tester);
    await pumpPage(tester);

    await tester.tap(find.text('Rose Domche'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Enregistrer la cotisation'), findsOneWidget);
    expect(find.text('Montant dû : 25000 FCFA'), findsOneWidget);

    await tester.tap(find.text('Enregistrer la cotisation'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(tontines.cotisations, hasLength(1));
    final cotisation = tontines.cotisations.values.single;
    expect(cotisation.membreId, 'm-1');
    expect(cotisation.montantVerse, 25000);
    // Un seul des deux détenteurs a réglé ; le second tour n'a pas démarré.
    expect(tontines.tours[tour1.id]!.statut, StatutTour.enCours);
  });
}
