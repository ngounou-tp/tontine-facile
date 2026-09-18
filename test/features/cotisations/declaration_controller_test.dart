import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tontinefacile/domain/entities/declaration.dart';
import 'package:tontinefacile/domain/entities/nom.dart';
import 'package:tontinefacile/domain/entities/part.dart';
import 'package:tontinefacile/domain/entities/tontine.dart';
import 'package:tontinefacile/domain/entities/tour.dart';
import 'package:tontinefacile/domain/enums/mode_parts.dart';
import 'package:tontinefacile/domain/enums/regle_penalite.dart';
import 'package:tontinefacile/domain/enums/statut_cotisation.dart';
import 'package:tontinefacile/domain/enums/statut_declaration.dart';
import 'package:tontinefacile/domain/enums/statut_tour.dart';
import 'package:tontinefacile/domain/value_objects/regle_periodicite.dart';
import 'package:tontinefacile/features/auth/application/auth_providers.dart';
import 'package:tontinefacile/features/cotisations/application/declaration_controller.dart';

import '../membres/membres_controller_test.dart' show FakeTontineRepository;

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
  late ProviderContainer container;
  late Nom nom1;
  late Nom nom2;
  late Tour tour1;

  setUp(() {
    tontines = FakeTontineRepository();
    tontines.saved['t-1'] = _tontine();
    nom1 = const Nom(id: 'n-1', position: 1, libelle: 'Nom 1', parts: [Part(membreId: 'm-1', fraction: 1)]);
    nom2 = const Nom(id: 'n-2', position: 2, libelle: 'Nom 2', parts: [Part(membreId: 'm-2', fraction: 1)]);
    tontines.noms[nom1.id] = nom1;
    tontines.noms[nom2.id] = nom2;
    tour1 = Tour(id: 't-1-tour-1', nomId: nom1.id, position: 1, datePrevue: DateTime(2026, 1, 10), statut: StatutTour.enCours);
    tontines.tours[tour1.id] = tour1;
    tontines.tours['t-1-tour-2'] = Tour(
      id: 't-1-tour-2',
      nomId: nom2.id,
      position: 2,
      datePrevue: DateTime(2026, 1, 17),
      statut: StatutTour.aVenir,
    );
    container = ProviderContainer(
      overrides: [tontineRepositoryProvider.overrideWithValue(tontines)],
    );
  });

  tearDown(() => container.dispose());

  test('declarerPaiement enregistre une preuve puis une déclaration en attente', () async {
    final notifier = container.read(declarationControllerProvider.notifier);

    await notifier.declarerPaiement(
      tontineId: 't-1',
      tour: tour1,
      nom: nom1,
      membreId: 'm-1',
      montantDeclare: 25000,
      datePaiement: DateTime(2026, 1, 10),
      preuveBytes: Uint8List.fromList([1, 2, 3]),
    );

    expect(tontines.preuves, hasLength(1));
    expect(tontines.declarations, hasLength(1));
    final declaration = tontines.declarations.values.single;
    expect(declaration.statut, StatutDeclaration.enAttente);
    expect(declaration.preuveId, tontines.preuves.keys.single);
    // Aucune cotisation officielle n'est créée avant validation.
    expect(tontines.cotisations, isEmpty);
  });

  test(
    'declarerPaiement refuse une déclaration pour un nom que le membre ne '
    'détient pas',
    () async {
      final notifier = container.read(declarationControllerProvider.notifier);

      await expectLater(
        () => notifier.declarerPaiement(
          tontineId: 't-1',
          tour: tour1,
          nom: nom1,
          membreId: 'm-2', // ne détient pas nom1
          montantDeclare: 25000,
          datePaiement: DateTime(2026, 1, 10),
          preuveBytes: Uint8List.fromList([1, 2, 3]),
        ),
        throwsStateError,
      );
      expect(tontines.declarations, isEmpty);
    },
  );

  test(
    'validerDeclaration crée la cotisation officielle et marque la '
    'déclaration validée',
    () async {
      final declaration = Declaration(
        id: 'd-1',
        tourId: tour1.id,
        nomId: nom1.id,
        membreId: 'm-1',
        montantDeclare: 25000,
        datePaiement: DateTime(2026, 1, 10),
        preuveId: 'preuve-1',
        statut: StatutDeclaration.enAttente,
        createdAt: DateTime(2026, 1, 10),
      );
      tontines.declarations['d-1'] = declaration;
      final notifier = container.read(declarationControllerProvider.notifier);

      await notifier.validerDeclaration(
        tontineId: 't-1',
        declaration: declaration,
        tontine: tontines.saved['t-1']!,
        nom: nom1,
        tour: tour1,
        adminUid: 'admin-uid',
      );

      expect(tontines.cotisations, hasLength(1));
      final cotisation = tontines.cotisations.values.single;
      expect(cotisation.statut, StatutCotisation.validee);
      expect(cotisation.montantVerse, 25000);
      expect(tontines.declarations['d-1']!.statut, StatutDeclaration.validee);
    },
  );

  test('refuserDeclaration exige un motif et ne crée aucune cotisation', () async {
    final declaration = Declaration(
      id: 'd-1',
      tourId: tour1.id,
      nomId: nom1.id,
      membreId: 'm-1',
      montantDeclare: 25000,
      datePaiement: DateTime(2026, 1, 10),
      preuveId: 'preuve-1',
      statut: StatutDeclaration.enAttente,
      createdAt: DateTime(2026, 1, 10),
    );
    tontines.declarations['d-1'] = declaration;
    final notifier = container.read(declarationControllerProvider.notifier);

    await expectLater(
      () => notifier.refuserDeclaration(tontineId: 't-1', declaration: declaration, motif: ''),
      throwsArgumentError,
    );
    expect(tontines.declarations['d-1']!.statut, StatutDeclaration.enAttente);

    await notifier.refuserDeclaration(
      tontineId: 't-1',
      declaration: declaration,
      motif: 'Preuve illisible',
    );
    expect(tontines.declarations['d-1']!.statut, StatutDeclaration.contestee);
    expect(tontines.declarations['d-1']!.motifContestation, 'Preuve illisible');
    expect(tontines.cotisations, isEmpty);
  });
}
