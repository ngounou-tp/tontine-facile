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
  String get verifyEmailResent => 'Email de vérification renvoyé.';

  @override
  String get verifyYourAddressFallback => 'votre adresse';

  @override
  String get verifyTitle => 'Vérifiez votre adresse email';

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

  @override
  String get homeAddMember => 'Ajouter un membre';

  @override
  String get homeLoading => 'Chargement de votre tontine…';

  @override
  String get homeLoadError => 'Impossible de charger votre tontine.';

  @override
  String get homeHello => 'Bonjour';

  @override
  String homeHelloName(String name) {
    return 'Bonjour, $name';
  }

  @override
  String homeSubtitlePending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count paiements attendent votre validation.',
      one: 'Un paiement attend votre validation.',
      zero: 'Voici le résumé de votre tontine.',
    );
    return '$_temp0';
  }

  @override
  String get homeSubtitleMember => 'Voici le résumé de votre tontine.';

  @override
  String get homeAtAGlance => 'En un coup d\'œil';

  @override
  String get commonSeeAll => 'Voir tout';

  @override
  String get homeNoActiveMembers => 'Aucun membre actif pour le moment';

  @override
  String homeActiveMembers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count membres actifs',
      one: '1 membre actif',
    );
    return '$_temp0';
  }

  @override
  String get unknownName => 'Nom inconnu';

  @override
  String get tourScheduleToPrepare => 'Échéancier à préparer';

  @override
  String get tourScheduleToPrepareMessage =>
      'L\'échéancier n\'a pas encore été généré. Attribuez les noms puis générez-le depuis Membres.';

  @override
  String get tourGoToMembers => 'Aller aux membres';

  @override
  String get tourTontineFinished => 'Tontine terminée';

  @override
  String get tourTontineFinishedMessage =>
      'Tous les tours ont été remis. Bravo !';

  @override
  String tourCurrentOverline(int position) {
    return 'TOUR $position · EN COURS';
  }

  @override
  String tourReceives(String amount, String date, String relative) {
    return 'Reçoit $amount · $date ($relative)';
  }

  @override
  String tourCollectedOf(String amount) {
    return 'collectés sur $amount';
  }

  @override
  String get tourSeeCollection => 'Voir la collecte';

  @override
  String get tourCollect => 'Collecter les cotisations';

  @override
  String percentValue(int value) {
    return '$value %';
  }

  @override
  String statsActiveMembers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Membres actifs',
      one: 'Membre actif',
      zero: 'Membre actif',
    );
    return '$_temp0';
  }

  @override
  String get statsNamesAssigned => 'Noms attribués';

  @override
  String get statsTurnsPaid => 'Tours remis';

  @override
  String get statsOnTimeLate => 'À temps / en retard';

  @override
  String bannerPendingDeclarations(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count déclarations de paiement à traiter',
      one: '1 déclaration de paiement à traiter',
    );
    return '$_temp0';
  }

  @override
  String get bannerCheckProofs =>
      'Vérifiez les preuves pour valider les paiements.';

  @override
  String get settingsSignOutTitle => 'Se déconnecter ?';

  @override
  String get settingsSignOutMessage =>
      'Vous devrez vous reconnecter pour accéder à votre tontine.';

  @override
  String get settingsTitle => 'Réglages';

  @override
  String get settingsSectionGroup => 'Groupe';

  @override
  String get settingsTontineSettings => 'Réglages de la tontine';

  @override
  String get settingsTontineSettingsAdmin =>
      'Nom, montant, pénalité, nombre de noms';

  @override
  String get settingsTontineSettingsMember => 'Consulter (lecture seule)';

  @override
  String get settingsSectionAccount => 'Compte';

  @override
  String get settingsMyProfile => 'Mon profil';

  @override
  String get settingsMyProfileAdmin =>
      'Vos coordonnées et votre code d\'invitation';

  @override
  String get settingsMyProfileMember =>
      'Vos noms, vos cotisations et vos déclarations';

  @override
  String get settingsSectionPreferences => 'Préférences';

  @override
  String get settingsLanguage => 'Langue';

  @override
  String get settingsLanguageSystem => 'Langue du téléphone';

  @override
  String get languageFrench => 'Français';

  @override
  String get languageEnglish => 'English';

  @override
  String namesCountWhole(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count noms',
      one: '1 nom',
      zero: '0 nom',
    );
    return '$_temp0';
  }

  @override
  String get namesCountHalfOnly => '½ nom';

  @override
  String namesCountWithHalf(int count) {
    return '$count½ noms';
  }

  @override
  String get namesRemoveHalf => 'Retirer une demie';

  @override
  String get namesAddHalf => 'Ajouter une demie';

  @override
  String get membersTitle => 'Membres';

  @override
  String membersTabNames(int count) {
    return 'Noms ($count)';
  }

  @override
  String membersTabMembers(int count) {
    return 'Membres ($count)';
  }

  @override
  String get commonAdd => 'Ajouter';

  @override
  String get membersLoadError => 'Impossible de charger les membres.';

  @override
  String get membersSectionNames => 'Noms';

  @override
  String get membersAssign => 'Attribuer';

  @override
  String get membersNoNamesYet =>
      'Aucun nom n\'a encore été créé. Attribuez le premier pour commencer.';

  @override
  String get membersAssignName => 'Attribuer un nom';

  @override
  String get membersGenerateSchedule => 'Générer l\'échéancier';

  @override
  String membersNamesLeftBeforeSchedule(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Encore $count noms à attribuer avant de pouvoir générer l\'échéancier.',
      one: 'Encore 1 nom à attribuer avant de pouvoir générer l\'échéancier.',
    );
    return '$_temp0';
  }

  @override
  String membersActiveSection(int count) {
    return 'Membres actifs ($count)';
  }

  @override
  String get membersNoActive => 'Aucun membre actif pour le moment.';

  @override
  String membersInactiveSection(int count) {
    return 'Membres désactivés ($count)';
  }

  @override
  String get unknownMember => 'Membre inconnu';

  @override
  String get membersNoHolder => 'Aucun détenteur';

  @override
  String get membersToComplete => 'À compléter';

  @override
  String get membersNoContact => 'Aucun contact';

  @override
  String get membersPending => 'En attente';

  @override
  String membersNamesAssignedOf(int total) {
    return '/$total noms attribués';
  }

  @override
  String get membersComplete => 'Complet';

  @override
  String get addMemberCodeCopied => 'Code copié.';

  @override
  String get addMemberTitle => 'Ajouter un membre';

  @override
  String get addMemberSubmit => 'Ajouter et générer le code';

  @override
  String addMemberAddedFlash(String name) {
    return '$name a été ajouté(e) à la tontine.';
  }

  @override
  String addMemberAddedTitle(String name) {
    return '$name a été ajouté(e)';
  }

  @override
  String get addMemberNoNamesYet => 'Sans nom attribué pour le moment.';

  @override
  String addMemberWithNames(String names) {
    return 'Avec $names.';
  }

  @override
  String get addMemberShareCode =>
      'Transmettez-lui ce code pour qu\'il ou elle rejoigne la tontine.';

  @override
  String get addMemberInviteCodeOverline => 'CODE D\'INVITATION';

  @override
  String addMemberInviteCodeSemantics(String code) {
    return 'Code d\'invitation $code';
  }

  @override
  String get addMemberCopyCode => 'Copier le code';

  @override
  String get commonDone => 'Terminé';

  @override
  String get profileContactUpdated => 'Coordonnées mises à jour.';

  @override
  String profileDeactivateTitle(String name) {
    return 'Désactiver $name ?';
  }

  @override
  String get profileDeactivateMessage =>
      'Ce membre n\'apparaîtra plus dans les membres actifs. Vous pourrez le réactiver à tout moment.';

  @override
  String get profileDeactivate => 'Désactiver';

  @override
  String profileDeactivated(String name) {
    return '$name a été désactivé(e).';
  }

  @override
  String profileReactivated(String name) {
    return '$name a été réactivé(e).';
  }

  @override
  String profileNamesAssigned(String names, String name) {
    return '$names attribué(s) à $name.';
  }

  @override
  String get profileLoadError => 'Impossible de charger ce membre.';

  @override
  String get profileNotFound => 'Ce membre est introuvable.';

  @override
  String get profileEditContact => 'Modifier les coordonnées';

  @override
  String get commonSave => 'Enregistrer';

  @override
  String get contactWhatsApp => 'WhatsApp';

  @override
  String get profileNamesHeld => 'Noms détenus';

  @override
  String get profileNoNamesYet => 'Aucun nom attribué pour le moment.';

  @override
  String get profileDeactivateMember => 'Désactiver ce membre';

  @override
  String get profileReactivateMember => 'Réactiver ce membre';

  @override
  String get profileInviteCodeUsed => 'Code d\'invitation (utilisé)';

  @override
  String get profileInviteCode => 'Code d\'invitation';

  @override
  String get profileRegistered => 'Inscrit';

  @override
  String profileShareCodeWith(String name) {
    return 'À transmettre à $name pour qu\'il ou elle rejoigne la tontine.';
  }

  @override
  String get profileDuePerDueDate => 'DÛ PAR ÉCHÉANCE';

  @override
  String profileNamesHeldCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count noms détenus',
      one: '1 nom détenu',
    );
    return '$_temp0';
  }

  @override
  String get statusDeactivated => 'Désactivé';

  @override
  String get statusAwaitingSignup => 'En attente d\'inscription';

  @override
  String get statusActive => 'Actif';

  @override
  String get profileAssignNamesTitle => 'Attribuer des noms';

  @override
  String profileAssignNamesQuestion(String name) {
    return 'Combien de noms supplémentaires pour $name ?';
  }

  @override
  String get memberFormContactRequired =>
      'Indiquez au moins un email ou un numéro WhatsApp.';

  @override
  String get memberFormFullName => 'Nom complet';

  @override
  String get memberFormNameTooShort =>
      'Le nom doit contenir au moins 2 caractères.';

  @override
  String get memberFormWhatsApp => 'Numéro WhatsApp';

  @override
  String get memberFormEmail => 'Email';

  @override
  String get memberFormOneContactRequired =>
      'Au moins un des deux moyens de contact est requis.';

  @override
  String get memberFormHalfNamesHelp =>
      'Un nom peut être partagé en demies entre deux membres ; le nom entier lui appartient exclusivement.';

  @override
  String errorNamesQuotaExceeded(int total) {
    return 'Cette attribution dépasserait le nombre de noms prévu pour la tontine ($total).';
  }

  @override
  String defaultNameLabel(int position) {
    return 'Nom $position';
  }

  @override
  String get assignSharesMustTotal100 =>
      'La somme des parts doit être égale à 100 %.';

  @override
  String get assignSharesSaved => 'Parts enregistrées.';

  @override
  String get assignLoadNamesError => 'Impossible de charger les noms.';

  @override
  String get assignNameNotFound => 'Ce nom est introuvable.';

  @override
  String get assignNewName => 'Nouveau nom';

  @override
  String get assignEditShares => 'Modifier les parts';

  @override
  String get assignAddActiveMembersFirst =>
      'Ajoutez d\'abord des membres actifs pour pouvoir leur attribuer ce nom.';

  @override
  String get assignFrozen =>
      'Figé — l\'échéancier a déjà démarré. Modifier ces parts fausserait les montants dus déjà calculés.';

  @override
  String get partsHolders => 'Détenteurs de part';

  @override
  String get partsSplitEqually => 'Répartir également';

  @override
  String partsTotal(int percent) {
    return 'Total : $percent %';
  }

  @override
  String scheduleTabUpcoming(int count) {
    return 'À venir ($count)';
  }

  @override
  String scheduleTabHistory(int count) {
    return 'Historique ($count)';
  }

  @override
  String get scheduleLoadError => 'Impossible de charger l\'échéancier.';

  @override
  String get scheduleNoCalendarYet => 'Pas encore de calendrier';

  @override
  String get scheduleDragHint =>
      'Maintenez et faites glisser pour changer l\'ordre.';

  @override
  String get scheduleNoTurnPaid =>
      'Aucun tour remis pour le moment. Les tours apparaîtront ici une fois la cagnotte remise.';

  @override
  String get reorderReasonRequired => 'Indiquez la raison de ce changement.';

  @override
  String get reorderTitle => 'Déplacer ce tour';

  @override
  String get reorderExplanation =>
      'Les dates des tours suivants seront recalculées. Expliquez pourquoi l\'ordre change.';

  @override
  String get reorderHint => 'Ex. absence exceptionnelle, demande du membre…';

  @override
  String get commonConfirm => 'Confirmer';

  @override
  String get turnStatusUpcoming => 'À venir';

  @override
  String get turnStatusInProgress => 'En cours';

  @override
  String get turnStatusPaid => 'Remis';

  @override
  String get turnStatusPostponed => 'Reporté';

  @override
  String get turnHistoryTitle => 'Historique du tour';

  @override
  String turnPositionChange(int from, int to) {
    return 'Position $from → $to';
  }

  @override
  String turnPaidOn(String date) {
    return 'Remis le $date';
  }

  @override
  String turnPlannedOn(String date) {
    return 'Prévu le $date';
  }

  @override
  String turnChangesSeeHistory(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count changements — voir l\'historique',
      one: 'Repositionné — voir l\'historique',
    );
    return '$_temp0';
  }

  @override
  String turnsPaidOf(int total) {
    return ' / $total tours remis';
  }

  @override
  String get collectLoadError => 'Impossible de charger la collecte.';

  @override
  String get collectTurnNotFound => 'Ce tour est introuvable.';

  @override
  String collectRecorded(String name) {
    return 'Cotisation de $name enregistrée.';
  }

  @override
  String collectTitleAdmin(int position) {
    return 'Collecte — Tour $position';
  }

  @override
  String collectTitleMember(int position) {
    return 'Tour $position — Contributions';
  }

  @override
  String collectTabToCollect(int count) {
    return 'À collecter ($count)';
  }

  @override
  String collectTabSettled(int count) {
    return 'Réglé ($count)';
  }

  @override
  String get collectNoHolders => 'Aucun détenteur de part pour ce tour.';

  @override
  String get collectEveryonePaid => 'Tout le monde a réglé ce tour.';

  @override
  String get collectNoPaymentsYet =>
      'Aucun règlement enregistré pour le moment.';

  @override
  String collectDueOverline(String date) {
    return 'ÉCHÉANCE · $date';
  }

  @override
  String get collectComplete => 'Collecte complète';

  @override
  String collectPeopleLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count personnes à encaisser',
      one: '1 personne à encaisser',
    );
    return '$_temp0';
  }

  @override
  String get statusUnpaid => 'Impayé';

  @override
  String collectRemainingOf(String amount) {
    return 'reste sur $amount';
  }

  @override
  String get contribInvalidAmount => 'Indiquez un montant versé valide.';

  @override
  String get contribAmountExceedsDue =>
      'Le montant versé ne peut pas dépasser le montant dû.';

  @override
  String get contribMarkedOnTimeReason =>
      'Marqué comme à temps par l’administratrice.';

  @override
  String contribAmountDue(String amount) {
    return 'Montant dû : $amount';
  }

  @override
  String get contribAmountPaid => 'Montant versé';

  @override
  String get contribPaymentDate => 'Date du paiement';

  @override
  String get contribIsLate => 'Ce paiement est-il en retard ?';

  @override
  String get contribOnTime => 'À temps';

  @override
  String get contribPenaltyWaived => 'Pénalité levée';

  @override
  String get contribPenaltyComputed => 'Pénalité calculée';

  @override
  String get contribCancelWaiver => 'Annuler la levée';

  @override
  String get contribWaivePenalty => 'Lever la pénalité';

  @override
  String get contribSubmit => 'Enregistrer la cotisation';

  @override
  String get declValidated => 'Déclaration validée.';

  @override
  String get declRejected => 'Déclaration refusée.';

  @override
  String get declTitle => 'Déclaration';

  @override
  String get declLoadError => 'Impossible de charger cette déclaration.';

  @override
  String get declNotFound => 'Cette déclaration est introuvable.';

  @override
  String turnLabel(int position) {
    return 'Tour $position';
  }

  @override
  String get declAmountDeclared => 'Montant déclaré';

  @override
  String declPaidOn(String date) {
    return 'Payé le $date';
  }

  @override
  String declRejectionReason(String reason) {
    return 'Motif du refus : $reason';
  }

  @override
  String get declProofOfPayment => 'Preuve de paiement';

  @override
  String get declApprove => 'Valider la déclaration';

  @override
  String get declReject => 'Refuser';

  @override
  String get declNewDeclaration => 'Faire une nouvelle déclaration';

  @override
  String get declStatusPending => 'En attente';

  @override
  String get declStatusApproved => 'Validée';

  @override
  String get declStatusDisputed => 'Contestée';

  @override
  String get declProofLoadError => 'Impossible de charger la preuve.';

  @override
  String get declNoProof => 'Aucune preuve disponible.';

  @override
  String get declEnlargeProof => 'Agrandir la preuve';

  @override
  String get declRejectReasonRequired => 'Indiquez la raison du refus.';

  @override
  String get declRejectTitle => 'Refuser cette déclaration';

  @override
  String get declRejectHint => 'Ex. preuve illisible, montant incorrect…';

  @override
  String get declListLoadError => 'Impossible de charger les déclarations.';

  @override
  String get declNone => 'Aucune déclaration';

  @override
  String get declNoneMessage =>
      'Quand un membre signale avoir payé, sa déclaration et sa preuve apparaissent ici.';

  @override
  String get unknownTurn => 'Tour inconnu';

  @override
  String declGroupTitle(int position, String beneficiaries) {
    return 'Tour $position — $beneficiaries';
  }

  @override
  String declPendingOf(int pending, int total) {
    return '$pending en attente sur $total';
  }

  @override
  String declCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count déclarations',
      one: '1 déclaration',
    );
    return '$_temp0';
  }

  @override
  String get waiverReasonRequired => 'Indiquez la raison de cette exception.';

  @override
  String get waiverExplanation =>
      'La pénalité de retard calculée ne sera pas appliquée à cette cotisation. Expliquez pourquoi.';

  @override
  String get waiverHint => 'Ex. panne réseau signalée à l’avance';

  @override
  String get proofImageError => 'Impossible de récupérer l\'image. Réessayez.';

  @override
  String get proofTakePhoto => 'Prendre une photo';

  @override
  String get proofChooseFromGallery => 'Choisir dans la galerie';

  @override
  String get proofRequired => 'Preuve (obligatoire)';

  @override
  String get proofOptional => 'Preuve (optionnelle)';

  @override
  String get proofRemove => 'Retirer la preuve';

  @override
  String get proofCompressing => 'Compression en cours…';

  @override
  String get proofAdd => 'Ajouter une preuve';

  @override
  String get memberSpaceTitle => 'Mon espace';

  @override
  String get memberSpaceLoadError => 'Impossible de charger votre espace.';

  @override
  String get memberSpaceNoMember => 'Aucune fiche membre associée à ce compte.';

  @override
  String get memberSpaceScheduleNotGenerated =>
      'L\'échéancier n\'a pas encore été généré par l\'administratrice.';

  @override
  String get memberSpaceAllTurnsPaid => 'Tous les tours ont été remis.';

  @override
  String get memberSpaceToPayThisTurn => 'À régler pour ce tour';

  @override
  String get memberSpaceMyDeclarations => 'Mes déclarations';

  @override
  String memberSpaceDeclaredOn(String date) {
    return 'Déclaré le $date';
  }

  @override
  String get memberSpaceContributionHistory => 'Historique des cotisations';

  @override
  String get declareInvalidAmount => 'Indiquez un montant valide.';

  @override
  String get declareAmountExceedsRemaining =>
      'Le montant ne peut pas dépasser le reste à devoir.';

  @override
  String get declareProofRequired =>
      'Une preuve est obligatoire pour déclarer un paiement.';

  @override
  String get declareSent =>
      'Déclaration envoyée. En attente de validation par l\'administratrice.';

  @override
  String get declareTitle => 'J\'ai payé';

  @override
  String get declareNotAllowed =>
      'Ce nom ne peut plus être déclaré pour le tour en cours.';

  @override
  String declareRemaining(String amount) {
    return 'Reste à devoir : $amount';
  }

  @override
  String get declareSubmit => 'Envoyer la déclaration';

  @override
  String get myNamesNoCurrentTurn => 'Aucun tour en cours pour vos noms.';

  @override
  String get myNamesDeclarationPending => 'Déclaration en attente';

  @override
  String get myNamesDeclarationDisputed => 'Déclaration contestée';

  @override
  String myNamesShare(String fraction) {
    return 'Part : $fraction';
  }

  @override
  String get situationNoUpcomingTurn => 'Aucun tour à venir pour vos noms.';

  @override
  String get situationYourNextTurn => 'Votre prochain tour';

  @override
  String situationTurnLine(String name, int position, String relative) {
    return '$name · tour $position · $relative';
  }

  @override
  String get onboarding1Title => 'Votre tontine,\nsans cahier ni calculs';

  @override
  String onboarding1Text(String appName) {
    return 'Membres, noms, parts et ordre des tours : tout le cercle est réglé une fois, puis $appName tient le calendrier pour vous.';
  }

  @override
  String get onboarding2Title => 'Chaque franc,\nsuivi en direct';

  @override
  String get onboarding2Text =>
      'Voyez qui a payé, qui est en retard et combien il reste à collecter pour le tour en cours. Les pénalités se calculent toutes seules.';

  @override
  String get onboarding3Title => 'Les membres déclarent,\nvous validez';

  @override
  String get onboarding3Text =>
      'Chaque membre signale son paiement avec une preuve, depuis son téléphone. L\'administratrice vérifie et valide en un geste.';

  @override
  String get onboardingSkip => 'Passer';

  @override
  String get onboardingStart => 'Commencer';

  @override
  String get onboardingHaveCode => 'J\'ai reçu un code d\'invitation';

  @override
  String get onboardingCircleCaption => 'Tour 5 · Aïcha reçoit la cagnotte';

  @override
  String get onboardingCollectOverline => 'COLLECTE · TOUR 3';

  @override
  String get onboardingDeclaredPayment => 'a déclaré un paiement';

  @override
  String get onboardingMobileMoneyReceipt => 'Reçu Mobile Money joint';

  @override
  String get errorAlreadyMember => 'Vous faites déjà partie de ce groupe.';

  @override
  String get errorForbidden => 'Cette action est réservée au bureau du groupe.';

  @override
  String get errorDeclarationNotPending =>
      'Cette déclaration a déjà été traitée.';

  @override
  String get errorTurnAlreadyPaid =>
      'Un tour déjà remis ne peut pas être déplacé.';

  @override
  String get errorLastOwner =>
      'Le groupe doit garder au moins un propriétaire.';

  @override
  String get errorNamesQuotaReached =>
      'Tous les noms prévus pour la tontine sont déjà attribués.';

  @override
  String get errorServerNotConfigured =>
      'L\'application n\'est pas reliée à son serveur. Contactez le support.';

  @override
  String get errorEmailNotConfirmed =>
      'Confirmez d\'abord votre adresse : ouvrez le lien reçu par email.';

  @override
  String verifyBodyLink(String email) {
    return 'Un lien de confirmation a été envoyé à $email. Ouvrez-le depuis ce téléphone pour entrer directement dans l\'application, ou connectez-vous ensuite.';
  }

  @override
  String get verifyDoneSignIn => 'J\'ai confirmé, me connecter';

  @override
  String get roleOwner => 'Propriétaire';

  @override
  String get rolePresident => 'Président(e)';

  @override
  String get roleTreasurer => 'Trésorier(ère)';

  @override
  String get roleAuditor => 'Commissaire aux comptes';

  @override
  String get roleMember => 'Membre';

  @override
  String get groupsTitle => 'Mes groupes';

  @override
  String get groupsSubtitle => 'Touchez un groupe pour l\'afficher.';

  @override
  String get groupsCurrent => 'Affiché';

  @override
  String get groupsJoinWithCode => 'Rejoindre avec un code';

  @override
  String get groupsSwitch => 'Changer de groupe';

  @override
  String get settingsMyGroups => 'Mes groupes';

  @override
  String settingsMyGroupsSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count groupes · changer, créer ou rejoindre',
      one: '1 groupe · créer ou rejoindre un autre',
    );
    return '$_temp0';
  }

  @override
  String get loginContinueWithApple => 'Continuer avec Apple';

  @override
  String get newPasswordTitle => 'Choisissez un nouveau mot de passe';

  @override
  String get newPasswordSubmit => 'Enregistrer le mot de passe';

  @override
  String get newPasswordSaved => 'Mot de passe modifié.';
}
