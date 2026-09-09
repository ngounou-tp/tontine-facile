import '../enums/statut_declaration.dart';

class Declaration {
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

  const Declaration({
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
}