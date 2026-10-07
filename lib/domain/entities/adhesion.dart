import '../enums/role_membre.dart';
import '../enums/type_groupe.dart';

/// Appartenance du compte connecté à un groupe : la fiche membre qui le
/// représente et ses rôles dans ce groupe.
class Adhesion {
  final String groupeId;
  final String membreId;
  final String nomGroupe;
  final TypeGroupe type;
  final Set<RoleMembre> roles;
  final bool actif;

  const Adhesion({
    required this.groupeId,
    required this.membreId,
    required this.nomGroupe,
    required this.type,
    required this.roles,
    this.actif = true,
  });

  /// Membre actif du bureau (propriétaire, président ou trésorier).
  bool get estGestionnaire => actif && roles.any(RoleMembre.bureau.contains);
}
