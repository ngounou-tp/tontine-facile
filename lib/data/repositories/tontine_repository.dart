import '../../domain/entities/changement.dart';
import '../../domain/entities/cotisation.dart';
import '../../domain/entities/declaration.dart';
import '../../domain/entities/membre.dart';
import '../../domain/entities/nom.dart';
import '../../domain/entities/preuve.dart';
import '../../domain/entities/tontine.dart';
import '../../domain/entities/tour.dart';

/// Repository de l'agrégat Tontine.
///
/// `Membre`, `Nom`, `Tour`, `Cotisation`, `Declaration`, `Preuve` et
/// `Changement` sont des entités enfants qui n'existent que sous une
/// tontine (sous-collections Firestore) : elles sont exposées ici plutôt
/// que via des repositories séparés, car aucune n'a de cycle de vie
/// indépendant de son `tontineId`.
abstract interface class TontineRepository {
  // Tontines
  String nouvelIdTontine();
  Future<List<Tontine>> getTontines();
  Future<Tontine?> getTontine(String tontineId);
  Future<void> saveTontine(Tontine tontine);

  // Membres
  Future<List<Membre>> getMembres(String tontineId);
  Future<void> saveMembre(String tontineId, Membre membre);

  /// Crée un membre sans `uid`, à réclamer plus tard via [claimMembre] et
  /// une invitation nominative.
  Future<Membre> creerMembrePlaceholder(
    String tontineId, {
    required String nomComplet,
    String? email,
    String? whatsapp,
  });

  /// Matérialise l'adhésion d'un membre : attache `uid` au placeholder créé
  /// par l'administratrice, après vérification du code d'invitation.
  Future<void> claimMembre({
    required String tontineId,
    required String membreId,
    required String uid,
    required String codeInvitation,
  });

  // Noms
  Future<List<Nom>> getNoms(String tontineId);
  Future<void> saveNom(String tontineId, Nom nom);

  // Tours
  Future<List<Tour>> getTours(String tontineId);
  Future<void> saveTour(String tontineId, Tour tour);

  // Cotisations
  Future<List<Cotisation>> getCotisations(String tontineId);
  Future<void> saveCotisation(String tontineId, Cotisation cotisation);

  // Declarations
  Future<List<Declaration>> getDeclarations(String tontineId);
  Future<void> saveDeclaration(String tontineId, Declaration declaration);

  // Preuves
  Future<List<Preuve>> getPreuves(String tontineId);
  Future<void> savePreuve(String tontineId, Preuve preuve);

  // Changements
  Future<List<Changement>> getChangements(String tontineId);
  Future<void> saveChangement(String tontineId, Changement changement);
}
