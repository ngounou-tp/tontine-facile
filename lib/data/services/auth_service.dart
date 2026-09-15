import '../../domain/entities/app_user.dart';

/// Abstraction sur Firebase Auth : Inscription, Connexion, Déconnexion,
/// réinitialisation de mot de passe et session courante.
///
/// Les implémentations doivent lancer une sous-classe d'`AuthException`
/// (voir `core/errors/app_exception.dart`) plutôt que de laisser fuiter le
/// type d'erreur du SDK sous-jacent.
abstract interface class AuthService {
  /// Utilisateur actuellement connecté, ou `null` si aucune session.
  AppUser? get currentUser;

  /// Session : émet un nouvel `AppUser` à chaque connexion et `null` à
  /// chaque déconnexion. À écouter au démarrage de l'application pour
  /// savoir si l'utilisateur doit voir l'écran de connexion.
  Stream<AppUser?> get authStateChanges;

  /// Inscription par email + mot de passe.
  Future<AppUser> signUp({required String email, required String password});

  /// Connexion par email + mot de passe.
  Future<AppUser> signIn({required String email, required String password});

  /// Connexion (ou création implicite de compte) via Google.
  ///
  /// Renvoie `null` si l'utilisateur annule la sélection de compte — ce n'est
  /// pas une erreur, l'appelant doit simplement ne rien faire dans ce cas.
  Future<AppUser?> signInWithGoogle();

  /// Déconnexion de la session courante.
  Future<void> signOut();

  /// Envoie un email de réinitialisation de mot de passe.
  Future<void> sendPasswordResetEmail(String email);

  /// Envoie un email de vérification à l'utilisateur actuellement connecté.
  /// Ne fait rien si personne n'est connecté.
  Future<void> sendEmailVerification();

  /// Recharge l'utilisateur courant depuis Firebase (après un clic sur le
  /// lien de vérification, par exemple) et renvoie son état à jour, ou
  /// `null` si personne n'est connecté.
  Future<AppUser?> reloadUser();
}
