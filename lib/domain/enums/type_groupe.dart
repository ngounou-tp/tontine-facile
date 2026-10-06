/// Nature d'un groupe : tontine rotative ou caisse d'épargne et de crédit.
enum TypeGroupe {
  tontine('tontine'),
  caisse('caisse');

  const TypeGroupe(this.id);

  final String id;

  static TypeGroupe fromId(String id) => values.firstWhere(
        (type) => type.id == id,
        orElse: () => throw FormatException('Type de groupe inconnu : $id'),
      );
}
