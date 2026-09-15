import '../../domain/entities/invitation.dart';
import '../../domain/entities/profil.dart';

/// Repository du profil applicatif (`utilisateurs/{uid}`) et des invitations
/// nominatives (`invitations/{code}`) — les deux petites collections racine
/// qui relient un compte Firebase Auth à une tontine.
abstract interface class ProfilRepository {
  Future<Profil?> getProfil(String uid);
  Future<void> saveProfil(Profil profil);

  Future<Invitation?> getInvitation(String code);
  Future<void> saveInvitation(Invitation invitation);
}
