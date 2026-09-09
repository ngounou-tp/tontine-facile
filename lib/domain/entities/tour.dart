import '../enums/statut_tour.dart';

class Tour {
  final String id;
  final String nomId;

  final int position;
  final DateTime datePrevue;

  final StatutTour statut;

  final int? montantRemis;

  const Tour({
    required this.id,
    required this.nomId,
    required this.position,
    required this.datePrevue,
    required this.statut,
    this.montantRemis,
  });
}