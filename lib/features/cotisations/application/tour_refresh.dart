import '../../../data/repositories/tontine_repository.dart';
import '../../../domain/entities/tontine.dart';
import '../../../domain/entities/tour.dart';
import '../../../domain/enums/statut_tour.dart';
import '../../../domain/services/calculateur_etat_tour.dart';

const _calculateurEtat = CalculateurEtatTour();

/// Recalcule le statut d'un tour après l'ajout d'une cotisation
/// ([CalculateurEtatTour]) et, s'il vient de se compléter, démarre le tour
/// suivant (le seul qui reste `aVenir` juste après celui qui se termine —
/// voir `GenerateurEcheancier`). Partagé entre [CotisationController]
/// (saisie directe) et `DeclarationController` (validation d'une
/// déclaration) : les deux chemins produisent une cotisation officielle et
/// doivent tenir l'échéancier à jour de la même façon.
Future<void> rafraichirTours({
  required TontineRepository tontines,
  required String tontineId,
  required Tontine tontine,
  required Tour tour,
}) async {
  final noms = await tontines.getNoms(tontineId);
  final cotisations = await tontines.getCotisations(tontineId);

  final tourMaj = _calculateurEtat.mettreAJour(
    tontine: tontine,
    tour: tour,
    noms: noms,
    cotisations: cotisations,
  );
  if (tourMaj.statut == tour.statut) return;

  await tontines.saveTour(tontineId, tourMaj);
  if (tourMaj.statut != StatutTour.remis) return;

  final tours = await tontines.getTours(tontineId);
  Tour? prochain;
  for (final candidat in tours) {
    if (candidat.position == tourMaj.position + 1) {
      prochain = candidat;
      break;
    }
  }
  if (prochain != null && prochain.statut == StatutTour.aVenir) {
    await tontines.saveTour(
      tontineId,
      Tour(
        id: prochain.id,
        nomId: prochain.nomId,
        position: prochain.position,
        datePrevue: prochain.datePrevue,
        statut: StatutTour.enCours,
        montantRemis: prochain.montantRemis,
      ),
    );
  }
}
