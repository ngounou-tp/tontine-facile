import '../../domain/entities/nom.dart';
import 'firestore_codec.dart';
import 'part_model.dart';

class NomModel {
  const NomModel({
    required this.id,
    required this.position,
    required this.libelle,
    required this.parts,
  });

  final String id;
  final int position;
  final String libelle;
  final List<PartModel> parts;

  factory NomModel.fromFirestore(
    Map<String, dynamic> data, {
    required String id,
  }) {
    return NomModel(
      id: id,
      position: FirestoreCodec.requiredInt(data, 'position'),
      libelle: FirestoreCodec.requiredString(data, 'libelle'),
      parts: FirestoreCodec.mapList(data, 'parts')
          .map(PartModel.fromFirestore)
          .toList(growable: false),
    );
  }

  factory NomModel.fromEntity(Nom entity) {
    return NomModel(
      id: entity.id,
      position: entity.position,
      libelle: entity.libelle,
      parts: entity.parts.map(PartModel.fromEntity).toList(growable: false),
    );
  }

  Nom toEntity() => Nom(
        id: id,
        position: position,
        libelle: libelle,
        parts: parts.map((part) => part.toEntity()).toList(growable: false),
      );

  Map<String, dynamic> toFirestore() => {
        'position': position,
        'libelle': libelle,
        'parts': parts.map((part) => part.toFirestore()).toList(growable: false),
      };
}
