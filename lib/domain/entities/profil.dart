/// Profil applicatif d'un utilisateur authentifié : `utilisateurs/{uid}`.
///
/// Relie un compte Firebase Auth (`uid`) à la tontine et au membre qu'il
/// représente. Un utilisateur sans profil est authentifié mais n'a encore
/// rejoint ni créé aucune tontine.
class Profil {
  final String uid;
  final String tontineId;
  final String membreId;

  const Profil({
    required this.uid,
    required this.tontineId,
    required this.membreId,
  });
}
