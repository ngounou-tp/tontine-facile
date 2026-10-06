// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get relativeToday => 'aujourd\'hui';

  @override
  String get relativeTomorrow => 'demain';

  @override
  String get relativeYesterday => 'hier';

  @override
  String relativeInDays(int days) {
    return 'dans $days jours';
  }

  @override
  String relativeDaysAgo(int days) {
    return 'il y a $days jours';
  }

  @override
  String get errorGeneric => 'Une erreur est survenue. Réessayez.';

  @override
  String get errorNetwork =>
      'La connexion a expiré. Vérifiez votre connexion et réessayez.';

  @override
  String get errorInvalidCredentials => 'Email ou mot de passe incorrect.';

  @override
  String get errorEmailAlreadyInUse => 'Un compte existe déjà avec cet email.';

  @override
  String get errorWeakPassword =>
      'Le mot de passe est trop faible (6 caractères minimum).';

  @override
  String get errorInvalidEmail => 'L\'adresse email est invalide.';

  @override
  String get errorUserDisabled => 'Ce compte a été désactivé.';

  @override
  String get errorTooManyRequests => 'Trop de tentatives. Réessaie plus tard.';

  @override
  String get errorSignInRequired => 'Connectez-vous pour continuer.';

  @override
  String get errorExternalSignIn =>
      'La connexion avec ce compte a échoué. Réessayez.';

  @override
  String get errorAuthUnknown => 'Erreur d\'authentification. Réessayez.';

  @override
  String get errorInvitationNotFound =>
      'Ce code d\'invitation est introuvable.';

  @override
  String get errorInvitationAlreadyUsed =>
      'Cette invitation a déjà été utilisée.';

  @override
  String get commonCancel => 'Annuler';

  @override
  String get commonRetry => 'Réessayer';

  @override
  String get commonBack => 'Retour';

  @override
  String get commonLoading => 'Chargement en cours';

  @override
  String get commonComingSoon => 'Cette fonctionnalité arrive bientôt.';

  @override
  String get amountFieldLabel => 'Montant de la cotisation';

  @override
  String get amountFieldHint => '25 000 FCFA';

  @override
  String get navHome => 'Accueil';

  @override
  String get navMembers => 'Membres';

  @override
  String get navSchedule => 'Échéancier';

  @override
  String get navDeclarations => 'Déclarations';

  @override
  String get navSettings => 'Réglages';

  @override
  String get statusPaid => 'Payé';

  @override
  String get statusLate => 'En retard';

  @override
  String get statusPartial => 'Partiel';

  @override
  String get statusException => 'Exception';

  @override
  String get statusToCollect => 'À encaisser';

  @override
  String get memberCardRecordPayment => 'Noter un paiement';

  @override
  String get memberCardMoreOptions => 'Plus d’options';

  @override
  String get authEmailLabel => 'E-mail';

  @override
  String get authPasswordLabel => 'Mot de passe';

  @override
  String get authConfirmPasswordLabel => 'Confirmer le mot de passe';

  @override
  String get authTogglePasswordVisibility =>
      'Afficher ou masquer le mot de passe';

  @override
  String get authPasswordsDoNotMatch =>
      'Les mots de passe ne correspondent pas.';

  @override
  String get authInvalidEmail => 'Saisissez une adresse e-mail valide.';

  @override
  String get authPasswordTooShort =>
      'Le mot de passe doit contenir au moins 6 caractères.';

  @override
  String get authTagline => 'Le registre de votre tontine, toujours à jour';

  @override
  String get loginEnterEmailForReset =>
      'Saisissez votre e-mail pour recevoir le lien de réinitialisation.';

  @override
  String get loginResetLinkSent =>
      'Un lien de réinitialisation a été envoyé à votre adresse e-mail.';

  @override
  String get loginSubmit => 'Se connecter';

  @override
  String get loginForgotPassword => 'Mot de passe oublié ?';

  @override
  String get commonOr => 'ou';

  @override
  String get loginContinueWithGoogle => 'Continuer avec Google';

  @override
  String get loginCreateAccount => 'Créer un compte';

  @override
  String get signupTitle => 'Créer un compte';

  @override
  String get signupSubmit => 'Créer mon compte';

  @override
  String get signupHaveAccount => 'J’ai déjà un compte';

  @override
  String welcomeTitle(String appName) {
    return 'Bienvenue sur $appName';
  }

  @override
  String get welcomeSubtitle => 'Comment souhaitez-vous commencer ?';

  @override
  String get welcomeCreateTitle => 'Créer une tontine';

  @override
  String get welcomeCreateDescription =>
      'Démarrez un nouveau groupe, invitez vos membres et suivez les cotisations dès aujourd\'hui.';

  @override
  String get welcomeJoinTitle => 'Rejoindre une tontine';

  @override
  String get welcomeJoinDescription =>
      'Vous avez reçu un code de votre trésorier ? Rejoignez son groupe en quelques secondes.';

  @override
  String get commonSignOut => 'Se déconnecter';

  @override
  String get joinEnterSixChars =>
      'Saisissez les 6 caractères du code d’invitation.';

  @override
  String get joinSuccess => 'Vous avez rejoint la tontine.';

  @override
  String get joinTitle => 'Entrez votre code d’invitation';

  @override
  String get joinSubtitle =>
      'Six caractères, remis par la trésorière du groupe.';

  @override
  String get joinPasteHint => 'Vous pouvez coller le code';

  @override
  String get joinSubmit => 'Rejoindre';

  @override
  String get joinSearching => 'Recherche de la tontine…';

  @override
  String joinMembersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count membres',
      one: '1 membre',
      zero: 'aucun membre',
    );
    return ' · $_temp0';
  }

  @override
  String get verifyStillNotVerified =>
      'Toujours pas vérifié. Pensez à vérifier vos courriers indésirables.';

  @override
  String get verifyEmailResent => 'Email de vérification renvoyé.';

  @override
  String get verifyYourAddressFallback => 'votre adresse';

  @override
  String get verifyTitle => 'Vérifiez votre adresse email';

  @override
  String verifyBody(String email) {
    return 'Un lien de vérification a été envoyé à $email. Ouvrez-le, puis revenez sur cet écran.';
  }

  @override
  String get verifyDone => 'J\'ai vérifié mon adresse';

  @override
  String verifyResendIn(int seconds) {
    return 'Renvoyer l\'email ($seconds s)';
  }

  @override
  String get verifyResend => 'Renvoyer l\'email';

  @override
  String get weekdayMonday => 'Lundi';

  @override
  String get weekdayTuesday => 'Mardi';

  @override
  String get weekdayWednesday => 'Mercredi';

  @override
  String get weekdayThursday => 'Jeudi';

  @override
  String get weekdayFriday => 'Vendredi';

  @override
  String get weekdaySaturday => 'Samedi';

  @override
  String get weekdaySunday => 'Dimanche';

  @override
  String get occurrenceFirst => 'Premier';

  @override
  String get occurrenceSecond => 'Deuxième';

  @override
  String get occurrenceThird => 'Troisième';

  @override
  String get occurrenceFourth => 'Quatrième';

  @override
  String get occurrenceLast => 'Dernier';

  @override
  String get sharesModeFixed => 'Montant fixe par part';

  @override
  String get sharesModeProportional => 'Répartition proportionnelle';

  @override
  String get sharesModeEqual => 'Parts égales';

  @override
  String get sharesModeFixedDescription =>
      'Chaque détenteur de part verse le même montant fixe, quelle que soit sa fraction.';

  @override
  String get sharesModeProportionalDescription =>
      'Chaque détenteur verse un montant proportionnel à sa fraction du nom.';

  @override
  String get sharesModeEqualDescription =>
      'Le montant du nom est réparti à parts égales entre ses détenteurs.';

  @override
  String get penaltyNone => 'Aucune pénalité';

  @override
  String get penaltyFlat => 'Pénalité forfaitaire (montant fixe)';

  @override
  String get penaltyProportional =>
      'Pénalité proportionnelle (% du montant dû)';

  @override
  String periodEveryNDays(int days) {
    return 'Tous les $days jours';
  }

  @override
  String periodWeekly(String day) {
    return 'Chaque $day';
  }

  @override
  String periodBiweekly(String day) {
    return 'Toutes les deux semaines, le $day';
  }

  @override
  String periodMonthlyDay(int day) {
    return 'Chaque mois, le $day';
  }

  @override
  String periodMonthlyWeekday(String occurrence, String day) {
    return '$occurrence $day du mois';
  }

  @override
  String get periodTypeEveryNDays => 'Tous les N jours';

  @override
  String get periodTypeWeekly => 'Chaque semaine';

  @override
  String get periodTypeBiweekly => 'Toutes les deux semaines';

  @override
  String get periodTypeMonthlyDay => 'Chaque mois, jour fixe';

  @override
  String get periodTypeMonthlyWeekday => 'Chaque mois, Nième jour de semaine';

  @override
  String get fieldFrequency => 'Fréquence';

  @override
  String get fieldDaysBetweenDueDates => 'Nombre de jours entre deux échéances';

  @override
  String get fieldDayOfMonth => 'Jour du mois (1 à 31)';

  @override
  String get fieldWeekday => 'Jour de la semaine';

  @override
  String get fieldOccurrenceInMonth => 'Occurrence dans le mois';

  @override
  String get fieldPenaltyRule => 'Règle de pénalité';

  @override
  String get fieldPenaltyAmount => 'Montant de la pénalité (FCFA)';

  @override
  String get fieldPenaltyPercent => 'Pourcentage de pénalité (%)';

  @override
  String get fieldGraceDays => 'Délai de grâce (jours, 0 à 30)';

  @override
  String get createStepGroup => 'Le groupe';

  @override
  String get createStepFrequency => 'Fréquence des échéances';

  @override
  String get createStepPenalty => 'Pénalité et délai de grâce';

  @override
  String get createStepShares => 'Répartition des parts';

  @override
  String get createStepConfirm => 'Confirmation';

  @override
  String get createErrorGroupName =>
      'Le nom du groupe doit contenir au moins 2 caractères.';

  @override
  String get createErrorFullName => 'Indiquez votre nom complet.';

  @override
  String get createErrorAmount => 'Indiquez un montant par nom valide.';

  @override
  String get createErrorNamesCount =>
      'Indiquez le nombre de noms que comptera la tontine.';

  @override
  String get createErrorFirstDueDate =>
      'Choisissez la date de la première échéance.';

  @override
  String get createErrorPenaltyValue =>
      'Indiquez une valeur de pénalité supérieure à zéro.';

  @override
  String get createErrorGraceDays =>
      'Le délai de grâce doit être compris entre 0 et 30 jours.';

  @override
  String get createSuccess =>
      'Tontine créée avec succès. Ajoutez vos premiers membres.';

  @override
  String get createPreviousStep => 'Étape précédente';

  @override
  String get createTitle => 'Créer une tontine';

  @override
  String createStepOf(int step, int total) {
    return 'Étape $step sur $total';
  }

  @override
  String get createSubmit => 'Créer la tontine';

  @override
  String get commonNext => 'Suivant';

  @override
  String get fieldGroupName => 'Nom du groupe';

  @override
  String get fieldGroupNameHint => 'Tontine des Dames';

  @override
  String get fieldYourFullName => 'Votre nom complet';

  @override
  String get fieldFullNameHint => 'Adèle Tchoumi';

  @override
  String get fieldAmountPerName => 'Montant par nom';

  @override
  String get fieldAmountHint => '25 000';

  @override
  String get fieldNamesCount => 'Nombre de noms';

  @override
  String get fieldNamesCountHelp =>
      'Combien de noms (parts) comptera la tontine au total ? Vous les attribuerez aux membres au fil des inscriptions.';

  @override
  String get fieldFirstDueDate => 'Date de la première échéance';

  @override
  String get fieldChooseDate => 'Choisir une date';

  @override
  String get recapGroup => 'Groupe';

  @override
  String get recapAdmin => 'Administratrice';

  @override
  String get recapFirstDueDate => 'Première échéance';

  @override
  String get recapPenalty => 'Pénalité';

  @override
  String get recapPenaltyValue => 'Valeur de la pénalité';

  @override
  String get recapGraceDays => 'Délai de grâce';

  @override
  String recapGraceDaysValue(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days jours',
      one: '1 jour',
      zero: '0 jour',
    );
    return '$_temp0';
  }

  @override
  String editErrorNamesBelowExisting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count noms existent déjà : le nombre de noms ne peut pas être réduit en dessous de ce total.',
      one:
          '1 nom existe déjà : le nombre de noms ne peut pas être réduit en dessous de ce total.',
    );
    return '$_temp0';
  }

  @override
  String get editSuccess => 'Tontine mise à jour.';

  @override
  String get editTitleAdmin => 'Modifier la tontine';

  @override
  String get editTitleMember => 'Réglages de la tontine';

  @override
  String get errorLoadTontine => 'Impossible de charger la tontine.';

  @override
  String get errorNoTontine => 'Aucune tontine associée à ce compte.';

  @override
  String get editSave => 'Enregistrer les modifications';

  @override
  String get editFrozenStarted => 'Figée — l\'échéancier a démarré';

  @override
  String get editReadOnlyAdminOnly =>
      'Lecture seule — réservé à l\'administratrice';

  @override
  String get editFrozenExplanation =>
      'Toute modification invaliderait les montants dus et les tours déjà calculés. Ces informations ne peuvent plus changer une fois la collecte commencée.';

  @override
  String get editAdminOnlyExplanation =>
      'Seule l\'administratrice de la tontine peut modifier ces informations.';
}
