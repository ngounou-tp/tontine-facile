/// Dates affichées à l'utilisateur, en français, sans dépendre des données
/// de locale d'`intl` (qui exigent une initialisation asynchrone).
library;

const _mois = [
  'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
  'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.',
];

const _joursCourts = ['lun.', 'mar.', 'mer.', 'jeu.', 'ven.', 'sam.', 'dim.'];

/// `10 janv. 2026` : se lit d'un coup d'œil, sans décoder un `10/01/2026`
/// (jour ou mois en premier ?).
String formatDate(DateTime date) => '${date.day} ${_mois[date.month - 1]} ${date.year}';

/// `sam. 10 janv.` : pour les échéances proches, où le jour de la semaine
/// compte plus que l'année.
String formatDateCourte(DateTime date) =>
    '${_joursCourts[date.weekday - 1]} ${date.day} ${_mois[date.month - 1]}';

/// Distance relative à aujourd'hui pour une échéance : « aujourd'hui »,
/// « demain », « dans 5 jours », « il y a 2 jours ».
String formatEcheanceRelative(DateTime date, {DateTime? maintenant}) {
  final now = maintenant ?? DateTime.now();
  final aujourdhui = DateTime(now.year, now.month, now.day);
  final jour = DateTime(date.year, date.month, date.day);
  final ecart = jour.difference(aujourdhui).inDays;
  return switch (ecart) {
    0 => "aujourd'hui",
    1 => 'demain',
    -1 => 'hier',
    > 1 => 'dans $ecart jours',
    _ => 'il y a ${-ecart} jours',
  };
}
