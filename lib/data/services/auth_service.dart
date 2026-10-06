import '../../domain/entities/app_user.dart';

/// Résultat d'une inscription : l'utilisateur créé, et s'il est déjà
/// connecté. Quand la confirmation d'email est exigée, aucune session
/// n'existe tant que le lien reçu par email n'a pas été ouvert.
typedef ResultatInscription = ({AppUser utilisateur, bool connecte});

/// Abstraction du service d'authentification : Inscription, Connexion,
/// Déconnexion, réinitialisation de mot de passe et session courante.
///
/// Les implémentations doivent lancer une sous-classe d'`AuthException`
/// (voir `core/errors/app_exception.dart`) plutôt que de laisser fuiter le
/// type d'erreur du SDK sous-jacent.
abstract interface class AuthService {
  /// Utilisateur actuellement connecté, ou `null` si aucune session.
  AppUser? get currentUser;

  /// Session : émet un nouvel `AppUser` à chaque connexion et `null` à
  /// chaque déconnexion.
  Stream<AppUser?> get authStateChanges;

  /// Inscription par email + mot de passe.
  Future<ResultatInscription> signUp({required String email, required String password});

  /// Connexion par email + mot de passe.
  Future<AppUser> signIn({required String email, required String password});

  /// Connexion (ou création implicite de compte) via Google. `null` si
  /// l'utilisateur annule — ce n'est pas une erreur.
  Future<AppUser?> signInWithGoogle();

  /// Connexion via Apple (obligatoire sur iOS dès qu'une connexion tierce
  /// est proposée). `null` si l'utilisateur annule.
  Future<AppUser?> signInWithApple();

  /// Déconnexion de la session courante.
  Future<void> signOut();

  /// Envoie un email de réinitialisation de mot de passe.
  Future<void> sendPasswordResetEmail(String email);

  /// Renvoie l'email de confirmation d'inscription à [email].
  Future<void> resendConfirmation(String email);

  /// Recharge l'utilisateur courant depuis le serveur et renvoie son état
  /// à jour, ou `null` si personne n'est connecté.
  Future<AppUser?> reloadUser();
}
