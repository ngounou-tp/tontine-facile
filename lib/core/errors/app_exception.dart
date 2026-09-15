sealed class AppException implements Exception {
  const AppException(this.message);

  final String message;
}

final class NetworkException extends AppException {
  const NetworkException(super.message);
}

/// Erreurs d'authentification (Inscription, Connexion, Reset password),
/// mappées depuis les codes de `FirebaseAuthException` par
/// `mapFirebaseAuthException`.
sealed class AuthException extends AppException {
  const AuthException(super.message);
}

/// Email/mot de passe incorrect à la connexion. Regroupe les codes Firebase
/// `wrong-password`, `user-not-found` et `invalid-credential` : les séparer
/// permettrait à un client malveillant de savoir si un email est enregistré.
final class InvalidCredentialsException extends AuthException {
  const InvalidCredentialsException()
      : super('Email ou mot de passe incorrect.');
}

final class EmailAlreadyInUseException extends AuthException {
  const EmailAlreadyInUseException()
      : super('Un compte existe déjà avec cet email.');
}

final class WeakPasswordException extends AuthException {
  const WeakPasswordException()
      : super('Le mot de passe est trop faible (6 caractères minimum).');
}

final class InvalidEmailException extends AuthException {
  const InvalidEmailException() : super("L'adresse email est invalide.");
}

final class UserDisabledException extends AuthException {
  const UserDisabledException() : super('Ce compte a été désactivé.');
}

final class TooManyRequestsException extends AuthException {
  const TooManyRequestsException()
      : super('Trop de tentatives. Réessaie plus tard.');
}

final class UnknownAuthException extends AuthException {
  const UnknownAuthException(super.message);
}

/// Le code saisi ne correspond à aucune invitation (`invitations/{code}`).
final class InvitationIntrouvableException extends AppException {
  const InvitationIntrouvableException()
      : super("Ce code d'invitation est introuvable.");
}

/// Le placeholder membre visé par l'invitation a déjà été réclamé
/// (`membres/{id}.uid` déjà renseigné) — les règles Firestore l'interdisent.
final class InvitationDejaUtiliseeException extends AppException {
  const InvitationDejaUtiliseeException()
      : super('Cette invitation a déjà été utilisée.');
}
