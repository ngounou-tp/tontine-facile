import '../entities/cotisation.dart';
import '../entities/declaration.dart';
import '../entities/nom.dart';
import '../entities/tontine.dart';
import '../entities/tour.dart';
import '../enums/origine_cotisation.dart';
import '../enums/statut_cotisation.dart';
import '../enums/statut_declaration.dart';
import '../rules/validation_cotisation.dart';
import '../rules/validation_declaration.dart';
import 'calculateur_cotisation.dart';

class TraitementDeclaration {
  const TraitementDeclaration({
    this.calculateur = const CalculateurCotisation(),
    this.validationDeclaration = const ValidationDeclaration(),
    this.validationCotisation = const ValidationCotisation(),
  });

  final CalculateurCotisation calculateur;
  final ValidationDeclaration validationDeclaration;
  final ValidationCotisation validationCotisation;

  Declaration validerDeclaration({
    required Declaration declaration,
    DateTime? dateDecision,
  }) {
    if (declaration.statut != StatutDeclaration.enAttente) {
      throw StateError('Seule une déclaration en attente peut être validée.');
    }
    return Declaration(
      id: declaration.id,
      tourId: declaration.tourId,
      nomId: declaration.nomId,
      membreId: declaration.membreId,
      montantDeclare: declaration.montantDeclare,
      datePaiement: declaration.datePaiement,
      preuveId: declaration.preuveId,
      statut: StatutDeclaration.validee,
      motifContestation: null,
      createdAt: declaration.createdAt,
      updatedAt: dateDecision ?? DateTime.now(),
    );
  }

  Cotisation valider({
    required Declaration declaration,
    required Tontine tontine,
    required Nom nom,
    required Tour tour,
    required String adminUid,
  }) {
    if (adminUid.trim().isEmpty) {
      throw ArgumentError('L’administratrice est obligatoire.');
    }
    validationDeclaration.valider(
      declaration: declaration,
      nom: nom,
      tour: tour,
    );
    final montantDu = calculateur.calculerMontantDuPourMembre(
      tontine: tontine,
      nom: nom,
      membreId: declaration.membreId,
    );
    final cotisation = Cotisation(
      id: '${declaration.id}-cotisation',
      tourId: declaration.tourId,
      nomId: declaration.nomId,
      membreId: declaration.membreId,
      montantDu: montantDu,
      montantVerse: declaration.montantDeclare,
      datePaiement: declaration.datePaiement,
      origine: OrigineCotisation.membre,
      statut: StatutCotisation.validee,
      auteurUid: adminUid,
      penalite: calculateur.calculerPenalite(
        tontine: tontine,
        nom: nom,
        datePaiement: declaration.datePaiement,
        dateEcheance: tour.datePrevue,
      ),
      preuveId: declaration.preuveId,
    );
    validationCotisation.valider(cotisation);
    return cotisation;
  }

  Declaration contester({
    required Declaration declaration,
    required String motif,
    DateTime? dateDecision,
  }) {
    if (declaration.statut != StatutDeclaration.enAttente) {
      throw StateError('Seule une déclaration en attente peut être contestée.');
    }
    if (motif.trim().isEmpty) {
      throw ArgumentError('Le motif de contestation est obligatoire.');
    }
    return Declaration(
      id: declaration.id,
      tourId: declaration.tourId,
      nomId: declaration.nomId,
      membreId: declaration.membreId,
      montantDeclare: declaration.montantDeclare,
      datePaiement: declaration.datePaiement,
      preuveId: declaration.preuveId,
      statut: StatutDeclaration.contestee,
      motifContestation: motif.trim(),
      createdAt: declaration.createdAt,
      updatedAt: dateDecision ?? DateTime.now(),
    );
  }
}