/// Libellés traduits des notions du domaine (jours, périodicités, pénalités,
/// modes de parts). Le domaine reste sans texte : c'est ici, et nulle part
/// ailleurs, qu'une valeur métier devient une phrase lisible.
library;

import '../domain/enums/jour_semaine.dart';
import '../domain/enums/mode_parts.dart';
import '../domain/enums/occurrence_mensuelle.dart';
import '../domain/enums/regle_penalite.dart';
import '../domain/value_objects/regle_periodicite.dart';
import 'l10n.dart';

extension JourSemaineLabel on JourSemaine {
  /// « Lundi » / « Monday ».
  String label(AppLocalizations l10n) => switch (this) {
        JourSemaine.lundi => l10n.weekdayMonday,
        JourSemaine.mardi => l10n.weekdayTuesday,
        JourSemaine.mercredi => l10n.weekdayWednesday,
        JourSemaine.jeudi => l10n.weekdayThursday,
        JourSemaine.vendredi => l10n.weekdayFriday,
        JourSemaine.samedi => l10n.weekdaySaturday,
        JourSemaine.dimanche => l10n.weekdaySunday,
      };

  /// Forme utilisée au milieu d'une phrase : minuscule en français
  /// (« chaque lundi »), majuscule en anglais (« every Monday »).
  String labelInSentence(AppLocalizations l10n) {
    final texte = label(l10n);
    return l10n.localeName == 'fr' ? texte.toLowerCase() : texte;
  }
}

extension OccurrenceMensuelleLabel on OccurrenceMensuelle {
  String label(AppLocalizations l10n) => switch (this) {
        OccurrenceMensuelle.premier => l10n.occurrenceFirst,
        OccurrenceMensuelle.deuxieme => l10n.occurrenceSecond,
        OccurrenceMensuelle.troisieme => l10n.occurrenceThird,
        OccurrenceMensuelle.quatrieme => l10n.occurrenceFourth,
        OccurrenceMensuelle.dernier => l10n.occurrenceLast,
      };
}

extension ModePartsLabel on ModeParts {
  String label(AppLocalizations l10n) => switch (this) {
        ModeParts.montantFixe => l10n.sharesModeFixed,
        ModeParts.proportionnel => l10n.sharesModeProportional,
        ModeParts.partEgale => l10n.sharesModeEqual,
      };

  String description(AppLocalizations l10n) => switch (this) {
        ModeParts.montantFixe => l10n.sharesModeFixedDescription,
        ModeParts.proportionnel => l10n.sharesModeProportionalDescription,
        ModeParts.partEgale => l10n.sharesModeEqualDescription,
      };
}

extension ReglePenaliteLabel on ReglePenalite {
  String label(AppLocalizations l10n) => switch (this) {
        ReglePenalite.aucune => l10n.penaltyNone,
        ReglePenalite.forfaitaire => l10n.penaltyFlat,
        ReglePenalite.proportionnelle => l10n.penaltyProportional,
      };
}

/// « Chaque lundi », « Every 7 days », « First Monday of the month »…
String periodiciteLabel(ReglePeriodicite regle, AppLocalizations l10n) => switch (regle) {
      RegleTousLesNJours(:final jours) => l10n.periodEveryNDays(jours),
      RegleChaqueSemaine(:final jour) => l10n.periodWeekly(jour.labelInSentence(l10n)),
      RegleToutesLesDeuxSemaines(:final jour) => l10n.periodBiweekly(jour.labelInSentence(l10n)),
      RegleChaqueMoisJourFixe(:final jour) => l10n.periodMonthlyDay(jour),
      RegleChaqueMoisSemaine(:final occurrence, :final jour) =>
        l10n.periodMonthlyWeekday(occurrence.label(l10n), jour.labelInSentence(l10n)),
    };
