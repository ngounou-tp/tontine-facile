import '../entities/nom.dart';
import '../entities/tontine.dart';
import '../entities/tour.dart';
import '../enums/statut_tour.dart';
import 'calculateur_periodicite.dart';

class GenerateurEcheancier {
	const GenerateurEcheancier({
		this.calculateur = const CalculateurPeriodicite(),
	});

	final CalculateurPeriodicite calculateur;

	List<Tour> generer({
		required Tontine tontine,
		required List<Nom> noms,
	}) {
		if (noms.isEmpty) {
			return const [];
		}

		final nomsOrdonnes = [...noms]
			..sort((premier, second) => premier.position.compareTo(second.position));
		final dates = calculateur.genererEcheancier(
			regle: tontine.periodicite,
			dateDebut: tontine.datePremiereEcheance,
			nombreDeTours: nomsOrdonnes.length,
		);

		return List<Tour>.generate(nomsOrdonnes.length, (index) {
			return Tour(
				id: '${tontine.id}-tour-${index + 1}',
				nomId: nomsOrdonnes[index].id,
				position: index + 1,
				datePrevue: dates[index],
				statut: index == 0 ? StatutTour.enCours : StatutTour.aVenir,
			);
		});
	}
}
