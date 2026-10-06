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

/// Connexion tentée avant d'avoir ouvert le lien de confirmation reçu par
/// email.
final class EmailNonConfirmeException extends AuthException {
  const EmailNonConfirmeException();

  @override
  String get message => L10n.current.errorEmailNotConfirmed;
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

/// Une attribution de noms dépasserait le total prévu pour la tontine.
final class NamesQuotaExceededException extends AppException {
  const NamesQuotaExceededException([this.total]);

  /// Nombre de noms prévu, quand il est connu.
  final int? total;

  @override
  String get message => total == null
      ? L10n.current.errorNamesQuotaReached
      : L10n.current.errorNamesQuotaExceeded(total!);
}

/// Le compte fait déjà partie du groupe visé par l'invitation.
final class DejaMembreException extends AppException {
  const DejaMembreException();

  @override
  String get message => L10n.current.errorAlreadyMember;
}

/// Action réservée à un autre rôle (bureau, propriétaire).
final class ActionNonAutoriseeException extends AppException {
  const ActionNonAutoriseeException([super.details]);

  @override
  String get message => L10n.current.errorForbidden;
}

/// Suppression de compte refusée : le compte est le seul propriétaire d'un
/// groupe où d'autres personnes ont un compte.
final class TransfertProprieteRequisException extends AppException {
  const TransfertProprieteRequisException();

  @override
  String get message => L10n.current.errorTransferOwnershipRequired;
}

/// Données refusées par le serveur (règle métier non respectée). [details]
/// garde le code renvoyé (`shares_must_total_one`, `reason_required`...).
final class DonneesInvalidesException extends AppException {
  const DonneesInvalidesException([super.details]);

  @override
  String get message => switch (details) {
        'shares_must_total_one' => L10n.current.assignSharesMustTotal100,
        'contact_required' => L10n.current.memberFormContactRequired,
        'reason_required' => L10n.current.reorderReasonRequired,
        'amount_exceeds_due' => L10n.current.contribAmountExceedsDue,
        'declaration_not_pending' => L10n.current.errorDeclarationNotPending,
        'turn_already_paid' => L10n.current.errorTurnAlreadyPaid,
        'last_owner' => L10n.current.errorLastOwner,
        _ => L10n.current.errorGeneric,
      };
}

/// L'application n'est pas reliée à son serveur (URL/clé Supabase absentes
/// de la configuration de build).
final class ServeurNonConfigureException extends AppException {
  const ServeurNonConfigureException();

  @override
  String get message => L10n.current.errorServerNotConfigured;
}
