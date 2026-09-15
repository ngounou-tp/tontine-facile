import '../../domain/entities/changement.dart';
import '../../domain/entities/cotisation.dart';
import '../../domain/entities/declaration.dart';
import '../../domain/entities/membre.dart';
import '../../domain/entities/nom.dart';
import '../../domain/entities/preuve.dart';
import '../../domain/entities/tontine.dart';
import '../../domain/entities/tour.dart';
import '../datasources/tontine_firestore_datasource.dart';
import '../models/changement_model.dart';
import '../models/cotisation_model.dart';
import '../models/declaration_model.dart';
import '../models/membre_model.dart';
import '../models/nom_model.dart';
import '../models/preuve_model.dart';
import '../models/tontine_model.dart';
import '../models/tour_model.dart';
import 'tontine_repository.dart';

class FirestoreTontineRepository implements TontineRepository {
    FirestoreTontineRepository({required TontineDataSource dataSource})
      : _dataSource = dataSource;

    final TontineDataSource _dataSource;

  @override
  String nouvelIdTontine() => _dataSource.nouvelIdTontine();

  @override
  Future<List<Tontine>> getTontines() async {
    final models = await _dataSource.getTontines();
    return models.map((model) => model.toEntity()).toList(growable: false);
  }

  @override
  Future<Tontine?> getTontine(String tontineId) async {
    final model = await _dataSource.getTontine(tontineId);
    return model?.toEntity();
  }

  @override
  Future<void> saveTontine(Tontine tontine) =>
      _dataSource.saveTontine(TontineModel.fromEntity(tontine));

  @override
  Future<void> saveMembre(String tontineId, Membre membre) =>
      _dataSource.saveMembre(tontineId, MembreModel.fromEntity(membre));

  @override
  Future<Membre> creerMembrePlaceholder(
    String tontineId, {
    required String nomComplet,
    String? email,
    String? whatsapp,
  }) async {
    final membre = await _dataSource.creerMembrePlaceholder(
      tontineId,
      nomComplet: nomComplet,
      email: email,
      whatsapp: whatsapp,
    );
    return membre.toEntity();
  }

  @override
  Future<void> claimMembre({
    required String tontineId,
    required String membreId,
    required String uid,
    required String codeInvitation,
  }) =>
      _dataSource.claimMembre(
        tontineId: tontineId,
        membreId: membreId,
        uid: uid,
        codeInvitation: codeInvitation,
      );

  @override
  Future<void> saveNom(String tontineId, Nom nom) =>
      _dataSource.saveNom(tontineId, NomModel.fromEntity(nom));

  @override
  Future<void> saveTour(String tontineId, Tour tour) =>
      _dataSource.saveTour(tontineId, TourModel.fromEntity(tour));

  @override
  Future<void> saveCotisation(String tontineId, Cotisation cotisation) =>
      _dataSource.saveCotisation(
        tontineId,
        CotisationModel.fromEntity(cotisation),
      );

  @override
  Future<void> saveDeclaration(String tontineId, Declaration declaration) =>
      _dataSource.saveDeclaration(
        tontineId,
        DeclarationModel.fromEntity(declaration),
      );

  @override
  Future<void> savePreuve(String tontineId, Preuve preuve) =>
      _dataSource.savePreuve(tontineId, PreuveModel.fromEntity(preuve));

  @override
  Future<void> saveChangement(String tontineId, Changement changement) =>
      _dataSource.saveChangement(
        tontineId,
        ChangementModel.fromEntity(changement),
      );

  @override
  Future<List<Membre>> getMembres(String tontineId) async =>
      (await _dataSource.getMembres(tontineId))
          .map((model) => model.toEntity())
          .toList(growable: false);

  @override
  Future<List<Nom>> getNoms(String tontineId) async =>
      (await _dataSource.getNoms(tontineId))
          .map((model) => model.toEntity())
          .toList(growable: false);

  @override
  Future<List<Tour>> getTours(String tontineId) async =>
      (await _dataSource.getTours(tontineId))
          .map((model) => model.toEntity())
          .toList(growable: false);

  @override
  Future<List<Cotisation>> getCotisations(String tontineId) async =>
      (await _dataSource.getCotisations(tontineId))
          .map((model) => model.toEntity())
          .toList(growable: false);

  @override
  Future<List<Declaration>> getDeclarations(String tontineId) async =>
      (await _dataSource.getDeclarations(tontineId))
          .map((model) => model.toEntity())
          .toList(growable: false);

  @override
  Future<List<Preuve>> getPreuves(String tontineId) async =>
      (await _dataSource.getPreuves(tontineId))
          .map((model) => model.toEntity())
          .toList(growable: false);

  @override
  Future<List<Changement>> getChangements(String tontineId) async =>
      (await _dataSource.getChangements(tontineId))
          .map((model) => model.toEntity())
          .toList(growable: false);
}
