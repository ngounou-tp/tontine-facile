import '../enums/jour_semaine.dart';
import '../enums/occurrence_mensuelle.dart';
import '../value_objects/regle_periodicite.dart';

class CalculateurPeriodicite {
	const CalculateurPeriodicite();

	DateTime prochainTour(ReglePeriodicite regle, DateTime reference) {
		final date = _normaliser(reference);
		return switch (regle) {
			RegleTousLesNJours(:final jours) =>
				date.add(Duration(days: jours)),
			RegleChaqueSemaine(:final jour) => _prochainJour(date, jour.value, 7),
			RegleToutesLesDeuxSemaines(:final jour) =>
				_prochainJour(date, jour.value, 14),
			RegleChaqueMoisJourFixe(:final jour) => _prochainJourMoisFixe(date, jour),
			RegleChaqueMoisSemaine(:final occurrence, :final jour) =>
				_prochainJourOccurrence(date, occurrence, jour),
		};
	}

	DateTime tourSuivant(ReglePeriodicite regle, DateTime tourActuel) {
		final date = _normaliser(tourActuel);
		return switch (regle) {
			RegleTousLesNJours(:final jours) =>
				date.add(Duration(days: jours)),
			RegleChaqueSemaine() => date.add(const Duration(days: 7)),
			RegleToutesLesDeuxSemaines() => date.add(const Duration(days: 14)),
			RegleChaqueMoisJourFixe(:final jour) => _moisSuivantJourFixe(date, jour),
			RegleChaqueMoisSemaine(:final occurrence, :final jour) =>
				_moisSuivantOccurrence(date, occurrence, jour),
		};
	}

	List<DateTime> genererEcheancier({
		required ReglePeriodicite regle,
		required DateTime dateDebut,
		required int nombreDeTours,
	}) {
		if (nombreDeTours <= 0) {
			throw ArgumentError('Le nombre de tours doit être supérieur à 0.');
		}
		final dates = <DateTime>[_normaliser(dateDebut)];
		while (dates.length < nombreDeTours) {
			dates.add(tourSuivant(regle, dates.last));
		}
		return dates;
	}

	DateTime _prochainJour(DateTime reference, int weekday, int intervalle) {
		var difference = weekday - reference.weekday;
		if (difference <= 0) difference += intervalle;
		return reference.add(Duration(days: difference));
	}

	DateTime _prochainJourMoisFixe(DateTime reference, int jour) {
		final candidat = _dateJourMois(reference.year, reference.month, jour);
		return candidat.isAfter(reference)
				? candidat
				: _moisSuivantJourFixe(reference, jour);
	}

	DateTime _moisSuivantJourFixe(DateTime reference, int jour) {
		final mois = _moisSuivant(reference);
		return _dateJourMois(mois.year, mois.month, jour);
	}

	DateTime _prochainJourOccurrence(
		DateTime reference,
		OccurrenceMensuelle occurrence,
		JourSemaine jour,
	) {
		final candidat = _occurrenceDansMois(
			reference.year,
			reference.month,
			jour.value,
			occurrence,
		);
		return candidat != null && candidat.isAfter(reference)
				? candidat
				: _moisSuivantOccurrence(reference, occurrence, jour);
	}

	DateTime _moisSuivantOccurrence(
		DateTime reference,
		OccurrenceMensuelle occurrence,
		JourSemaine jour,
	) {
		var mois = _moisSuivant(reference);
		DateTime? candidat;
		while (candidat == null) {
			candidat = _occurrenceDansMois(
				mois.year,
				mois.month,
				jour.value,
				occurrence,
			);
			if (candidat == null) mois = _moisSuivant(mois);
		}
		return candidat;
	}

	DateTime? _occurrenceDansMois(
		int year,
		int month,
		int weekday,
		OccurrenceMensuelle occurrence,
	) {
		if (occurrence == OccurrenceMensuelle.dernier) {
			final dernierJour = DateTime(year, month + 1, 0);
			final difference = (dernierJour.weekday - weekday + 7) % 7;
			return DateTime(year, month, dernierJour.day - difference);
		}
		final premierJour = DateTime(year, month, 1);
		final difference = (weekday - premierJour.weekday + 7) % 7;
		final jour = 1 + difference + ((occurrence.value - 1) * 7);
		if (jour > _nombreJoursDansMois(year, month)) return null;
		return DateTime(year, month, jour);
	}

	DateTime _dateJourMois(int year, int month, int jour) {
		final dernierJour = _nombreJoursDansMois(year, month);
		return DateTime(year, month, jour > dernierJour ? dernierJour : jour);
	}

	int _nombreJoursDansMois(int year, int month) =>
			DateTime(year, month + 1, 0).day;

	DateTime _moisSuivant(DateTime date) => date.month == 12
			? DateTime(date.year + 1, 1)
			: DateTime(date.year, date.month + 1);

	DateTime _normaliser(DateTime date) => DateTime(date.year, date.month, date.day);
}
