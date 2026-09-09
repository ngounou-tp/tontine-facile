import '../enums/regle_penalite.dart';

class CalculPenalite {
	const CalculPenalite();

	int calculer({
		required int montantDu,
		required DateTime dateEcheance,
		required DateTime datePaiement,
		required int delaiGraceJours,
		required ReglePenalite regle,
		int? valeurPenalite,
	}) {
		if (montantDu <= 0) {
			throw ArgumentError.value(montantDu, 'montantDu');
		}
		if (delaiGraceJours < 0) {
			throw ArgumentError.value(delaiGraceJours, 'delaiGraceJours');
		}

		final limite = DateTime(
			dateEcheance.year,
			dateEcheance.month,
			dateEcheance.day + delaiGraceJours,
		);
		if (!datePaiement.isAfter(limite) || regle == ReglePenalite.aucune) {
			return 0;
		}

		final valeur = valeurPenalite;
		if (valeur == null || valeur <= 0) {
			throw ArgumentError.value(
				valeur,
				'valeurPenalite',
				'La valeur de pénalité doit être strictement positive.',
			);
		}

		return switch (regle) {
			ReglePenalite.aucune => 0,
			ReglePenalite.forfaitaire => valeur,
			ReglePenalite.proportionnelle => (montantDu * valeur / 100).round(),
		};
	}
}
