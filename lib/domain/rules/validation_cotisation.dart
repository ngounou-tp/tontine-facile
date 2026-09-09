import '../entities/cotisation.dart';
import '../enums/origine_cotisation.dart';
import '../enums/statut_cotisation.dart';

class ValidationCotisation {
  const ValidationCotisation();

  void valider(Cotisation cotisation) {
    if (cotisation.montantDu <= 0) {
      throw ArgumentError('Le montant dû doit être strictement positif.');
    }
    if (cotisation.montantVerse <= 0) {
      throw ArgumentError('Le montant versé doit être strictement positif.');
    }
    if (cotisation.montantVerse > cotisation.montantDu) {
      throw ArgumentError('Le montant versé ne peut pas dépasser le montant dû.');
    }
    if (cotisation.penalite < 0) {
      throw ArgumentError('La pénalité ne peut pas être négative.');
    }
    if (cotisation.statut == StatutCotisation.refusee &&
        (cotisation.motifRefus == null || cotisation.motifRefus!.trim().isEmpty)) {
      throw ArgumentError('Le refus exige un motif non vide.');
    }
    if (cotisation.origine == OrigineCotisation.membre &&
        cotisation.statut != StatutCotisation.declaree &&
        cotisation.auteurUid.trim().isEmpty) {
      throw ArgumentError('L’auteur de la cotisation est obligatoire.');
    }
  }
}