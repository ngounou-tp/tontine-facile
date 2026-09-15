import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/changement_model.dart';
import '../models/cotisation_model.dart';
import '../models/declaration_model.dart';
import '../models/membre_model.dart';
import '../models/nom_model.dart';
import '../models/preuve_model.dart';
import '../models/tontine_model.dart';
import '../models/tour_model.dart';

abstract interface class TontineDataSource {
  /// Identifiant frais pour une nouvelle tontine (aucun accès réseau).
  String nouvelIdTontine();

  Future<List<TontineModel>> getTontines();
  Future<TontineModel?> getTontine(String tontineId);
  Future<void> saveTontine(TontineModel tontine);
  Future<void> saveMembre(String tontineId, MembreModel membre);

  /// Crée un membre sans `uid` (voir `Membre.uid`), destiné à être réclamé
  /// plus tard par la personne invitée via [claimMembre].
  Future<MembreModel> creerMembrePlaceholder(
    String tontineId, {
    required String nomComplet,
    String? email,
    String? whatsapp,
  });

  /// Attache `uid` au membre placeholder [membreId] pour matérialiser
  /// l'adhésion validée par le code d'invitation [codeInvitation].
  ///
  /// Échoue (`FirebaseException` avec `code == 'permission-denied'`) si le
  /// placeholder a déjà été réclamé — les règles Firestore l'exigent.
  Future<void> claimMembre({
    required String tontineId,
    required String membreId,
    required String uid,
    required String codeInvitation,
  });
  Future<void> saveNom(String tontineId, NomModel nom);
  Future<void> saveTour(String tontineId, TourModel tour);
  Future<void> saveCotisation(String tontineId, CotisationModel cotisation);
  Future<void> saveDeclaration(String tontineId, DeclarationModel declaration);
  Future<void> savePreuve(String tontineId, PreuveModel preuve);
  Future<void> saveChangement(String tontineId, ChangementModel changement);
  Future<List<MembreModel>> getMembres(String tontineId);
  Future<List<NomModel>> getNoms(String tontineId);
  Future<List<TourModel>> getTours(String tontineId);
  Future<List<CotisationModel>> getCotisations(String tontineId);
  Future<List<DeclarationModel>> getDeclarations(String tontineId);
  Future<List<PreuveModel>> getPreuves(String tontineId);
  Future<List<ChangementModel>> getChangements(String tontineId);
}

class FirestoreTontineDataSource implements TontineDataSource {
  FirestoreTontineDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _tontines =>
      _firestore.collection('tontines');

  DocumentReference<Map<String, dynamic>> _tontine(String id) =>
      _tontines.doc(id);

  CollectionReference<Map<String, dynamic>> _subcollection(
    String tontineId,
    String name,
  ) =>
      _tontine(tontineId).collection(name);

  @override
  String nouvelIdTontine() => _tontines.doc().id;

  @override
  Future<List<TontineModel>> getTontines() async {
    final snapshot = await _tontines.orderBy('nom').get();
    return snapshot.docs
        .map((doc) => TontineModel.fromFirestore(doc.data(), id: doc.id))
        .toList(growable: false);
  }

  @override
  Future<TontineModel?> getTontine(String tontineId) async {
    final snapshot = await _tontine(tontineId).get();
    final data = snapshot.data();
    if (!snapshot.exists || data == null) return null;
    return TontineModel.fromFirestore(data, id: snapshot.id);
  }

  @override
  Future<void> saveTontine(TontineModel tontine) =>
      _tontine(tontine.id).set(tontine.toFirestore());

  @override
  Future<void> saveMembre(String tontineId, MembreModel membre) =>
      _subcollection(tontineId, 'membres').doc(membre.id).set(membre.toFirestore());

  @override
  Future<MembreModel> creerMembrePlaceholder(
    String tontineId, {
    required String nomComplet,
    String? email,
    String? whatsapp,
  }) async {
    final doc = _subcollection(tontineId, 'membres').doc();
    final membre = MembreModel(
      id: doc.id,
      nomComplet: nomComplet,
      email: email,
      whatsapp: whatsapp,
      uid: null,
    );
    await doc.set(membre.toFirestore());
    return membre;
  }

  @override
  Future<void> claimMembre({
    required String tontineId,
    required String membreId,
    required String uid,
    required String codeInvitation,
  }) =>
      _subcollection(tontineId, 'membres').doc(membreId).update({
        'uid': uid,
        'codeInvitationUtilise': codeInvitation,
      });

  @override
  Future<void> saveNom(String tontineId, NomModel nom) =>
      _subcollection(tontineId, 'noms').doc(nom.id).set(nom.toFirestore());

  @override
  Future<void> saveTour(String tontineId, TourModel tour) =>
      _subcollection(tontineId, 'tours').doc(tour.id).set(tour.toFirestore());

  @override
  Future<void> saveCotisation(
    String tontineId,
    CotisationModel cotisation,
  ) =>
      _subcollection(tontineId, 'cotisations')
          .doc(cotisation.id)
          .set(cotisation.toFirestore());

  @override
  Future<void> saveDeclaration(
    String tontineId,
    DeclarationModel declaration,
  ) =>
      _subcollection(tontineId, 'declarations')
          .doc(declaration.id)
          .set(declaration.toFirestore());

  @override
  Future<void> savePreuve(String tontineId, PreuveModel preuve) =>
      _subcollection(tontineId, 'preuves').doc(preuve.id).set(preuve.toFirestore());

  @override
  Future<void> saveChangement(
    String tontineId,
    ChangementModel changement,
  ) =>
      _subcollection(tontineId, 'changements')
          .doc(changement.id)
          .set(changement.toFirestore());

  @override
  Future<List<MembreModel>> getMembres(String tontineId) => _getSubcollection(
        tontineId,
        'membres',
        (data, id) => MembreModel.fromFirestore(data, id: id),
      );

  @override
  Future<List<NomModel>> getNoms(String tontineId) => _getSubcollection(
        tontineId,
        'noms',
        (data, id) => NomModel.fromFirestore(data, id: id),
      );

  @override
  Future<List<TourModel>> getTours(String tontineId) => _getSubcollection(
        tontineId,
        'tours',
        (data, id) => TourModel.fromFirestore(data, id: id),
        orderBy: 'position',
      );

  @override
  Future<List<CotisationModel>> getCotisations(String tontineId) =>
      _getSubcollection(
        tontineId,
        'cotisations',
        (data, id) => CotisationModel.fromFirestore(data, id: id),
        orderBy: 'datePaiement',
        descending: true,
      );

  @override
  Future<List<DeclarationModel>> getDeclarations(String tontineId) =>
      _getSubcollection(
        tontineId,
        'declarations',
        (data, id) => DeclarationModel.fromFirestore(data, id: id),
        orderBy: 'createdAt',
      );

  @override
  Future<List<PreuveModel>> getPreuves(String tontineId) => _getSubcollection(
        tontineId,
        'preuves',
        (data, id) => PreuveModel.fromFirestore(data, id: id),
        orderBy: 'createdAt',
      );

  @override
  Future<List<ChangementModel>> getChangements(String tontineId) =>
      _getSubcollection(
        tontineId,
        'changements',
        (data, id) => ChangementModel.fromFirestore(data, id: id),
        orderBy: 'createdAt',
      );

  Future<List<T>> _getSubcollection<T>(
    String tontineId,
    String name,
    T Function(Map<String, dynamic> data, String id) parse, {
    String? orderBy,
    bool descending = false,
  }) async {
    Query<Map<String, dynamic>> query = _subcollection(tontineId, name);
    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }
    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => parse(doc.data(), doc.id))
        .toList(growable: false);
  }
}
