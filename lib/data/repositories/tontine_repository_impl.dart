import '../../domain/entities/cotisation.dart';
import '../../domain/entities/declaration.dart';
import '../../domain/entities/membre.dart';
import '../../domain/entities/nom.dart';
import '../../domain/entities/tontine.dart';
import '../../domain/entities/tour.dart';
import '../datasources/tontine_firestore_datasource.dart';
import '../models/cotisation_model.dart';
import '../models/declaration_model.dart';
import '../models/membre_model.dart';
import '../models/nom_model.dart';
import '../models/tontine_model.dart';
import '../models/tour_model.dart';
import 'tontine_repository.dart';

class FirestoreTontineRepository implements TontineRepository {
    FirestoreTontineRepository({required this._dataSource});

    final TontineDataSource _dataSource;

  @override
  Future<List<Tontine>> getTontines() async {
    final models = await _dataSource.getTontines();
    return models.map((model) => model.toEntity()).toList(growable: false);
  }

  Future<Tontine?> getTontine(String tontineId) async {
    final model = await _dataSource.getTontine(tontineId);
    return model?.toEntity();
  }

  Future<void> saveTontine(Tontine tontine) =>
      _dataSource.saveTontine(TontineModel.fromEntity(tontine));

  Future<void> saveMembre(String tontineId, Membre membre) =>
      _dataSource.saveMembre(tontineId, MembreModel.fromEntity(membre));

  Future<void> saveNom(String tontineId, Nom nom) =>
      _dataSource.saveNom(tontineId, NomModel.fromEntity(nom));

  Future<void> saveTour(String tontineId, Tour tour) =>
      _dataSource.saveTour(tontineId, TourModel.fromEntity(tour));

  Future<void> saveCotisation(String tontineId, Cotisation cotisation) =>
      _dataSource.saveCotisation(
        tontineId,
        CotisationModel.fromEntity(cotisation),
      );

  Future<void> saveDeclaration(String tontineId, Declaration declaration) =>
      _dataSource.saveDeclaration(
        tontineId,
        DeclarationModel.fromEntity(declaration),
      );

  Future<List<Membre>> getMembres(String tontineId) async =>
      (await _dataSource.getMembres(tontineId))
          .map((model) => model.toEntity())
          .toList(growable: false);

  Future<List<Nom>> getNoms(String tontineId) async =>
      (await _dataSource.getNoms(tontineId))
          .map((model) => model.toEntity())
          .toList(growable: false);

  Future<List<Tour>> getTours(String tontineId) async =>
      (await _dataSource.getTours(tontineId))
          .map((model) => model.toEntity())
          .toList(growable: false);

  Future<List<Cotisation>> getCotisations(String tontineId) async =>
      (await _dataSource.getCotisations(tontineId))
          .map((model) => model.toEntity())
          .toList(growable: false);

  Future<List<Declaration>> getDeclarations(String tontineId) async =>
      (await _dataSource.getDeclarations(tontineId))
          .map((model) => model.toEntity())
          .toList(growable: false);
}
