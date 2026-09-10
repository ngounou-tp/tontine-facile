import '../../domain/entities/declaration.dart';
import '../../domain/enums/statut_declaration.dart';
import 'firestore_codec.dart';

class DeclarationModel {
  const DeclarationModel({
    required this.id,
    required this.tourId,
    required this.nomId,
    required this.membreId,
    required this.montantDeclare,
    required this.datePaiement,
    required this.preuveId,
    required this.statut,
    required this.createdAt,
    this.motifContestation,
    this.updatedAt,
  });

  final String id;
  final String tourId;
  final String nomId;
  final String membreId;
  final int montantDeclare;
  final DateTime datePaiement;
  final String preuveId;
  final StatutDeclaration statut;
  final String? motifContestation;
  final DateTime createdAt;
  final DateTime? updatedAt;

  factory DeclarationModel.fromFirestore(
    Map<String, dynamic> data, {
    required String id,
  }) {
    return DeclarationModel(
      id: id,
      tourId: FirestoreCodec.requiredString(data, 'tourId'),
      nomId: FirestoreCodec.requiredString(data, 'nomId'),
      membreId: FirestoreCodec.requiredString(data, 'membreId'),
      montantDeclare: FirestoreCodec.requiredInt(data, 'montantDeclare'),
      datePaiement: FirestoreCodec.requiredDate(data, 'datePaiement'),
      preuveId: FirestoreCodec.requiredString(data, 'preuveId'),
      statut: StatutDeclaration.values.byName(
        FirestoreCodec.requiredString(data, 'statut'),
      ),
      motifContestation:
          FirestoreCodec.optionalString(data, 'motifContestation'),
      createdAt: FirestoreCodec.requiredDate(data, 'createdAt'),
      updatedAt: FirestoreCodec.optionalDate(data, 'updatedAt'),
    );
  }

  factory DeclarationModel.fromEntity(Declaration entity) => DeclarationModel(
        id: entity.id,
        tourId: entity.tourId,
        nomId: entity.nomId,
        membreId: entity.membreId,
        montantDeclare: entity.montantDeclare,
        datePaiement: entity.datePaiement,
        preuveId: entity.preuveId,
        statut: entity.statut,
        motifContestation: entity.motifContestation,
        createdAt: entity.createdAt,
        updatedAt: entity.updatedAt,
      );

  Declaration toEntity() => Declaration(
        id: id,
        tourId: tourId,
        nomId: nomId,
        membreId: membreId,
        montantDeclare: montantDeclare,
        datePaiement: datePaiement,
        preuveId: preuveId,
        statut: statut,
        motifContestation: motifContestation,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  Map<String, dynamic> toFirestore() => {
        'tourId': tourId,
        'nomId': nomId,
        'membreId': membreId,
        'montantDeclare': montantDeclare,
        'datePaiement': FirestoreCodec.timestamp(datePaiement),
        'preuveId': preuveId,
        'statut': statut.name,
        'motifContestation': motifContestation,
        'createdAt': FirestoreCodec.timestamp(createdAt),
        'updatedAt': updatedAt == null
            ? null
            : FirestoreCodec.timestamp(updatedAt!),
      };
}
