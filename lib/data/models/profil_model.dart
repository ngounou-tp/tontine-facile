import '../../domain/entities/profil.dart';
import 'firestore_codec.dart';

class ProfilModel {
  const ProfilModel({
    required this.uid,
    required this.tontineId,
    required this.membreId,
  });

  final String uid;
  final String tontineId;
  final String membreId;

  factory ProfilModel.fromFirestore(
    Map<String, dynamic> data, {
    required String uid,
  }) {
    return ProfilModel(
      uid: uid,
      tontineId: FirestoreCodec.requiredString(data, 'tontineId'),
      membreId: FirestoreCodec.requiredString(data, 'membreId'),
    );
  }

  factory ProfilModel.fromEntity(Profil entity) => ProfilModel(
        uid: entity.uid,
        tontineId: entity.tontineId,
        membreId: entity.membreId,
      );

  Profil toEntity() => Profil(
        uid: uid,
        tontineId: tontineId,
        membreId: membreId,
      );

  Map<String, dynamic> toFirestore() => {
        'tontineId': tontineId,
        'membreId': membreId,
      };
}
