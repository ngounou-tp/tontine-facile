import '../../domain/entities/changement.dart';
import '../../domain/entities/cotisation.dart';
import '../../domain/entities/declaration.dart';
import '../../domain/entities/invitation.dart';
import '../../domain/entities/membre.dart';
import '../../domain/entities/nom.dart';
import '../../domain/entities/preuve.dart';
import '../../domain/entities/tontine.dart';
import '../../domain/entities/tour.dart';

/// Repository de l'agrégat Tontine, adressé par l'identifiant du groupe.
///
/// Les droits sont appliqués par le serveur (RLS et fonctions SQL) : un
/// appel non autorisé échoue avec une `AppException` (voir
/// `mapSupabaseError`), quelle que soit l'interface qui l'a déclenché.
abstract interface class TontineRepository {
  // Tontine (nom du groupe et réglages). La création passe par
  // `GroupesRepository.creerTontine`.
  Future<Tontine?> getTontine(String groupeId);
  Stream<Tontine?> watchTontine(String groupeId);
  Future<void> saveTontine(Tontine tontine);

  // Membres
  Future<List<Membre>> getMembres(String groupeId);
  Stream<List<Membre>> watchMembres(String groupeId);

  /// Met à jour coordonnées et activation d'un membre (bureau). Ni le
  /// compte rattaché ni les rôles ne changent par ce biais.
  Future<void> saveMembre(String groupeId, Membre membre);

  /// Ajoute un membre (sans compte) et génère son invitation nominative.
  Future<Invitation> inviterMembre(
    String groupeId, {
    required String nomComplet,
    String? email,
    String? whatsapp,
  });

  // Noms
  String nouvelIdNom(String groupeId);
  Future<List<Nom>> getNoms(String groupeId);
  Stream<List<Nom>> watchNoms(String groupeId);

  /// Crée ou remplace un nom et ses parts, d'un bloc.
  Future<void> saveNom(String groupeId, Nom nom);

  // Tours
  String nouvelIdTour(String groupeId);
  Future<List<Tour>> getTours(String groupeId);

  /// Programme, triée par [Tour.position].
  Stream<List<Tour>> watchTours(String groupeId);
  Future<void> saveTour(String groupeId, Tour tour);

  /// Enregistre plusieurs tours en une requête (génération de l'échéancier).
  Future<void> saveTours(String groupeId, List<Tour> tours);

  /// Applique une réorganisation (positions et dates) et historise un
  /// changement par tour déplacé, d'un bloc.
  Future<void> reorganiserTours(
    String groupeId, {
    required List<Tour> tours,
    required List<Changement> changements,
    required String motif,
  });

  // Cotisations
  String nouvelIdCotisation(String groupeId);
  Future<List<Cotisation>> getCotisations(String groupeId);
  Stream<List<Cotisation>> watchCotisations(String groupeId);

  /// Enregistre une cotisation officielle (bureau). Une cotisation ne se
  /// modifie ni ne se supprime ensuite.
  Future<void> saveCotisation(String groupeId, Cotisation cotisation);

  // Déclarations
  String nouvelIdDeclaration(String groupeId);
  Future<List<Declaration>> getDeclarations(String groupeId);
  Stream<List<Declaration>> watchDeclarations(String groupeId);

  /// Dépôt par un membre, pour un nom qu'il détient, sur le tour en cours.
  Future<void> deposerDeclaration(String groupeId, Declaration declaration);

  /// Validation par le bureau : crée la cotisation officielle et passe la
  /// déclaration en « validée », d'un bloc. Renvoie l'id de la cotisation.
  Future<String> validerDeclaration(
    String groupeId, {
    required String declarationId,
    required int montantDu,
    required int penalite,
  });

  /// Refus motivé par le bureau.
  Future<void> contesterDeclaration(
    String groupeId, {
    required String declarationId,
    required String motif,
  });

  // Preuves
  String nouvelIdPreuve(String groupeId);
  Future<void> savePreuve(String groupeId, Preuve preuve);
  Future<Preuve?> getPreuve(String groupeId, String preuveId);

  // Historique des réorganisations
  Future<List<Changement>> getChangements(String groupeId);
  Stream<List<Changement>> watchChangements(String groupeId);
}
