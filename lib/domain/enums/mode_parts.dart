enum ModeParts {
  montantFixe('FIXED_AMOUNT'),
  proportionnel('PROPORTIONAL'),
  partEgale('EQUAL_SHARE');

  const ModeParts(this.id);

  /// Identifiant stable stocké dans Firestore.
  final String id;

  static ModeParts fromId(String id) {
    return values.firstWhere(
      (mode) => mode.id == id,
      orElse: () => throw FormatException(
        'Mode de parts inconnu : $id',
      ),
    );
  }

  String get libelle {
    return switch (this) {
      ModeParts.montantFixe =>
        'Montant fixe par part',

      ModeParts.proportionnel =>
        'Répartition proportionnelle',

      ModeParts.partEgale =>
        'Parts égales',
    };
  }
}