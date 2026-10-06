import '../enums/role_membre.dart';

/// Groupe courant du compte connecté : le groupe affiché par l'app et la
/// fiche membre qui le représente dans ce groupe.
///
/// [tontineId] est l'identifiant du groupe (nom conservé pour les écrans
/// existants, qui ne gèrent encore que des tontines).
class Profil {
  final String uid;
  final String tontineId;
  final String membreId;
  final Set<RoleMembre> roles;

  const Profil({
    required this.uid,
    required this.tontineId,
    required this.membreId,
    this.roles = const {RoleMembre.membre},
  });

  bool get estGestionnaire => roles.any(RoleMembre.bureau.contains);
}
