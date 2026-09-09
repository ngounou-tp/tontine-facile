import '../entities/declaration.dart';
import '../entities/nom.dart';
import '../entities/tour.dart';
import '../enums/statut_declaration.dart';
import '../enums/statut_tour.dart';
import 'validation_parts.dart';

class ValidationDeclaration {
  const ValidationDeclaration({
    this.validationParts = const ValidationParts(),
  });

  final ValidationParts validationParts;

  void valider({
    required Declaration declaration,
    required Nom nom,
    required Tour tour,
  }) {
    if (declaration.montantDeclare <= 0) {
      throw ArgumentError('Le montant déclaré doit être strictement positif.');
    }
    if (declaration.preuveId.trim().isEmpty) {
      throw ArgumentError('Une déclaration doit avoir une preuve.');
    }
    if (declaration.tourId != tour.id || declaration.nomId != nom.id) {
      throw ArgumentError('La déclaration ne correspond pas au tour ou au nom.');
    }
    if (declaration.statut != StatutDeclaration.enAttente) {
      throw StateError('Seule une déclaration en attente peut être traitée.');
    }
    if (tour.statut != StatutTour.enCours) {
      throw StateError('Une déclaration ne peut concerner que le tour en cours.');
    }
    validationParts.valider(nom.parts);
    if (!nom.parts.any((part) => part.membreId == declaration.membreId)) {
      throw StateError('Le membre ne détient aucune part du nom déclaré.');
    }
  }
}