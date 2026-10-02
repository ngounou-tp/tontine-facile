import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tontinefacile/domain/entities/tontine.dart';
import 'package:tontinefacile/domain/entities/tour.dart';
import 'package:tontinefacile/domain/enums/mode_parts.dart';
import 'package:tontinefacile/domain/enums/regle_penalite.dart';
import 'package:tontinefacile/domain/enums/statut_tour.dart';
import 'package:tontinefacile/domain/value_objects/regle_periodicite.dart';
import 'package:tontinefacile/features/auth/application/auth_providers.dart';
import 'package:tontinefacile/features/tontine/application/tontine_providers.dart';
import 'package:tontinefacile/features/tontine/presentation/pages/modifier_tontine_page.dart';

import '../membres/membres_controller_test.dart' show FakeTontineRepository;

void _tailleTelephone(WidgetTester tester) {
  // Assez haut pour que le formulaire entier tienne sans avoir à faire
  // défiler dans le test (évite les faux « hors écran » causés par le
  // clavier virtuel après enterText) tout en gardant la largeur étroite
  // d'un téléphone, seule dimension pertinente pour les débordements
  // horizontaux qu'on veut détecter ici.
  tester.view.physicalSize = const Size(1080, 4000);
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

Future<GoRouter> _pumpPage(WidgetTester tester, FakeTontineRepository tontines) async {
  final router = GoRouter(
    initialLocation: '/reglages/tontine',
    routes: [
      GoRoute(path: '/reglages/tontine', builder: (_, _) => const ModifierTontinePage()),
      GoRoute(path: '/reglages', builder: (_, _) => const Text('REGLAGES_PAGE')),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tontineRepositoryProvider.overrideWithValue(tontines),
        currentTontineIdProvider.overrideWithValue('t-1'),
        // Ce test exerce le formulaire d'édition, réservé à
        // l'administratrice : sans wiring complet de la session/tontine
        // courante, `isAdminProvider` résoudrait à `false` par défaut et
        // figerait la page indépendamment de l'échéancier.
        isAdminProvider.overrideWithValue(true),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

void main() {
  late FakeTontineRepository tontines;

  setUp(() {
    tontines = FakeTontineRepository();
    tontines.saved['t-1'] = _tontine();
  });

  testWidgets(
    'tontine sans échéancier : fréquence et répartition des parts sont '
    'modifiables',
    (tester) async {
      _tailleTelephone(tester);
      await _pumpPage(tester, tontines);

      expect(tester.takeException(), isNull);
      expect(find.text('Figés — échéancier déjà généré'), findsNothing);
      expect(find.text('Nombre de jours entre deux échéances'), findsOneWidget);
      expect(find.text('Parts égales'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).first, 'Cercle rénové');
      await tester.ensureVisible(find.text('Parts égales'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Parts égales'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.ensureVisible(find.text('Enregistrer les modifications'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Enregistrer les modifications'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(tontines.saved['t-1']!.nom, 'Cercle rénové');
      expect(tontines.saved['t-1']!.modeParts, ModeParts.partEgale);
    },
  );

  testWidgets(
    'tontine avec échéancier déjà généré : toute la tontine est figée, '
    'aucun champ ni bouton d\'enregistrement',
    (tester) async {
      _tailleTelephone(tester);
      tontines.tours['tour-1'] = Tour(
        id: 'tour-1',
        nomId: 'n-1',
        position: 1,
        datePrevue: DateTime(2026, 1, 10),
        statut: StatutTour.aVenir,
      );

      await _pumpPage(tester, tontines);

      expect(tester.takeException(), isNull);
      expect(find.text('Figée — l\'échéancier a démarré'), findsOneWidget);
      // Résumé en lecture seule de tous les champs, pas seulement
      // fréquence/répartition.
      expect(find.text('Cercle des amies'), findsOneWidget);
      expect(find.text('25 000 FCFA'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
      // Aucun moyen de modifier quoi que ce soit.
      expect(find.byType(TextFormField), findsNothing);
      expect(find.text('Enregistrer les modifications'), findsNothing);

      // La tontine sauvegardée reste inchangée.
      expect(tontines.saved['t-1']!.nom, 'Cercle des amies');
      expect(tontines.saved['t-1']!.periodicite, isA<RegleTousLesNJours>());
      expect(tontines.saved['t-1']!.modeParts, ModeParts.montantFixe);
    },
  );
}
