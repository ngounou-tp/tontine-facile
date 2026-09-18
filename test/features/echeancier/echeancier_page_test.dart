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
import 'package:tontinefacile/features/echeancier/presentation/pages/echeancier_page.dart';
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
      nombreDeNoms: 3,
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

  Future<void> pumpPage(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/echeancier',
      routes: [
        GoRoute(path: '/echeancier', builder: (_, _) => const EcheancierPage()),
        GoRoute(
          path: '/cotisations/:tourId',
          builder: (_, _) => const Text('COTISATIONS_PAGE'),
        ),
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
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() {
    tontines = FakeTontineRepository();
    tontines.saved['t-1'] = _tontine();
  });

  testWidgets("affiche un état vide quand l'échéancier n'est pas généré", (tester) async {
    _tailleTelephone(tester);
    await pumpPage(tester);

    expect(tester.takeException(), isNull);
    expect(
      find.text("L'échéancier n'a pas encore été généré. Attribuez les noms puis générez-le depuis Membres."),
      findsOneWidget,
    );
  });

  testWidgets(
    'affiche les tours dans les onglets À venir / Historique, ordre persisté, '
    'tour en cours mis en évidence',
    (tester) async {
      _tailleTelephone(tester);
      tontines.membres['m-1'] = const Membre(id: 'm-1', nomComplet: 'Rose Domche');
      tontines.membres['m-2'] = const Membre(id: 'm-2', nomComplet: 'Alice Pouth');
      tontines.membres['m-3'] = const Membre(id: 'm-3', nomComplet: 'Fatou Diallo');
      tontines.noms['n-1'] =
          const Nom(id: 'n-1', position: 1, libelle: 'Nom 1', parts: [Part(membreId: 'm-1', fraction: 1)]);
      tontines.noms['n-2'] =
          const Nom(id: 'n-2', position: 2, libelle: 'Nom 2', parts: [Part(membreId: 'm-2', fraction: 1)]);
      tontines.noms['n-3'] =
          const Nom(id: 'n-3', position: 3, libelle: 'Nom 3', parts: [Part(membreId: 'm-3', fraction: 1)]);
      tontines.tours['tour-1'] = Tour(
        id: 'tour-1',
        nomId: 'n-1',
        position: 1,
        datePrevue: DateTime(2026, 1, 3),
        statut: StatutTour.remis,
        montantRemis: 25000,
      );
      tontines.tours['tour-2'] = Tour(
        id: 'tour-2',
        nomId: 'n-2',
        position: 2,
        datePrevue: DateTime(2026, 1, 10),
        statut: StatutTour.enCours,
      );
      tontines.tours['tour-3'] = Tour(
        id: 'tour-3',
        nomId: 'n-3',
        position: 3,
        datePrevue: DateTime(2026, 1, 17),
        statut: StatutTour.aVenir,
      );

      await pumpPage(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('À venir (2)'), findsOneWidget);
      expect(find.text('Historique (1)'), findsOneWidget);
      // Onglet « À venir » actif par défaut : le tour remis n'y figure pas,
      // les deux autres si, dans l'ordre persisté.
      expect(find.text('Rose Domche'), findsNothing);
      expect(find.text('Alice Pouth'), findsOneWidget);
      expect(find.text('Fatou Diallo'), findsOneWidget);

      await tester.tap(find.text('Historique (1)'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Rose Domche'), findsOneWidget);
      expect(find.text('25000 FCFA'), findsOneWidget);
    },
  );
}
