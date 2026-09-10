import '../../domain/entities/preuve.dart';
import 'firestore_codec.dart';

class PreuveModel {
  const PreuveModel({
    required this.id,
    required this.imageEncodee,
    required this.tailleOctets,
    required this.createdAt,
  });

  final String id;
  final String imageEncodee;
  final int tailleOctets;
  final DateTime createdAt;

  factory PreuveModel.fromFirestore(
    Map<String, dynamic> data, {
    required String id,
  }) {
    return PreuveModel(
      id: id,
      imageEncodee: FirestoreCodec.requiredString(data, 'imageEncodee'),
      tailleOctets: FirestoreCodec.requiredInt(data, 'tailleOctets'),
      createdAt: FirestoreCodec.requiredDate(data, 'createdAt'),
    );
  }

  factory PreuveModel.fromEntity(Preuve entity) => PreuveModel(
        id: entity.id,
        imageEncodee: entity.imageEncodee,
        tailleOctets: entity.tailleOctets,
        createdAt: entity.createdAt,
      );

  Preuve toEntity() => Preuve(
        id: id,
        imageEncodee: imageEncodee,
        tailleOctets: tailleOctets,
        createdAt: createdAt,
      );

  Map<String, dynamic> toFirestore() => {
        'imageEncodee': imageEncodee,
        'tailleOctets': tailleOctets,
        'createdAt': FirestoreCodec.timestamp(createdAt),
      };
}
