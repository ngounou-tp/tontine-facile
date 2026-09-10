import '../../domain/entities/part.dart';
import 'firestore_codec.dart';

class PartModel {
  const PartModel({
    required this.membreId,
    required this.fraction,
  });

  final String membreId;
  final double fraction;

  factory PartModel.fromFirestore(Map<String, dynamic> data) {
    return PartModel(
      membreId: FirestoreCodec.requiredString(data, 'membreId'),
      fraction: FirestoreCodec.requiredDouble(data, 'fraction'),
    );
  }

  factory PartModel.fromEntity(Part entity) {
    return PartModel(membreId: entity.membreId, fraction: entity.fraction);
  }

  Part toEntity() => Part(membreId: membreId, fraction: fraction);

  Map<String, dynamic> toFirestore() => {
        'membreId': membreId,
        'fraction': fraction,
      };
}
