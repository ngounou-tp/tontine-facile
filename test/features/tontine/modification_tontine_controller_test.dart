import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tontinefacile/domain/entities/tontine.dart';
import 'package:tontinefacile/domain/enums/mode_parts.dart';
import 'package:tontinefacile/domain/enums/regle_penalite.dart';
import 'package:tontinefacile/domain/value_objects/regle_periodicite.dart';
import 'package:tontinefacile/features/auth/application/auth_providers.dart';
import 'package:tontinefacile/features/tontine/application/modification_tontine_controller.dart';

import '../../support/fakes.dart';

void main() {
  late FakeTontineRepository tontines;
  late ProviderContainer container;

  final tontineInitiale = Tontine(
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
  );

  setUp(() {
    tontines = FakeTontineRepository();
    tontines.saved['t-1'] = tontineInitiale;
    container = ProviderContainer(
      overrides: [tontineRepositoryProvider.overrideWithValue(tontines)],
    );
  });

  tearDown(() => container.dispose());

  test('modifierTontine enregistre les changements valides', () async {
    final notifier = container.read(modificationTontineControllerProvider.notifier);
    final misAJour = Tontine(
      id: tontineInitiale.id,
      nom: 'Nouveau nom',
      adminUid: tontineInitiale.adminUid,
      montantParNom: 30000,
      nombreDeNoms: 12,
      datePremiereEcheance: tontineInitiale.datePremiereEcheance,
      periodicite: tontineInitiale.periodicite,
      reglePenalite: tontineInitiale.reglePenalite,
      delaiGraceJours: tontineInitiale.delaiGraceJours,
      valeurPenalite: tontineInitiale.valeurPenalite,
      modeParts: tontineInitiale.modeParts,
    );

    await notifier.modifierTontine(misAJour);

    expect(tontines.saved['t-1']!.nom, 'Nouveau nom');
    expect(tontines.saved['t-1']!.montantParNom, 30000);
    expect(tontines.saved['t-1']!.nombreDeNoms, 12);
    expect(container.read(modificationTontineControllerProvider).hasValue, isTrue);
  });

  test('modifierTontine rejette une tontine invalide sans écrire', () async {
    final notifier = container.read(modificationTontineControllerProvider.notifier);
    final invalide = Tontine(
      id: tontineInitiale.id,
      nom: 'x',
      adminUid: tontineInitiale.adminUid,
      montantParNom: tontineInitiale.montantParNom,
      nombreDeNoms: tontineInitiale.nombreDeNoms,
      datePremiereEcheance: tontineInitiale.datePremiereEcheance,
      periodicite: tontineInitiale.periodicite,
      reglePenalite: tontineInitiale.reglePenalite,
      delaiGraceJours: tontineInitiale.delaiGraceJours,
      valeurPenalite: tontineInitiale.valeurPenalite,
      modeParts: tontineInitiale.modeParts,
    );

    await expectLater(
      () => notifier.modifierTontine(invalide),
      throwsArgumentError,
    );
    expect(tontines.saved['t-1']!.nom, 'Cercle des amies');
  });
}
