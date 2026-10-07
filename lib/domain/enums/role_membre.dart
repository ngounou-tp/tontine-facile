/// Rôle d'un membre dans un groupe. Un même compte peut cumuler plusieurs
/// rôles dans un groupe, et avoir des rôles différents d'un groupe à
/// l'autre.
enum RoleMembre {
  /// Créateur du groupe : gère les rôles des autres membres.
  proprietaire('owner'),
  president('president'),
  tresorier('treasurer'),

  /// Commissaire aux comptes : lecture étendue, aucune validation.
  commissaire('auditor'),
  membre('member');

  const RoleMembre(this.id);

  /// Valeur stockée côté serveur (`member_role`).
  final String id;

  static RoleMembre fromId(String id) => values.firstWhere(
        (role) => role.id == id,
        orElse: () => throw FormatException('Rôle inconnu : $id'),
      );

  /// Rôles du bureau : gestion quotidienne du groupe (membres, noms,
  /// tours, cotisations, validations).
  static const bureau = {proprietaire, president, tresorier};
}
