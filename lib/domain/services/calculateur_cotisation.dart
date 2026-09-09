import '../entities/nom.dart';
import '../entities/tontine.dart';
import '../rules/calcul_montant.dart';
import '../rules/calcul_penalite.dart';

class CalculateurCotisation {
	const CalculateurCotisation({
		this.calculMontant = const CalculMontant(),
		this.calculPenalite = const CalculPenalite(),
	});

	final CalculMontant calculMontant;
	final CalculPenalite calculPenalite;

	int calculerMontantDu({
		required Tontine tontine,
		required Nom nom,
	}) {
		return calculMontant.calculerMontantDu(
			montantParNom: tontine.montantParNom,
			nom: nom,
		);
	}

	int calculerMontantDuPourMembre({
		required Tontine tontine,
		required Nom nom,
		required String membreId,
	}) {
		return calculMontant.calculerMontantPourMembre(
			montantParNom: tontine.montantParNom,
			nom: nom,
			membreId: membreId,
		);
	}

	int calculerPenalite({
		required Tontine tontine,
		required Nom nom,
		required DateTime datePaiement,
		required DateTime dateEcheance,
	}) {
		return calculPenalite.calculer(
			montantDu: calculerMontantDu(tontine: tontine, nom: nom),
			dateEcheance: dateEcheance,
			datePaiement: datePaiement,
			delaiGraceJours: tontine.delaiGraceJours,
			regle: tontine.reglePenalite,
			valeurPenalite: tontine.valeurPenalite,
		);
	}

	int calculerResteADu({
		required Tontine tontine,
		required Nom nom,
		required int montantVerse,
	}) {
		if (montantVerse < 0) {
			throw ArgumentError.value(montantVerse, 'montantVerse');
		}
		return calculerMontantDu(tontine: tontine, nom: nom) - montantVerse;
	}

	int calculerResteADuPourMembre({
		required Tontine tontine,
		required Nom nom,
		required String membreId,
		required int montantVerse,
	}) {
		if (montantVerse < 0) {
			throw ArgumentError.value(montantVerse, 'montantVerse');
		}
		return calculerMontantDuPourMembre(
			tontine: tontine,
			nom: nom,
			membreId: membreId,
		) - montantVerse;
	}
}
