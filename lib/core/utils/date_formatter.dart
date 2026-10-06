/// Dates affichées à l'utilisateur, dans la langue de l'app, sans dépendre
/// des données de locale d'`intl` (qui exigent une initialisation
/// asynchrone).
library;

import '../../l10n/l10n.dart';

const _mois = {
  'fr': ['janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin', 'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'],
  'en': ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'],
};

const _joursCourts = {
  'fr': ['lun.', 'mar.', 'mer.', 'jeu.', 'ven.', 'sam.', 'dim.'],
  'en': ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
};

bool get _anglais => L10n.current.localeName == 'en';

List<String> get _moisCourants => _mois[_anglais ? 'en' : 'fr']!;

/// `10 janv. 2026` / `Jan 10, 2026` : se lit d'un coup d'œil, sans décoder
/// un `10/01/2026` (jour ou mois en premier ?).
String formatDate(DateTime date) {
  final mois = _moisCourants[date.month - 1];
  return _anglais ? '$mois ${date.day}, ${date.year}' : '${date.day} $mois ${date.year}';
}

/// `sam. 10 janv.` / `Sat, Jan 10` : pour les échéances proches, où le jour
/// de la semaine compte plus que l'année.
String formatDateCourte(DateTime date) {
  final jour = _joursCourts[_anglais ? 'en' : 'fr']![date.weekday - 1];
  final mois = _moisCourants[date.month - 1];
  return _anglais ? '$jour, $mois ${date.day}' : '$jour ${date.day} $mois';
}

/// Distance relative à aujourd'hui pour une échéance : « aujourd'hui »,
/// « demain », « dans 5 jours », « il y a 2 jours ».
String formatEcheanceRelative(DateTime date, {DateTime? maintenant}) {
  final now = maintenant ?? DateTime.now();
  final aujourdhui = DateTime(now.year, now.month, now.day);
  final jour = DateTime(date.year, date.month, date.day);
  final ecart = jour.difference(aujourdhui).inDays;
  final l10n = L10n.current;
  return switch (ecart) {
    0 => l10n.relativeToday,
    1 => l10n.relativeTomorrow,
    -1 => l10n.relativeYesterday,
    > 1 => l10n.relativeInDays(ecart),
    _ => l10n.relativeDaysAgo(-ecart),
  };
}
