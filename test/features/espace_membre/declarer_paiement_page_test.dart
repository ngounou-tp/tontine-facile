import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tontinefacile/domain/entities/app_user.dart';
import 'package:tontinefacile/domain/entities/membre.dart';
import 'package:tontinefacile/domain/entities/nom.dart';
import 'package:tontinefacile/domain/entities/part.dart';
import 'package:tontinefacile/domain/entities/profil.dart';
import 'package:tontinefacile/domain/entities/session.dart';
import 'package:tontinefacile/domain/entities/tontine.dart';
import 'package:tontinefacile/domain/entities/tour.dart';
import 'package:tontinefacile/domain/enums/mode_parts.dart';
import 'package:tontinefacile/domain/enums/regle_penalite.dart';
import 'package:tontinefacile/domain/enums/statut_tour.dart';
import 'package:tontinefacile/domain/value_objects/regle_periodicite.dart';
import 'package:tontinefacile/features/auth/application/auth_providers.dart';
import 'package:tontinefacile/features/espace_membre/presentation/pages/declarer_paiement_page.dart';
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

  Future<void> pumpPage(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/espace-membre/declarer/n-1',
      routes: [
        GoRoute(
          path: '/espace-membre/declarer/:nomId',
          builder: (_, state) => DeclarerPaiementPage(nomId: state.pathParameters['nomId']!),
        ),
        GoRoute(path: '/espace-membre', builder: (_, _) => const Text('ESPACE_MEMBRE_PAGE')),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tontineRepositoryProvider.overrideWithValue(tontines),
          currentTontineIdProvider.overrideWithValue('t-1'),
          sessionProvider.overrideWith(
            (ref) => Stream.value(const Session(
              utilisateur: AppUser(uid: 'uid-1'),
              profil: Profil(uid: 'uid-1', tontineId: 't-1', membreId: 'm-1'),
            )),
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
    tontines.membres['m-1'] = const Membre(id: 'm-1', nomComplet: 'Rose Domche', uid: 'uid-1');
    tontines.noms['n-1'] =
        const Nom(id: 'n-1', position: 1, libelle: 'Nom 1', parts: [Part(membreId: 'm-1', fraction: 1)]);
    tontines.tours['tour-1'] = Tour(
      id: 'tour-1',
      nomId: 'n-1',
      position: 1,
      datePrevue: DateTime.now(),
      statut: StatutTour.enCours,
    );
  });

  testWidgets('affiche le formulaire pré-rempli au reste à devoir sans exception', (tester) async {
    _tailleTelephone(tester);
    await pumpPage(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('Nom 1'), findsOneWidget);
    expect(find.text('Reste à devoir : 25 000 FCFA'), findsOneWidget);
    expect(find.text('Ajouter une preuve'), findsOneWidget);
  });

  testWidgets('refuse la soumission sans preuve jointe', (tester) async {
    _tailleTelephone(tester);
    await pumpPage(tester);

    await tester.tap(find.text('Envoyer la déclaration'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Une preuve est obligatoire pour déclarer un paiement.'), findsOneWidget);
    expect(tontines.declarations, isEmpty);
  });
}
