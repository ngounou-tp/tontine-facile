import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tontinefacile/domain/entities/tontine.dart';
import 'package:tontinefacile/domain/entities/tour.dart';
import 'package:tontinefacile/domain/enums/mode_parts.dart';
import 'package:tontinefacile/domain/enums/regle_penalite.dart';
import 'package:tontinefacile/domain/enums/statut_tour.dart';
import 'package:tontinefacile/domain/value_objects/regle_periodicite.dart';
import 'package:tontinefacile/features/auth/application/auth_providers.dart';
import 'package:tontinefacile/features/echeancier/application/reorganisation_controller.dart';

import '../../support/fakes.dart' show FakeTontineRepository;

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
    );

void main() {
  late FakeTontineRepository tontines;
  late ProviderContainer container;
  late List<Tour> tours;

  setUp(() {
    tontines = FakeTontineRepository();
    tontines.saved['t-1'] = _tontine();
    tours = [
      Tour(id: 'tour-1', nomId: 'n-1', position: 1, datePrevue: DateTime(2026, 1, 3), statut: StatutTour.remis, montantRemis: 25000),
      Tour(id: 'tour-2', nomId: 'n-2', position: 2, datePrevue: DateTime(2026, 1, 10), statut: StatutTour.enCours),
      Tour(id: 'tour-3', nomId: 'n-3', position: 3, datePrevue: DateTime(2026, 1, 17), statut: StatutTour.aVenir),
    ];
    for (final tour in tours) {
      tontines.tours[tour.id] = tour;
    }
    container = ProviderContainer(
      overrides: [tontineRepositoryProvider.overrideWithValue(tontines)],
    );
  });

  tearDown(() => container.dispose());

  test('deplacer réordonne deux tours non remis et recalcule leurs dates', () async {
    final notifier = container.read(reorganisationControllerProvider.notifier);

    await notifier.deplacer(
      tontineId: 't-1',
      tontine: tontines.saved['t-1']!,
      tours: tours,
      anciennePosition: 3,
      nouvellePosition: 2,
      motif: 'Le tour 3 doit passer avant.',
      auteurUid: 'admin-uid',
    );

    final ordonnes = tontines.tours.values.toList()
      ..sort((a, b) => a.position.compareTo(b.position));
    expect(ordonnes.map((t) => t.id), ['tour-1', 'tour-3', 'tour-2']);
    // Le tour remis garde sa position et sa date.
    expect(tontines.tours['tour-1']!.position, 1);
    expect(tontines.tours['tour-1']!.datePrevue, DateTime(2026, 1, 3));
    expect(tontines.changements, isNotEmpty);
  });

  test('deplacer refuse de déplacer un tour déjà remis', () async {
    final notifier = container.read(reorganisationControllerProvider.notifier);

    await expectLater(
      () => notifier.deplacer(
        tontineId: 't-1',
        tontine: tontines.saved['t-1']!,
        tours: tours,
        anciennePosition: 1,
        nouvellePosition: 2,
        motif: 'Test',
        auteurUid: 'admin-uid',
      ),
      throwsStateError,
    );
    expect(tontines.tours['tour-1']!.position, 1);
  });
}
