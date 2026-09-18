import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/errors/app_exception.dart';
import '../models/invitation_model.dart';
import '../models/profil_model.dart';

abstract interface class ProfilDataSource {
  Future<ProfilModel?> getProfil(String uid);
  Future<void> saveProfil(ProfilModel profil);

  /// Mis à jour en direct — le profil n'existe pas encore juste après la
  /// connexion Firebase Auth d'une personne qui vient de créer son compte ou
  /// de rejoindre une tontine avec un code : `getProfil` seul ne le
  /// détecterait jamais tant que rien d'autre ne force une nouvelle lecture.
  Stream<ProfilModel?> watchProfil(String uid);

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

  /// Voir la même note dans `TontineFirestoreDataSource` : sans ce délai, un
  /// appel Firestore ponctuel resté bloqué (réseau dégradé) peut geler
  /// l'application entière — `getProfil` est notamment sur le chemin critique
  /// de résolution de session au démarrage.
  static const _delaiReseau = Duration(seconds: 20);

  Future<T> _avecDelai<T>(Future<T> Function() action) {
    return action().timeout(
      _delaiReseau,
      onTimeout: () => throw const NetworkException(
        'La connexion à Firestore a expiré. Vérifiez votre connexion et réessayez.',
      ),
    );
  }

  @override
  Future<ProfilModel?> getProfil(String uid) => _avecDelai(() async {
        final snapshot = await _utilisateurs.doc(uid).get();
        final data = snapshot.data();
        if (!snapshot.exists || data == null) return null;
        return ProfilModel.fromFirestore(data, uid: snapshot.id);
      });

  @override
  Future<void> saveProfil(ProfilModel profil) =>
      _avecDelai(() => _utilisateurs.doc(profil.uid).set(profil.toFirestore()));

  @override
  Stream<ProfilModel?> watchProfil(String uid) {
    return _utilisateurs.doc(uid).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (!snapshot.exists || data == null) return null;
      return ProfilModel.fromFirestore(data, uid: snapshot.id);
    });
  }

  @override
  Future<InvitationModel?> getInvitation(String code) => _avecDelai(() async {
        final snapshot = await _invitations.doc(code).get();
        final data = snapshot.data();
        if (!snapshot.exists || data == null) return null;
        return InvitationModel.fromFirestore(data, code: snapshot.id);
      });

  @override
  Future<void> saveInvitation(InvitationModel invitation) => _avecDelai(
        () => _invitations.doc(invitation.code).set(invitation.toFirestore()),
      );
}
