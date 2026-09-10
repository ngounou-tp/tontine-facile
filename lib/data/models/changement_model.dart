import '../../domain/entities/changement.dart';
import 'firestore_codec.dart';

class ChangementModel {
  const ChangementModel({
    required this.id,
    required this.tourId,
    required this.anciennePosition,
    required this.nouvellePosition,
    required this.motif,
    required this.auteurUid,
    required this.createdAt,
  });

  final String id;
  final String tourId;
  final int anciennePosition;
  final int nouvellePosition;
  final String motif;
  final String auteurUid;
  final DateTime createdAt;

  factory ChangementModel.fromFirestore(
    Map<String, dynamic> data, {
    required String id,
  }) {
    return ChangementModel(
      id: id,
      tourId: FirestoreCodec.requiredString(data, 'tourId'),
      anciennePosition: FirestoreCodec.requiredInt(data, 'anciennePosition'),
      nouvellePosition: FirestoreCodec.requiredInt(data, 'nouvellePosition'),
      motif: FirestoreCodec.requiredString(data, 'motif'),
      auteurUid: FirestoreCodec.requiredString(data, 'auteurUid'),
      createdAt: FirestoreCodec.requiredDate(data, 'createdAt'),
    );
  }

  factory ChangementModel.fromEntity(Changement entity) => ChangementModel(
        id: entity.id,
        tourId: entity.tourId,
        anciennePosition: entity.anciennePosition,
        nouvellePosition: entity.nouvellePosition,
        motif: entity.motif,
        auteurUid: entity.auteurUid,
        createdAt: entity.createdAt,
      );

  Changement toEntity() => Changement(
        id: id,
        tourId: tourId,
        anciennePosition: anciennePosition,
        nouvellePosition: nouvellePosition,
        motif: motif,
        auteurUid: auteurUid,
        createdAt: createdAt,
      );

  Map<String, dynamic> toFirestore() => {
        'tourId': tourId,
        'anciennePosition': anciennePosition,
        'nouvellePosition': nouvellePosition,
        'motif': motif,
        'auteurUid': auteurUid,
        'createdAt': FirestoreCodec.timestamp(createdAt),
      };
}
