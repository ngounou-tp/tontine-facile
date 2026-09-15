import '../../domain/entities/invitation.dart';
import '../../domain/entities/profil.dart';
import '../datasources/profil_firestore_datasource.dart';
import '../models/invitation_model.dart';
import '../models/profil_model.dart';
import 'profil_repository.dart';

class FirestoreProfilRepository implements ProfilRepository {
  FirestoreProfilRepository({required ProfilDataSource dataSource})
      : _dataSource = dataSource;

  final ProfilDataSource _dataSource;

  @override
  Future<Profil?> getProfil(String uid) async =>
      (await _dataSource.getProfil(uid))?.toEntity();

  @override
  Future<void> saveProfil(Profil profil) =>
      _dataSource.saveProfil(ProfilModel.fromEntity(profil));

  @override
  Future<Invitation?> getInvitation(String code) async =>
      (await _dataSource.getInvitation(code))?.toEntity();

  @override
  Future<void> saveInvitation(Invitation invitation) =>
      _dataSource.saveInvitation(InvitationModel.fromEntity(invitation));
}
