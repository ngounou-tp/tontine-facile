import '../../domain/entities/cotisation.dart';
import '../../domain/enums/origine_cotisation.dart';
import '../../domain/enums/statut_cotisation.dart';
import 'firestore_codec.dart';

class CotisationModel {
  const CotisationModel({
    required this.id,
    required this.tourId,
    required this.nomId,
    required this.membreId,
    required this.montantDu,
    required this.montantVerse,
    required this.datePaiement,
    required this.origine,
    required this.statut,
    required this.auteurUid,
    required this.penalite,
    this.motifException,
    this.motifRefus,
    this.preuveId,
  });

  final String id;
  final String tourId;
  final String nomId;
  final String membreId;
  final int montantDu;
  final int montantVerse;
  final DateTime datePaiement;
  final OrigineCotisation origine;
  final StatutCotisation statut;
  final String auteurUid;
  final int penalite;
  final String? motifException;
  final String? motifRefus;
  final String? preuveId;

  factory CotisationModel.fromFirestore(
    Map<String, dynamic> data, {
    required String id,
  }) {
    return CotisationModel(
      id: id,
      tourId: FirestoreCodec.requiredString(data, 'tourId'),
      nomId: FirestoreCodec.requiredString(data, 'nomId'),
      membreId: FirestoreCodec.requiredString(data, 'membreId'),
      montantDu: FirestoreCodec.requiredInt(data, 'montantDu'),
      montantVerse: FirestoreCodec.requiredInt(data, 'montantVerse'),
      datePaiement: FirestoreCodec.requiredDate(data, 'datePaiement'),
      origine: OrigineCotisation.values.byName(
        FirestoreCodec.requiredString(data, 'origine'),
      ),
      statut: StatutCotisation.values.byName(
        FirestoreCodec.requiredString(data, 'statut'),
      ),
      auteurUid: FirestoreCodec.requiredString(data, 'auteurUid'),
      penalite: FirestoreCodec.requiredInt(data, 'penalite'),
      motifException: FirestoreCodec.optionalString(data, 'motifException'),
      motifRefus: FirestoreCodec.optionalString(data, 'motifRefus'),
      preuveId: FirestoreCodec.optionalString(data, 'preuveId'),
    );
  }

  factory CotisationModel.fromEntity(Cotisation entity) => CotisationModel(
        id: entity.id,
        tourId: entity.tourId,
        nomId: entity.nomId,
        membreId: entity.membreId,
        montantDu: entity.montantDu,
        montantVerse: entity.montantVerse,
        datePaiement: entity.datePaiement,
        origine: entity.origine,
        statut: entity.statut,
        auteurUid: entity.auteurUid,
        penalite: entity.penalite,
        motifException: entity.motifException,
        motifRefus: entity.motifRefus,
        preuveId: entity.preuveId,
      );

  Cotisation toEntity() => Cotisation(
        id: id,
        tourId: tourId,
        nomId: nomId,
        membreId: membreId,
        montantDu: montantDu,
        montantVerse: montantVerse,
        datePaiement: datePaiement,
        origine: origine,
        statut: statut,
        auteurUid: auteurUid,
        penalite: penalite,
        motifException: motifException,
        motifRefus: motifRefus,
        preuveId: preuveId,
      );

  Map<String, dynamic> toFirestore() => {
        'tourId': tourId,
        'nomId': nomId,
        'membreId': membreId,
        'montantDu': montantDu,
        'montantVerse': montantVerse,
        'datePaiement': FirestoreCodec.timestamp(datePaiement),
        'origine': origine.name,
        'statut': statut.name,
        'auteurUid': auteurUid,
        'penalite': penalite,
        'motifException': motifException,
        'motifRefus': motifRefus,
        'preuveId': preuveId,
      };
}
