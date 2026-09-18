import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tontinefacile/domain/entities/app_user.dart';
import 'package:tontinefacile/domain/entities/cotisation.dart';
import 'package:tontinefacile/domain/entities/membre.dart';
import 'package:tontinefacile/domain/entities/nom.dart';
import 'package:tontinefacile/domain/entities/part.dart';
import 'package:tontinefacile/domain/entities/session.dart';
import 'package:tontinefacile/domain/entities/tontine.dart';
import 'package:tontinefacile/domain/entities/tour.dart';
import 'package:tontinefacile/domain/enums/mode_parts.dart';
import 'package:tontinefacile/domain/enums/origine_cotisation.dart';
import 'package:tontinefacile/domain/enums/regle_penalite.dart';
import 'package:tontinefacile/domain/enums/statut_cotisation.dart';
import 'package:tontinefacile/domain/enums/statut_tour.dart';
import 'package:tontinefacile/domain/value_objects/regle_periodicite.dart';
import 'package:tontinefacile/features/auth/application/auth_providers.dart';
import 'package:tontinefacile/features/tontine/application/tontine_providers.dart';
import 'package:tontinefacile/features/tontine/presentation/pages/home_page.dart';

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

  Future<void> pumpPage(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/accueil',
      routes: [
        GoRoute(path: '/accueil', builder: (_, _) => const HomePage()),
        GoRoute(path: '/reglages', builder: (_, _) => const Text('REGLAGES_PAGE')),
        GoRoute(path: '/membres', builder: (_, _) => const Text('MEMBRES_PAGE')),
        GoRoute(path: '/membres/ajouter', builder: (_, _) => const Text('AJOUTER_PAGE')),
        GoRoute(
          path: '/cotisations/:tourId',
          builder: (_, _) => const Text('COTISATIONS_PAGE'),
        ),
        GoRoute(path: '/declarations', builder: (_, _) => const Text('DECLARATIONS_PAGE')),
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

  testWidgets('affiche un état vide sans échéancier sans donnée codée en dur', (tester) async {
    _tailleTelephone(tester);
    tontines.membres['m-1'] = const Membre(id: 'm-1', nomComplet: 'Rose Domche', uid: 'admin-uid');

    await pumpPage(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('Cercle des amies'), findsOneWidget);
    expect(find.textContaining('Bonjour'), findsOneWidget);
    // Aucune des anciennes données figées ne doit apparaître.
    expect(find.text('Cercle des Amies'), findsNothing);
    expect(find.text("L'échéancier n'a pas encore été généré. Attribuez les noms puis générez-le depuis Membres."), findsOneWidget);
  });

  testWidgets(
    'affiche le tour en cours, la progression de collecte et les stats à '
    'partir des données réelles',
    (tester) async {
      _tailleTelephone(tester);
      tontines.membres['m-1'] =
          const Membre(id: 'm-1', nomComplet: 'Rose Domche', uid: 'admin-uid');
      tontines.membres['m-2'] = const Membre(id: 'm-2', nomComplet: 'Alice Pouth', uid: 'uid-2');
      tontines.noms['n-1'] =
          const Nom(id: 'n-1', position: 1, libelle: 'Nom 1', parts: [Part(membreId: 'm-1', fraction: 1)]);
      tontines.noms['n-2'] =
          const Nom(id: 'n-2', position: 2, libelle: 'Nom 2', parts: [Part(membreId: 'm-2', fraction: 1)]);
      tontines.tours['t-1-tour-1'] = Tour(
        id: 't-1-tour-1',
        nomId: 'n-1',
        position: 1,
        datePrevue: DateTime(2026, 1, 10),
        statut: StatutTour.enCours,
      );
      tontines.tours['t-1-tour-2'] = Tour(
        id: 't-1-tour-2',
        nomId: 'n-2',
        position: 2,
        datePrevue: DateTime(2026, 1, 17),
        statut: StatutTour.aVenir,
      );
      tontines.cotisations['c-1'] = Cotisation(
        id: 'c-1',
        tourId: 't-1-tour-1',
        nomId: 'n-1',
        membreId: 'm-1',
        montantDu: 25000,
        montantVerse: 25000,
        datePaiement: DateTime(2026, 1, 10),
        origine: OrigineCotisation.administratrice,
        statut: StatutCotisation.validee,
        auteurUid: 'admin-uid',
        penalite: 0,
      );

      await pumpPage(tester);

      expect(tester.takeException(), isNull);
      // Bénéficiaire du tour en cours (nom 1, détenu par Rose Domche).
      expect(find.text('Rose Domche'), findsOneWidget);
      // Collecte du tour : 25000/50000 = 50 %.
      expect(find.text('25000 / 50000 FCFA'), findsOneWidget);
      expect(find.text('50 %', skipOffstage: false), findsWidgets);
      // Stats : 2 membres actifs, 2/2 noms attribués, 1 paiement à temps, 0 en retard.
      expect(find.text('2', skipOffstage: false), findsWidgets);
      expect(find.text('2/2', skipOffstage: false), findsOneWidget);
      expect(find.text('1 / 0', skipOffstage: false), findsOneWidget);
    },
  );
}
