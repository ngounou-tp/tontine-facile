import 'package:flutter_test/flutter_test.dart';
import 'package:tontinefacile/data/datasources/tontine_firestore_datasource.dart';
import 'package:tontinefacile/data/models/changement_model.dart';
import 'package:tontinefacile/data/models/cotisation_model.dart';
import 'package:tontinefacile/data/models/declaration_model.dart';
import 'package:tontinefacile/data/models/membre_model.dart';
import 'package:tontinefacile/data/models/nom_model.dart';
import 'package:tontinefacile/data/models/preuve_model.dart';
import 'package:tontinefacile/data/models/tontine_model.dart';
import 'package:tontinefacile/data/models/tour_model.dart';
import 'package:tontinefacile/data/repositories/tontine_repository_impl.dart';
import 'package:tontinefacile/domain/entities/tontine.dart';
import 'package:tontinefacile/domain/enums/mode_parts.dart';
import 'package:tontinefacile/domain/enums/regle_penalite.dart';
import 'package:tontinefacile/domain/value_objects/regle_periodicite.dart';

void main() {
  test('le repository convertit les models en entités', () async {
    final source = FakeTontineDataSource([
      TontineModel.fromEntity(_tontine()),
    ]);
    final repository = FirestoreTontineRepository(dataSource: source);

    final tontines = await repository.getTontines();

    expect(tontines, hasLength(1));
    expect(tontines.single.nom, 'Tontine test');
  });

  test('le repository écrit une tontine via le datasource', () async {
    final source = FakeTontineDataSource();
    final repository = FirestoreTontineRepository(dataSource: source);

    await repository.saveTontine(_tontine());

    expect(source.savedTontine?.id, 'tontine-1');
    expect(source.savedTontine?.toFirestore()['montantParNom'], 25000);
  });
}

class FakeTontineDataSource implements TontineDataSource {
  FakeTontineDataSource([this.items = const []]);

  final List<TontineModel> items;
  TontineModel? savedTontine;

  @override
  Future<List<TontineModel>> getTontines() async => items;

  @override
  Future<TontineModel?> getTontine(String tontineId) async =>
      items.where((item) => item.id == tontineId).firstOrNull;

  @override
  Future<void> saveTontine(TontineModel tontine) async => savedTontine = tontine;

  @override
  Future<void> saveMembre(String tontineId, MembreModel membre) async {}

  @override
  Future<void> saveNom(String tontineId, NomModel nom) async {}

  @override
  Future<void> saveTour(String tontineId, TourModel tour) async {}

  @override
  Future<void> saveCotisation(
    String tontineId,
    CotisationModel cotisation,
  ) async {}

  @override
  Future<void> saveDeclaration(
    String tontineId,
    DeclarationModel declaration,
  ) async {}

  @override
  Future<void> savePreuve(String tontineId, PreuveModel preuve) async {}

  @override
  Future<void> saveChangement(
    String tontineId,
    ChangementModel changement,
  ) async {}

  @override
  Future<List<MembreModel>> getMembres(String tontineId) async => const [];

  @override
  Future<List<NomModel>> getNoms(String tontineId) async => const [];

  @override
  Future<List<TourModel>> getTours(String tontineId) async => const [];

  @override
  Future<List<CotisationModel>> getCotisations(String tontineId) async => const [];

  @override
  Future<List<DeclarationModel>> getDeclarations(String tontineId) async => const [];
}

Tontine _tontine() => Tontine(
      id: 'tontine-1',
      nom: 'Tontine test',
      adminUid: 'admin-1',
      montantParNom: 25000,
      datePremiereEcheance: DateTime(2026, 9, 9),
      periodicite: ReglePeriodicite.tousLesNJours(7),
      reglePenalite: ReglePenalite.aucune,
      delaiGraceJours: 0,
      valeurPenalite: null,
      modeParts: ModeParts.montantFixe,
      codeInvitation: 'ABC123',
    );
