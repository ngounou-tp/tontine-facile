import '../entities/changement.dart';
import '../entities/tontine.dart';
import '../entities/tour.dart';
import '../enums/statut_tour.dart';
import '../value_objects/regle_periodicite.dart';
import 'calculateur_periodicite.dart';

class ReorganisationResult {
	const ReorganisationResult({
		required this.tours,
		required this.changements,
	});

	final List<Tour> tours;
	final List<Changement> changements;
}

class ReorganisateurTours {
	const ReorganisateurTours({
		this.calculateur = const CalculateurPeriodicite(),
	});

	final CalculateurPeriodicite calculateur;

	ReorganisationResult reorganiser({
		required Tontine tontine,
		required List<Tour> tours,
		required int anciennePosition,
		required int nouvellePosition,
		required String motif,
		required String auteurUid,
		DateTime? dateChangement,
	}) {
		if (motif.trim().isEmpty) {
			throw ArgumentError('Le motif de réorganisation est obligatoire.');
		}
		if (auteurUid.trim().isEmpty) {
			throw ArgumentError('L’auteur de la réorganisation est obligatoire.');
		}
		if (tours.isEmpty) {
			throw ArgumentError('La liste des tours ne peut pas être vide.');
		}

		final ordonnees = [...tours]
			..sort((premier, second) => premier.position.compareTo(second.position));
		if (anciennePosition < 1 || anciennePosition > ordonnees.length ||
				nouvellePosition < 1 || nouvellePosition > ordonnees.length) {
			throw RangeError('La position demandée est hors de l’échéancier.');
		}
		if (anciennePosition == nouvellePosition) {
			throw ArgumentError('La nouvelle position doit être différente.');
		}

		final indexDepart = anciennePosition - 1;
		final indexArrivee = nouvellePosition - 1;
		if (ordonnees[indexDepart].statut == StatutTour.remis ||
				ordonnees[indexArrivee].statut == StatutTour.remis) {
			throw StateError('Un tour remis ne peut pas être réorganisé.');
		}

		final deplaces = [...ordonnees];
		final tour = deplaces.removeAt(indexDepart);
		deplaces.insert(indexArrivee, tour);

		final premierTourModifiable = deplaces.indexWhere(
			(tour) => tour.statut != StatutTour.remis,
		);
		final dates = <DateTime>[];
		if (premierTourModifiable >= 0) {
			var date = deplaces[premierTourModifiable].datePrevue;
			dates.add(date);
			for (var index = premierTourModifiable + 1;
					index < deplaces.length;
					index++) {
				date = calculateur.tourSuivant(
					_reglePourTour(tontine, date),
					date,
				);
				dates.add(date);
			}
		}

		final changements = <Changement>[];
		final resultat = List<Tour>.generate(deplaces.length, (index) {
			final original = deplaces[index];
			final nouvelleDate = index >= premierTourModifiable
					? dates[index - premierTourModifiable]
					: original.datePrevue;
			final nouveauTour = Tour(
				id: original.id,
				nomId: original.nomId,
				position: index + 1,
				datePrevue: nouvelleDate,
				statut: original.statut,
				montantRemis: original.montantRemis,
			);
			if (original.position != nouveauTour.position) {
				changements.add(
					Changement(
						id: '${original.id}-${dateChangement?.microsecondsSinceEpoch ?? 0}',
						tourId: original.id,
						anciennePosition: original.position,
						nouvellePosition: nouveauTour.position,
						motif: motif.trim(),
						auteurUid: auteurUid,
						createdAt: dateChangement ?? DateTime.now(),
					),
				);
			}
			return nouveauTour;
		});

		return ReorganisationResult(
			tours: resultat,
			changements: changements,
		);
	}

	// The periodicity is shared by every tour in a tontine; this helper keeps
	// the date recalculation independent from the concrete rule subclasses.
	ReglePeriodicite _reglePourTour(Tontine tontine, DateTime date) {
		return tontine.periodicite;
	}
}
