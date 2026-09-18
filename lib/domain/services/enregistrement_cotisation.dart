import '../entities/cotisation.dart';
import '../entities/nom.dart';
import '../entities/tontine.dart';
import '../entities/tour.dart';
import '../enums/origine_cotisation.dart';
import '../enums/statut_cotisation.dart';
import '../enums/statut_tour.dart';
import '../rules/validation_cotisation.dart';
import 'calculateur_cotisation.dart';

class EnregistrementCotisation {
  const EnregistrementCotisation({
    this.calculateur = const CalculateurCotisation(),
    this.validation = const ValidationCotisation(),
  });

  final CalculateurCotisation calculateur;
  final ValidationCotisation validation;

  Cotisation enregistrer({
    required String id,
    required Tontine tontine,
    required Tour tour,
    required Nom nom,
    required String membreId,
    required String adminUid,
    required int montantVerse,
    required DateTime datePaiement,
    String? preuveId,
    String? motifException,
    bool exonererPenalite = false,
  }) {
    _verifierEntrees(id, adminUid, membreId, tour);
    final montantDu = calculateur.calculerMontantDuPourMembre(
      tontine: tontine,
      nom: nom,
      membreId: membreId,
    );
    if (motifException != null && motifException.trim().isEmpty) {
      throw ArgumentError('Le motif d’exception ne peut pas être vide.');
    }
    if (exonererPenalite && (motifException == null || motifException.trim().isEmpty)) {
      throw ArgumentError('La levée de la pénalité exige un motif non vide.');
    }
    final penalite = exonererPenalite
        ? 0
        : calculateur.calculerPenalite(
            tontine: tontine,
            nom: nom,
            datePaiement: datePaiement,
            dateEcheance: tour.datePrevue,
          );

    final cotisation = Cotisation(
      id: id,
      tourId: tour.id,
      nomId: nom.id,
      membreId: membreId,
      montantDu: montantDu,
      montantVerse: montantVerse,
      datePaiement: datePaiement,
      origine: OrigineCotisation.administratrice,
      statut: StatutCotisation.validee,
      auteurUid: adminUid,
      penalite: penalite,
      motifException: motifException?.trim(),
      preuveId: preuveId,
    );
    validation.valider(cotisation);
    return cotisation;
  }

  void _verifierEntrees(
    String id,
    String adminUid,
    String membreId,
    Tour tour,
  ) {
    if (id.trim().isEmpty || adminUid.trim().isEmpty || membreId.trim().isEmpty) {
      throw ArgumentError('Les identifiants de cotisation sont obligatoires.');
    }
    if (tour.statut != StatutTour.enCours) {
      throw StateError('Une cotisation ne peut être enregistrée que sur le tour en cours.');
    }
  }
}