import '../entities/tontine.dart';
import '../enums/regle_penalite.dart';

class ValidationTontine {
	const ValidationTontine();

	void valider(Tontine tontine) {
		if (tontine.nom.trim().length < 2) {
			throw ArgumentError('Le nom de la tontine doit avoir au moins 2 caractères.');
		}
		if (tontine.montantParNom <= 0) {
			throw ArgumentError('Le montant par nom doit être supérieur à zéro.');
		}
		if (tontine.nombreDeNoms <= 0) {
			throw ArgumentError('Le nombre de noms doit être supérieur à zéro.');
		}
		if (tontine.delaiGraceJours < 0 || tontine.delaiGraceJours > 30) {
			throw ArgumentError('Le délai de grâce doit être compris entre 0 et 30 jours.');
		}
		if (tontine.reglePenalite != ReglePenalite.aucune &&
				(tontine.valeurPenalite == null || tontine.valeurPenalite! <= 0)) {
			throw ArgumentError('Une règle de pénalité exige une valeur positive.');
		}
		if (tontine.reglePenalite == ReglePenalite.aucune &&
				tontine.valeurPenalite != null) {
			throw ArgumentError('Une tontine sans pénalité ne peut pas avoir de valeur.');
		}
	}
}
