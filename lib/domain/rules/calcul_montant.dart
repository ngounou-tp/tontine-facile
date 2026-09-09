import '../entities/nom.dart';
import '../entities/part.dart';
import 'validation_parts.dart';

class CalculMontant {
	const CalculMontant({
		this.validationParts = const ValidationParts(),
	});

	final ValidationParts validationParts;

	int calculerMontantDu({
		required int montantParNom,
		required Nom nom,
	}) {
		if (montantParNom <= 0) {
			throw ArgumentError.value(
				montantParNom,
				'montantParNom',
				'Le montant doit être strictement positif.',
			);
		}

		validationParts.valider(nom.parts);

		return (montantParNom * nom.parts.fold<double>(
			0,
			(total, part) => total + part.fraction,
		)).round();
	}

	int calculerMontantPourMembre({
		required int montantParNom,
		required Nom nom,
		required String membreId,
	}) {
		if (membreId.trim().isEmpty) {
			throw ArgumentError.value(membreId, 'membreId');
		}

		validationParts.valider(nom.parts);
		final parts = nom.parts.where((part) => part.membreId == membreId);
		final fraction = parts.fold<double>(
			0,
			(total, part) => total + part.fraction,
		);

		if (fraction == 0) {
			throw StateError('Le membre ne détient aucune part de ce nom.');
		}

		return (montantParNom * fraction).round();
	}

	int calculerMontantPourPart({
		required int montantParNom,
		required Part part,
	}) {
		if (montantParNom <= 0) {
			throw ArgumentError.value(montantParNom, 'montantParNom');
		}
		if (part.fraction <= 0 || part.fraction > 1) {
			throw ArgumentError.value(part.fraction, 'fraction');
		}

		return (montantParNom * part.fraction).round();
	}
}
