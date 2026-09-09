import '../entities/part.dart';

class ValidationParts {
	const ValidationParts();

	void valider(List<Part> parts) {
		if (parts.isEmpty) {
			throw ArgumentError('Un nom doit avoir au moins une part.');
		}

		final somme = parts.fold<double>(
			0,
			(total, part) {
				if (part.fraction <= 0 || part.fraction > 1) {
					throw ArgumentError(
						'Chaque fraction doit être supérieure à 0 et inférieure ou égale à 1.',
					);
				}
				if (part.membreId.trim().isEmpty) {
					throw ArgumentError('Chaque part doit être rattachée à un membre.');
				}
				return total + part.fraction;
			},
		);

		if ((somme - 1).abs() > 0.000001) {
			throw ArgumentError('La somme des fractions doit être égale à 1.');
		}
	}

	bool estValide(List<Part> parts) {
		try {
			valider(parts);
			return true;
		} on ArgumentError {
			return false;
		}
	}
}
