import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tontinefacile/domain/entities/nom.dart';
import 'package:tontinefacile/domain/entities/part.dart';
import 'package:tontinefacile/domain/entities/tontine.dart';
import 'package:tontinefacile/domain/enums/mode_parts.dart';
import 'package:tontinefacile/domain/enums/regle_penalite.dart';
import 'package:tontinefacile/domain/enums/statut_tour.dart';
import 'package:tontinefacile/domain/value_objects/regle_periodicite.dart';
import 'package:tontinefacile/features/auth/application/auth_providers.dart';
import 'package:tontinefacile/features/echeancier/application/echeancier_controller.dart';

import '../../support/fakes.dart';

void main() {
  late FakeTontineRepository tontines;
  late ProviderContainer container;

  setUp(() {
    tontines = FakeTontineRepository();
    container = ProviderContainer(
      overrides: [tontineRepositoryProvider.overrideWithValue(tontines)],
    );
  });

  tearDown(() => container.dispose());

  final tontine = Tontine(
    id: 't-1',
    nom: 'Cercle des amies',
    adminUid: 'admin',
    montantParNom: 25000,
    nombreDeNoms: 10,
    datePremiereEcheance: DateTime(2026, 1, 5),
    periodicite: ReglePeriodicite.chaqueMoisJourFixe(5),
    reglePenalite: ReglePenalite.aucune,
    delaiGraceJours: 0,
    valeurPenalite: null,
    modeParts: ModeParts.montantFixe,
  );

  final noms = [
    const Nom(id: 'n-2', position: 2, libelle: 'Nom 2', parts: [Part(membreId: 'm-2', fraction: 1)]),
    const Nom(id: 'n-1', position: 1, libelle: 'Nom 1', parts: [Part(membreId: 'm-1', fraction: 1)]),
  ];

  test('génère un tour par nom, trié par position, et le persiste', () async {
    final notifier = container.read(echeancierControllerProvider.notifier);

    await notifier.genererEcheancier(tontine: tontine, noms: noms);

    expect(tontines.tours, hasLength(2));
    final tries = tontines.tours.values.toList()..sort((a, b) => a.position.compareTo(b.position));
    expect(tries[0].nomId, 'n-1');
    expect(tries[0].position, 1);
    expect(tries[0].statut, StatutTour.enCours);
    expect(tries[1].nomId, 'n-2');
    expect(tries[1].position, 2);
    expect(tries[1].statut, StatutTour.aVenir);
    expect(container.read(echeancierControllerProvider).hasValue, isTrue);
  });

  test('ne persiste rien si aucun nom n\'est fourni', () async {
    final notifier = container.read(echeancierControllerProvider.notifier);

    await notifier.genererEcheancier(tontine: tontine, noms: const []);

    expect(tontines.tours, isEmpty);
  });
}
