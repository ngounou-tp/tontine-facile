/// Représente un jour de la semaine.
///
/// Les valeurs correspondent directement à DateTime.weekday :
/// lundi = 1 ... dimanche = 7.
enum JourSemaine {
  lundi(1),
  mardi(2),
  mercredi(3),
  jeudi(4),
  vendredi(5),
  samedi(6),
  dimanche(7);

  const JourSemaine(this.value);

  final int value;

  static JourSemaine fromInt(int value) {
    return JourSemaine.values.firstWhere(
      (jour) => jour.value == value,
      orElse: () => throw FormatException(
        'Jour de la semaine invalide : $value',
      ),
    );
  }
}