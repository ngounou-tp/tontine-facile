import '../../domain/entities/adhesion.dart';
import '../../domain/entities/tontine.dart';

/// Aperçu public d'une invitation, lisible avant même de créer un compte.
typedef ApercuInvitation = ({String nomGroupe, int nombreMembres, bool dejaUtilisee});

/// Groupes du compte connecté : appartenances, création et adhésion.
abstract interface class GroupesRepository {
  /// Groupes auxquels [uid] appartient, mis à jour en direct (nouvelle
  /// adhésion, rôle modifié, désactivation...).
  Stream<List<Adhesion>> watchAdhesions(String uid);

  /// Crée une tontine dont le compte courant devient propriétaire et
  /// trésorier. Renvoie l'identifiant du groupe.
  Future<String> creerTontine({required Tontine tontine, required String nomCompletAdmin});

  /// `null` si le code est inconnu.
  Future<ApercuInvitation?> apercuInvitation(String code);

  /// Rattache le compte courant à la fiche membre désignée par [code].
  Future<({String groupeId, String membreId})> rejoindre(String code);

  /// Supprime définitivement le compte courant. Ses fiches restent dans
  /// les groupes, anonymisées ; un groupe sans plus aucun autre compte est
  /// supprimé. Refusé tant que le compte est le seul propriétaire d'un
  /// groupe où d'autres ont un compte.
  Future<void> supprimerMonCompte();
}
