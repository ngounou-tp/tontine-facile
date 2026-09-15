/// Utilisateur authentifié (session Firebase Auth), indépendant du profil
/// métier stocké dans `utilisateurs/{uid}` (voir `Membre`).
class AppUser {
  final String uid;
  final String? email;
  final bool emailVerified;

  const AppUser({
    required this.uid,
    this.email,
    this.emailVerified = false,
  });
}
