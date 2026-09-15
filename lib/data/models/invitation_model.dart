import '../../domain/entities/invitation.dart';
import 'firestore_codec.dart';

class InvitationModel {
  const InvitationModel({
    required this.code,
    required this.tontineId,
    required this.membreId,
    required this.nomTontine,
    required this.nombreMembres,
  });

  final String code;
  final String tontineId;
  final String membreId;
  final String nomTontine;
  final int nombreMembres;

  factory InvitationModel.fromFirestore(
    Map<String, dynamic> data, {
    required String code,
  }) {
    return InvitationModel(
      code: code,
      tontineId: FirestoreCodec.requiredString(data, 'tontineId'),
      membreId: FirestoreCodec.requiredString(data, 'membreId'),
      nomTontine: FirestoreCodec.requiredString(data, 'nomTontine'),
      nombreMembres: FirestoreCodec.requiredInt(data, 'nombreMembres'),
    );
  }

  factory InvitationModel.fromEntity(Invitation entity) => InvitationModel(
        code: entity.code,
        tontineId: entity.tontineId,
        membreId: entity.membreId,
        nomTontine: entity.nomTontine,
        nombreMembres: entity.nombreMembres,
      );

  Invitation toEntity() => Invitation(
        code: code,
        tontineId: tontineId,
        membreId: membreId,
        nomTontine: nomTontine,
        nombreMembres: nombreMembres,
      );

  Map<String, dynamic> toFirestore() => {
        'tontineId': tontineId,
        'membreId': membreId,
        'nomTontine': nomTontine,
        'nombreMembres': nombreMembres,
      };
}
