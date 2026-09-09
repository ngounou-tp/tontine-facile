import '../entities/cotisation.dart';
import '../entities/nom.dart';
import '../entities/tontine.dart';
import '../entities/tour.dart';
import '../enums/statut_cotisation.dart';
import '../enums/statut_tour.dart';
import 'calculateur_cotisation.dart';

class CalculateurEtatTour {
  const CalculateurEtatTour({
    this.calculateur = const CalculateurCotisation(),
  });

  final CalculateurCotisation calculateur;

  Tour mettreAJour({
    required Tontine tontine,
    required Tour tour,
    required List<Nom> noms,
    required List<Cotisation> cotisations,
  }) {
    if (tour.statut != StatutTour.enCours) return tour;
    final cotisationsDuTour = cotisations.where(
      (cotisation) =>
          cotisation.tourId == tour.id &&
          cotisation.statut == StatutCotisation.validee,
    );

    var complet = true;
    final totalRemis = noms.fold<int>(0, (total, nom) {
      final montantDu = calculateur.calculerMontantDu(
        tontine: tontine,
        nom: nom,
      );
      final montantVerse = cotisationsDuTour
          .where((cotisation) => cotisation.nomId == nom.id)
          .fold<int>(0, (somme, cotisation) => somme + cotisation.montantVerse);
      if (montantVerse < montantDu) {
        complet = false;
        return total;
      }
      return total + montantDu;
    });

    if (!complet || noms.isEmpty) return tour;
    return Tour(
      id: tour.id,
      nomId: tour.nomId,
      position: tour.position,
      datePrevue: tour.datePrevue,
      statut: StatutTour.remis,
      montantRemis: totalRemis,
    );
  }
}