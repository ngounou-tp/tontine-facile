import '../../domain/entities/tour.dart';
import '../../domain/enums/statut_tour.dart';
import 'firestore_codec.dart';

class TourModel {
  const TourModel({
    required this.id,
    required this.nomId,
    required this.position,
    required this.datePrevue,
    required this.statut,
    this.montantRemis,
  });

  final String id;
  final String nomId;
  final int position;
  final DateTime datePrevue;
  final StatutTour statut;
  final int? montantRemis;

  factory TourModel.fromFirestore(
    Map<String, dynamic> data, {
    required String id,
  }) {
    final statut = FirestoreCodec.requiredString(data, 'statut');
    return TourModel(
      id: id,
      nomId: FirestoreCodec.requiredString(data, 'nomId'),
      position: FirestoreCodec.requiredInt(data, 'position'),
      datePrevue: FirestoreCodec.requiredDate(data, 'datePrevue'),
      statut: StatutTour.values.byName(statut),
      montantRemis: FirestoreCodec.optionalInt(data, 'montantRemis'),
    );
  }

  factory TourModel.fromEntity(Tour entity) => TourModel(
        id: entity.id,
        nomId: entity.nomId,
        position: entity.position,
        datePrevue: entity.datePrevue,
        statut: entity.statut,
        montantRemis: entity.montantRemis,
      );

  Tour toEntity() => Tour(
        id: id,
        nomId: nomId,
        position: position,
        datePrevue: datePrevue,
        statut: statut,
        montantRemis: montantRemis,
      );

  Map<String, dynamic> toFirestore() => {
        'nomId': nomId,
        'position': position,
        'datePrevue': FirestoreCodec.timestamp(datePrevue),
        'statut': statut.name,
        'montantRemis': montantRemis,
      };
}
