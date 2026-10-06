import '../../l10n/l10n.dart';

/// Erreur métier présentable à l'utilisateur.
///
/// Chaque sous-classe décrit une situation précise ; son texte est traduit
/// au moment de l'affichage ([message]) dans la langue courante de l'app.
/// [details] porte, si besoin, une information technique (code d'erreur
/// d'un fournisseur) jamais traduite.
sealed class AppException implements Exception {
  const AppException([this.details]);

  final String? details;

  String get message;

  @override
  String toString() => '$runtimeType: ${details ?? message}';
}

/// Délai réseau dépassé ou service injoignable.
final class NetworkException extends AppException {
  const NetworkException([super.details]);

  @override
  String get message => L10n.current.errorNetwork;
}

/// Erreurs d'authentification (Inscription, Connexion, Reset password),
/// mappées depuis les codes du fournisseur d'authentification.
sealed class AuthException extends AppException {
  const AuthException([super.details]);
}

/// Email/mot de passe incorrect à la connexion. Regroupe les codes
/// `wrong-password`, `user-not-found` et `invalid-credential` : les séparer
/// permettrait à un client malveillant de savoir si un email est enregistré.
final class InvalidCredentialsException extends AuthException {
  const InvalidCredentialsException();

  @override
  String get message => L10n.current.errorInvalidCredentials;
}

final class EmailAlreadyInUseException extends AuthException {
  const EmailAlreadyInUseException();

  @override
  String get message => L10n.current.errorEmailAlreadyInUse;
}

final class WeakPasswordException extends AuthException {
  const WeakPasswordException();

  @override
  String get message => L10n.current.errorWeakPassword;
}

final class InvalidEmailException extends AuthException {
  const InvalidEmailException();

  @override
  String get message => L10n.current.errorInvalidEmail;
}

final class UserDisabledException extends AuthException {
  const UserDisabledException();

  @override
  String get message => L10n.current.errorUserDisabled;
}

final class TooManyRequestsException extends AuthException {
  const TooManyRequestsException();

  @override
  String get message => L10n.current.errorTooManyRequests;
}

/// Action qui exige d'être connecté, tentée sans session.
final class SignInRequiredException extends AuthException {
  const SignInRequiredException();

  @override
  String get message => L10n.current.errorSignInRequired;
}

/// La connexion via un fournisseur externe (Google, Apple) a échoué.
final class ExternalSignInException extends AuthException {
  const ExternalSignInException([super.details]);

  @override
  String get message => L10n.current.errorExternalSignIn;
}

/// Erreur d'authentification non répertoriée ; [details] garde le code.
final class UnknownAuthException extends AuthException {
  const UnknownAuthException([super.details]);

  @override
  String get message => L10n.current.errorAuthUnknown;
}

/// Le code saisi ne correspond à aucune invitation.
final class InvitationIntrouvableException extends AppException {
  const InvitationIntrouvableException();

  @override
  String get message => L10n.current.errorInvitationNotFound;
}

/// La fiche membre visée par l'invitation a déjà été réclamée.
final class InvitationDejaUtiliseeException extends AppException {
  const InvitationDejaUtiliseeException();

  @override
  String get message => L10n.current.errorInvitationAlreadyUsed;
}
