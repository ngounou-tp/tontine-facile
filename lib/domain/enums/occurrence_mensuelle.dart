/// Position d'un jour de semaine à l'intérieur d'un mois.
enum OccurrenceMensuelle {
  premier(1),
  deuxieme(2),
  troisieme(3),
  quatrieme(4),
  dernier(5);

  const OccurrenceMensuelle(this.value);

  final int value;

  static OccurrenceMensuelle fromInt(int value) {
    return OccurrenceMensuelle.values.firstWhere(
      (occurrence) => occurrence.value == value,
      orElse: () => throw FormatException(
        'Occurrence mensuelle invalide : $value',
      ),
    );
  }
}