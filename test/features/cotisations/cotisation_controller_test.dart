import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tontinefacile/domain/entities/nom.dart';
import 'package:tontinefacile/domain/entities/part.dart';
import 'package:tontinefacile/domain/entities/tontine.dart';
import 'package:tontinefacile/domain/entities/tour.dart';
import 'package:tontinefacile/domain/enums/mode_parts.dart';
import 'package:tontinefacile/domain/enums/regle_penalite.dart';
import 'package:tontinefacile/domain/enums/statut_cotisation.dart';
import 'package:tontinefacile/domain/enums/statut_tour.dart';
import 'package:tontinefacile/domain/value_objects/regle_periodicite.dart';
import 'package:tontinefacile/features/auth/application/auth_providers.dart';
import 'package:tontinefacile/features/cotisations/application/cotisation_controller.dart';

import '../../support/fakes.dart' show FakeTontineRepository;

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
    );

void main() {
  late FakeTontineRepository tontines;
  late ProviderContainer container;
  late Nom nom1;
  late Nom nom2;
  late Tour tour1;
  late Tour tour2;

  setUp(() {
    tontines = FakeTontineRepository();
    tontines.saved['t-1'] = _tontine();

    nom1 = const Nom(id: 'n-1', position: 1, libelle: 'Nom 1', parts: [Part(membreId: 'm-1', fraction: 1)]);
    nom2 = const Nom(id: 'n-2', position: 2, libelle: 'Nom 2', parts: [Part(membreId: 'm-2', fraction: 1)]);
    tontines.noms[nom1.id] = nom1;
    tontines.noms[nom2.id] = nom2;

    tour1 = Tour(id: 't-1-tour-1', nomId: nom1.id, position: 1, datePrevue: DateTime(2026, 1, 10), statut: StatutTour.enCours);
    tour2 = Tour(id: 't-1-tour-2', nomId: nom2.id, position: 2, datePrevue: DateTime(2026, 1, 17), statut: StatutTour.aVenir);
    tontines.tours[tour1.id] = tour1;
    tontines.tours[tour2.id] = tour2;

    container = ProviderContainer(
      overrides: [tontineRepositoryProvider.overrideWithValue(tontines)],
    );
  });

  tearDown(() => container.dispose());

  test('saisirCotisation enregistre une cotisation validée sans compléter le tour', () async {
    final notifier = container.read(cotisationControllerProvider.notifier);

    await notifier.saisirCotisation(
      tontineId: 't-1',
      tontine: tontines.saved['t-1']!,
      tour: tour1,
      nom: nom1,
      membreId: 'm-1',
      adminUid: 'admin-uid',
      montantVerse: 25000,
      datePaiement: DateTime(2026, 1, 10),
    );

    expect(tontines.cotisations, hasLength(1));
    final cotisation = tontines.cotisations.values.single;
    expect(cotisation.montantVerse, 25000);
    expect(cotisation.statut, StatutCotisation.validee);
    // Un seul des deux noms a réglé : le tour reste en cours.
    expect(tontines.tours[tour1.id]!.statut, StatutTour.enCours);
  });

  test(
    'saisirCotisation marque le tour remis et démarre le suivant une fois '
    'tous les noms réglés',
    () async {
      final notifier = container.read(cotisationControllerProvider.notifier);

      await notifier.saisirCotisation(
        tontineId: 't-1',
        tontine: tontines.saved['t-1']!,
        tour: tour1,
        nom: nom1,
        membreId: 'm-1',
        adminUid: 'admin-uid',
        montantVerse: 25000,
        datePaiement: DateTime(2026, 1, 10),
      );
      await notifier.saisirCotisation(
        tontineId: 't-1',
        tontine: tontines.saved['t-1']!,
        tour: tour1,
        nom: nom2,
        membreId: 'm-2',
        adminUid: 'admin-uid',
        montantVerse: 25000,
        datePaiement: DateTime(2026, 1, 10),
      );

      expect(tontines.tours[tour1.id]!.statut, StatutTour.remis);
      expect(tontines.tours[tour1.id]!.montantRemis, 50000);
      expect(tontines.tours[tour2.id]!.statut, StatutTour.enCours);
    },
  );

  test('saisirCotisation avec exonererPenalite exige un motif non vide', () async {
    final notifier = container.read(cotisationControllerProvider.notifier);

    await expectLater(
      () => notifier.saisirCotisation(
        tontineId: 't-1',
        tontine: tontines.saved['t-1']!,
        tour: tour1,
        nom: nom1,
        membreId: 'm-1',
        adminUid: 'admin-uid',
        montantVerse: 25000,
        datePaiement: DateTime(2026, 1, 10),
        exonererPenalite: true,
      ),
      throwsArgumentError,
    );
    expect(tontines.cotisations, isEmpty);
  });

  test('saisirCotisation avec exonererPenalite et motif enregistre une pénalité nulle', () async {
    final notifier = container.read(cotisationControllerProvider.notifier);

    await notifier.saisirCotisation(
      tontineId: 't-1',
      tontine: tontines.saved['t-1']!,
      tour: tour1,
      nom: nom1,
      membreId: 'm-1',
      adminUid: 'admin-uid',
      montantVerse: 25000,
      datePaiement: DateTime(2026, 1, 10),
      exonererPenalite: true,
      motifException: 'Panne réseau signalée à l’avance',
    );

    expect(tontines.cotisations.values.single.penalite, 0);
  });
}
