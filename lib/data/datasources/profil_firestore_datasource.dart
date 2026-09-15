import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/invitation_model.dart';
import '../models/profil_model.dart';

abstract interface class ProfilDataSource {
  Future<ProfilModel?> getProfil(String uid);
  Future<void> saveProfil(ProfilModel profil);
  Future<InvitationModel?> getInvitation(String code);
  Future<void> saveInvitation(InvitationModel invitation);
}

class FirestoreProfilDataSource implements ProfilDataSource {
  FirestoreProfilDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _utilisateurs =>
      _firestore.collection('utilisateurs');

  CollectionReference<Map<String, dynamic>> get _invitations =>
      _firestore.collection('invitations');

  @override
  Future<ProfilModel?> getProfil(String uid) async {
    final snapshot = await _utilisateurs.doc(uid).get();
    final data = snapshot.data();
    if (!snapshot.exists || data == null) return null;
    return ProfilModel.fromFirestore(data, uid: snapshot.id);
  }

  @override
  Future<void> saveProfil(ProfilModel profil) =>
      _utilisateurs.doc(profil.uid).set(profil.toFirestore());

  @override
  Future<InvitationModel?> getInvitation(String code) async {
    final snapshot = await _invitations.doc(code).get();
    final data = snapshot.data();
    if (!snapshot.exists || data == null) return null;
    return InvitationModel.fromFirestore(data, code: snapshot.id);
  }

  @override
  Future<void> saveInvitation(InvitationModel invitation) =>
      _invitations.doc(invitation.code).set(invitation.toFirestore());
}
