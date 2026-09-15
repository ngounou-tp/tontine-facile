import 'app_user.dart';
import 'profil.dart';

/// Session applicative : l'utilisateur Firebase Auth courant, et le profil
/// qui le relie à une tontine s'il en a déjà un.
///
/// [profil] est `null` pour un compte authentifié mais dont l'inscription
/// (création de tontine ou adhésion) n'a pas abouti — normalement transitoire.
class Session {
  final AppUser utilisateur;
  final Profil? profil;

  const Session({required this.utilisateur, this.profil});
}
