import '../enums/origine_cotisation.dart';
import '../enums/statut_cotisation.dart';

class Cotisation {
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

  const Cotisation({
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
}