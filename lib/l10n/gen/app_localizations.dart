import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('fr'),
    Locale('en'),
  ];

  /// No description provided for @relativeToday.
  ///
  /// In fr, this message translates to:
  /// **'aujourd\'hui'**
  String get relativeToday;

  /// No description provided for @relativeTomorrow.
  ///
  /// In fr, this message translates to:
  /// **'demain'**
  String get relativeTomorrow;

  /// No description provided for @relativeYesterday.
  ///
  /// In fr, this message translates to:
  /// **'hier'**
  String get relativeYesterday;

  /// No description provided for @relativeInDays.
  ///
  /// In fr, this message translates to:
  /// **'dans {days} jours'**
  String relativeInDays(int days);

  /// No description provided for @relativeDaysAgo.
  ///
  /// In fr, this message translates to:
  /// **'il y a {days} jours'**
  String relativeDaysAgo(int days);

  /// No description provided for @errorGeneric.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur est survenue. Réessayez.'**
  String get errorGeneric;

  /// No description provided for @errorNetwork.
  ///
  /// In fr, this message translates to:
  /// **'La connexion a expiré. Vérifiez votre connexion et réessayez.'**
  String get errorNetwork;

  /// No description provided for @errorInvalidCredentials.
  ///
  /// In fr, this message translates to:
  /// **'Email ou mot de passe incorrect.'**
  String get errorInvalidCredentials;

  /// No description provided for @errorEmailAlreadyInUse.
  ///
  /// In fr, this message translates to:
  /// **'Un compte existe déjà avec cet email.'**
  String get errorEmailAlreadyInUse;

  /// No description provided for @errorWeakPassword.
  ///
  /// In fr, this message translates to:
  /// **'Le mot de passe est trop faible (6 caractères minimum).'**
  String get errorWeakPassword;

  /// No description provided for @errorInvalidEmail.
  ///
  /// In fr, this message translates to:
  /// **'L\'adresse email est invalide.'**
  String get errorInvalidEmail;

  /// No description provided for @errorUserDisabled.
  ///
  /// In fr, this message translates to:
  /// **'Ce compte a été désactivé.'**
  String get errorUserDisabled;

  /// No description provided for @errorTooManyRequests.
  ///
  /// In fr, this message translates to:
  /// **'Trop de tentatives. Réessaie plus tard.'**
  String get errorTooManyRequests;

  /// No description provided for @errorSignInRequired.
  ///
  /// In fr, this message translates to:
  /// **'Connectez-vous pour continuer.'**
  String get errorSignInRequired;

  /// No description provided for @errorExternalSignIn.
  ///
  /// In fr, this message translates to:
  /// **'La connexion avec ce compte a échoué. Réessayez.'**
  String get errorExternalSignIn;

  /// No description provided for @errorAuthUnknown.
  ///
  /// In fr, this message translates to:
  /// **'Erreur d\'authentification. Réessayez.'**
  String get errorAuthUnknown;

  /// No description provided for @errorInvitationNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Ce code d\'invitation est introuvable.'**
  String get errorInvitationNotFound;

  /// No description provided for @errorInvitationAlreadyUsed.
  ///
  /// In fr, this message translates to:
  /// **'Cette invitation a déjà été utilisée.'**
  String get errorInvitationAlreadyUsed;

  /// No description provided for @commonCancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get commonCancel;

  /// No description provided for @commonRetry.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get commonRetry;

  /// No description provided for @commonBack.
  ///
  /// In fr, this message translates to:
  /// **'Retour'**
  String get commonBack;

  /// No description provided for @commonLoading.
  ///
  /// In fr, this message translates to:
  /// **'Chargement en cours'**
  String get commonLoading;

  /// No description provided for @commonComingSoon.
  ///
  /// In fr, this message translates to:
  /// **'Cette fonctionnalité arrive bientôt.'**
  String get commonComingSoon;

  /// No description provided for @amountFieldLabel.
  ///
  /// In fr, this message translates to:
  /// **'Montant de la cotisation'**
  String get amountFieldLabel;

  /// No description provided for @amountFieldHint.
  ///
  /// In fr, this message translates to:
  /// **'25 000 FCFA'**
  String get amountFieldHint;

  /// No description provided for @navHome.
  ///
  /// In fr, this message translates to:
  /// **'Accueil'**
  String get navHome;

  /// No description provided for @navMembers.
  ///
  /// In fr, this message translates to:
  /// **'Membres'**
  String get navMembers;

  /// No description provided for @navSchedule.
  ///
  /// In fr, this message translates to:
  /// **'Échéancier'**
  String get navSchedule;

  /// No description provided for @navDeclarations.
  ///
  /// In fr, this message translates to:
  /// **'Déclarations'**
  String get navDeclarations;

  /// No description provided for @navSettings.
  ///
  /// In fr, this message translates to:
  /// **'Réglages'**
  String get navSettings;

  /// No description provided for @statusPaid.
  ///
  /// In fr, this message translates to:
  /// **'Payé'**
  String get statusPaid;

  /// No description provided for @statusLate.
  ///
  /// In fr, this message translates to:
  /// **'En retard'**
  String get statusLate;

  /// No description provided for @statusPartial.
  ///
  /// In fr, this message translates to:
  /// **'Partiel'**
  String get statusPartial;

  /// No description provided for @statusException.
  ///
  /// In fr, this message translates to:
  /// **'Exception'**
  String get statusException;

  /// No description provided for @statusToCollect.
  ///
  /// In fr, this message translates to:
  /// **'À encaisser'**
  String get statusToCollect;

  /// No description provided for @memberCardRecordPayment.
  ///
  /// In fr, this message translates to:
  /// **'Noter un paiement'**
  String get memberCardRecordPayment;

  /// No description provided for @memberCardMoreOptions.
  ///
  /// In fr, this message translates to:
  /// **'Plus d’options'**
  String get memberCardMoreOptions;

  /// No description provided for @authEmailLabel.
  ///
  /// In fr, this message translates to:
  /// **'E-mail'**
  String get authEmailLabel;

  /// No description provided for @authPasswordLabel.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get authPasswordLabel;

  /// No description provided for @authConfirmPasswordLabel.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer le mot de passe'**
  String get authConfirmPasswordLabel;

  /// No description provided for @authTogglePasswordVisibility.
  ///
  /// In fr, this message translates to:
  /// **'Afficher ou masquer le mot de passe'**
  String get authTogglePasswordVisibility;

  /// No description provided for @authPasswordsDoNotMatch.
  ///
  /// In fr, this message translates to:
  /// **'Les mots de passe ne correspondent pas.'**
  String get authPasswordsDoNotMatch;

  /// No description provided for @authInvalidEmail.
  ///
  /// In fr, this message translates to:
  /// **'Saisissez une adresse e-mail valide.'**
  String get authInvalidEmail;

  /// No description provided for @authPasswordTooShort.
  ///
  /// In fr, this message translates to:
  /// **'Le mot de passe doit contenir au moins 6 caractères.'**
  String get authPasswordTooShort;

  /// No description provided for @authTagline.
  ///
  /// In fr, this message translates to:
  /// **'Le registre de votre tontine, toujours à jour'**
  String get authTagline;

  /// No description provided for @loginEnterEmailForReset.
  ///
  /// In fr, this message translates to:
  /// **'Saisissez votre e-mail pour recevoir le lien de réinitialisation.'**
  String get loginEnterEmailForReset;

  /// No description provided for @loginResetLinkSent.
  ///
  /// In fr, this message translates to:
  /// **'Un lien de réinitialisation a été envoyé à votre adresse e-mail.'**
  String get loginResetLinkSent;

  /// No description provided for @loginSubmit.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get loginSubmit;

  /// No description provided for @loginForgotPassword.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe oublié ?'**
  String get loginForgotPassword;

  /// No description provided for @commonOr.
  ///
  /// In fr, this message translates to:
  /// **'ou'**
  String get commonOr;

  /// No description provided for @loginContinueWithGoogle.
  ///
  /// In fr, this message translates to:
  /// **'Continuer avec Google'**
  String get loginContinueWithGoogle;

  /// No description provided for @loginCreateAccount.
  ///
  /// In fr, this message translates to:
  /// **'Créer un compte'**
  String get loginCreateAccount;

  /// No description provided for @signupTitle.
  ///
  /// In fr, this message translates to:
  /// **'Créer un compte'**
  String get signupTitle;

  /// No description provided for @signupSubmit.
  ///
  /// In fr, this message translates to:
  /// **'Créer mon compte'**
  String get signupSubmit;

  /// No description provided for @signupHaveAccount.
  ///
  /// In fr, this message translates to:
  /// **'J’ai déjà un compte'**
  String get signupHaveAccount;

  /// No description provided for @welcomeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue sur {appName}'**
  String welcomeTitle(String appName);

  /// No description provided for @welcomeSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Comment souhaitez-vous commencer ?'**
  String get welcomeSubtitle;

  /// No description provided for @welcomeCreateTitle.
  ///
  /// In fr, this message translates to:
  /// **'Créer une tontine'**
  String get welcomeCreateTitle;

  /// No description provided for @welcomeCreateDescription.
  ///
  /// In fr, this message translates to:
  /// **'Démarrez un nouveau groupe, invitez vos membres et suivez les cotisations dès aujourd\'hui.'**
  String get welcomeCreateDescription;

  /// No description provided for @welcomeJoinTitle.
  ///
  /// In fr, this message translates to:
  /// **'Rejoindre une tontine'**
  String get welcomeJoinTitle;

  /// No description provided for @welcomeJoinDescription.
  ///
  /// In fr, this message translates to:
  /// **'Vous avez reçu un code de votre trésorier ? Rejoignez son groupe en quelques secondes.'**
  String get welcomeJoinDescription;

  /// No description provided for @commonSignOut.
  ///
  /// In fr, this message translates to:
  /// **'Se déconnecter'**
  String get commonSignOut;

  /// No description provided for @joinEnterSixChars.
  ///
  /// In fr, this message translates to:
  /// **'Saisissez les 6 caractères du code d’invitation.'**
  String get joinEnterSixChars;

  /// No description provided for @joinSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Vous avez rejoint la tontine.'**
  String get joinSuccess;

  /// No description provided for @joinTitle.
  ///
  /// In fr, this message translates to:
  /// **'Entrez votre code d’invitation'**
  String get joinTitle;

  /// No description provided for @joinSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Six caractères, remis par la trésorière du groupe.'**
  String get joinSubtitle;

  /// No description provided for @joinPasteHint.
  ///
  /// In fr, this message translates to:
  /// **'Vous pouvez coller le code'**
  String get joinPasteHint;

  /// No description provided for @joinSubmit.
  ///
  /// In fr, this message translates to:
  /// **'Rejoindre'**
  String get joinSubmit;

  /// No description provided for @joinSearching.
  ///
  /// In fr, this message translates to:
  /// **'Recherche de la tontine…'**
  String get joinSearching;

  /// No description provided for @joinMembersCount.
  ///
  /// In fr, this message translates to:
  /// **' · {count, plural, =0{aucun membre} =1{1 membre} other{{count} membres}}'**
  String joinMembersCount(int count);

  /// No description provided for @verifyEmailResent.
  ///
  /// In fr, this message translates to:
  /// **'Email de vérification renvoyé.'**
  String get verifyEmailResent;

  /// No description provided for @verifyYourAddressFallback.
  ///
  /// In fr, this message translates to:
  /// **'votre adresse'**
  String get verifyYourAddressFallback;

  /// No description provided for @verifyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Vérifiez votre adresse email'**
  String get verifyTitle;

  /// No description provided for @verifyResendIn.
  ///
  /// In fr, this message translates to:
  /// **'Renvoyer l\'email ({seconds} s)'**
  String verifyResendIn(int seconds);

  /// No description provided for @verifyResend.
  ///
  /// In fr, this message translates to:
  /// **'Renvoyer l\'email'**
  String get verifyResend;

  /// No description provided for @weekdayMonday.
  ///
  /// In fr, this message translates to:
  /// **'Lundi'**
  String get weekdayMonday;

  /// No description provided for @weekdayTuesday.
  ///
  /// In fr, this message translates to:
  /// **'Mardi'**
  String get weekdayTuesday;

  /// No description provided for @weekdayWednesday.
  ///
  /// In fr, this message translates to:
  /// **'Mercredi'**
  String get weekdayWednesday;

  /// No description provided for @weekdayThursday.
  ///
  /// In fr, this message translates to:
  /// **'Jeudi'**
  String get weekdayThursday;

  /// No description provided for @weekdayFriday.
  ///
  /// In fr, this message translates to:
  /// **'Vendredi'**
  String get weekdayFriday;

  /// No description provided for @weekdaySaturday.
  ///
  /// In fr, this message translates to:
  /// **'Samedi'**
  String get weekdaySaturday;

  /// No description provided for @weekdaySunday.
  ///
  /// In fr, this message translates to:
  /// **'Dimanche'**
  String get weekdaySunday;

  /// No description provided for @occurrenceFirst.
  ///
  /// In fr, this message translates to:
  /// **'Premier'**
  String get occurrenceFirst;

  /// No description provided for @occurrenceSecond.
  ///
  /// In fr, this message translates to:
  /// **'Deuxième'**
  String get occurrenceSecond;

  /// No description provided for @occurrenceThird.
  ///
  /// In fr, this message translates to:
  /// **'Troisième'**
  String get occurrenceThird;

  /// No description provided for @occurrenceFourth.
  ///
  /// In fr, this message translates to:
  /// **'Quatrième'**
  String get occurrenceFourth;

  /// No description provided for @occurrenceLast.
  ///
  /// In fr, this message translates to:
  /// **'Dernier'**
  String get occurrenceLast;

  /// No description provided for @sharesModeFixed.
  ///
  /// In fr, this message translates to:
  /// **'Montant fixe par part'**
  String get sharesModeFixed;

  /// No description provided for @sharesModeProportional.
  ///
  /// In fr, this message translates to:
  /// **'Répartition proportionnelle'**
  String get sharesModeProportional;

  /// No description provided for @sharesModeEqual.
  ///
  /// In fr, this message translates to:
  /// **'Parts égales'**
  String get sharesModeEqual;

  /// No description provided for @sharesModeFixedDescription.
  ///
  /// In fr, this message translates to:
  /// **'Chaque détenteur de part verse le même montant fixe, quelle que soit sa fraction.'**
  String get sharesModeFixedDescription;

  /// No description provided for @sharesModeProportionalDescription.
  ///
  /// In fr, this message translates to:
  /// **'Chaque détenteur verse un montant proportionnel à sa fraction du nom.'**
  String get sharesModeProportionalDescription;

  /// No description provided for @sharesModeEqualDescription.
  ///
  /// In fr, this message translates to:
  /// **'Le montant du nom est réparti à parts égales entre ses détenteurs.'**
  String get sharesModeEqualDescription;

  /// No description provided for @penaltyNone.
  ///
  /// In fr, this message translates to:
  /// **'Aucune pénalité'**
  String get penaltyNone;

  /// No description provided for @penaltyFlat.
  ///
  /// In fr, this message translates to:
  /// **'Pénalité forfaitaire (montant fixe)'**
  String get penaltyFlat;

  /// No description provided for @penaltyProportional.
  ///
  /// In fr, this message translates to:
  /// **'Pénalité proportionnelle (% du montant dû)'**
  String get penaltyProportional;

  /// No description provided for @periodEveryNDays.
  ///
  /// In fr, this message translates to:
  /// **'Tous les {days} jours'**
  String periodEveryNDays(int days);

  /// No description provided for @periodWeekly.
  ///
  /// In fr, this message translates to:
  /// **'Chaque {day}'**
  String periodWeekly(String day);

  /// No description provided for @periodBiweekly.
  ///
  /// In fr, this message translates to:
  /// **'Toutes les deux semaines, le {day}'**
  String periodBiweekly(String day);

  /// No description provided for @periodMonthlyDay.
  ///
  /// In fr, this message translates to:
  /// **'Chaque mois, le {day}'**
  String periodMonthlyDay(int day);

  /// No description provided for @periodMonthlyWeekday.
  ///
  /// In fr, this message translates to:
  /// **'{occurrence} {day} du mois'**
  String periodMonthlyWeekday(String occurrence, String day);

  /// No description provided for @periodTypeEveryNDays.
  ///
  /// In fr, this message translates to:
  /// **'Tous les N jours'**
  String get periodTypeEveryNDays;

  /// No description provided for @periodTypeWeekly.
  ///
  /// In fr, this message translates to:
  /// **'Chaque semaine'**
  String get periodTypeWeekly;

  /// No description provided for @periodTypeBiweekly.
  ///
  /// In fr, this message translates to:
  /// **'Toutes les deux semaines'**
  String get periodTypeBiweekly;

  /// No description provided for @periodTypeMonthlyDay.
  ///
  /// In fr, this message translates to:
  /// **'Chaque mois, jour fixe'**
  String get periodTypeMonthlyDay;

  /// No description provided for @periodTypeMonthlyWeekday.
  ///
  /// In fr, this message translates to:
  /// **'Chaque mois, Nième jour de semaine'**
  String get periodTypeMonthlyWeekday;

  /// No description provided for @fieldFrequency.
  ///
  /// In fr, this message translates to:
  /// **'Fréquence'**
  String get fieldFrequency;

  /// No description provided for @fieldDaysBetweenDueDates.
  ///
  /// In fr, this message translates to:
  /// **'Nombre de jours entre deux échéances'**
  String get fieldDaysBetweenDueDates;

  /// No description provided for @fieldDayOfMonth.
  ///
  /// In fr, this message translates to:
  /// **'Jour du mois (1 à 31)'**
  String get fieldDayOfMonth;

  /// No description provided for @fieldWeekday.
  ///
  /// In fr, this message translates to:
  /// **'Jour de la semaine'**
  String get fieldWeekday;

  /// No description provided for @fieldOccurrenceInMonth.
  ///
  /// In fr, this message translates to:
  /// **'Occurrence dans le mois'**
  String get fieldOccurrenceInMonth;

  /// No description provided for @fieldPenaltyRule.
  ///
  /// In fr, this message translates to:
  /// **'Règle de pénalité'**
  String get fieldPenaltyRule;

  /// No description provided for @fieldPenaltyAmount.
  ///
  /// In fr, this message translates to:
  /// **'Montant de la pénalité (FCFA)'**
  String get fieldPenaltyAmount;

  /// No description provided for @fieldPenaltyPercent.
  ///
  /// In fr, this message translates to:
  /// **'Pourcentage de pénalité (%)'**
  String get fieldPenaltyPercent;

  /// No description provided for @fieldGraceDays.
  ///
  /// In fr, this message translates to:
  /// **'Délai de grâce (jours, 0 à 30)'**
  String get fieldGraceDays;

  /// No description provided for @createStepGroup.
  ///
  /// In fr, this message translates to:
  /// **'Le groupe'**
  String get createStepGroup;

  /// No description provided for @createStepFrequency.
  ///
  /// In fr, this message translates to:
  /// **'Fréquence des échéances'**
  String get createStepFrequency;

  /// No description provided for @createStepPenalty.
  ///
  /// In fr, this message translates to:
  /// **'Pénalité et délai de grâce'**
  String get createStepPenalty;

  /// No description provided for @createStepShares.
  ///
  /// In fr, this message translates to:
  /// **'Répartition des parts'**
  String get createStepShares;

  /// No description provided for @createStepConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Confirmation'**
  String get createStepConfirm;

  /// No description provided for @createErrorGroupName.
  ///
  /// In fr, this message translates to:
  /// **'Le nom du groupe doit contenir au moins 2 caractères.'**
  String get createErrorGroupName;

  /// No description provided for @createErrorFullName.
  ///
  /// In fr, this message translates to:
  /// **'Indiquez votre nom complet.'**
  String get createErrorFullName;

  /// No description provided for @createErrorAmount.
  ///
  /// In fr, this message translates to:
  /// **'Indiquez un montant par nom valide.'**
  String get createErrorAmount;

  /// No description provided for @createErrorNamesCount.
  ///
  /// In fr, this message translates to:
  /// **'Indiquez le nombre de noms que comptera la tontine.'**
  String get createErrorNamesCount;

  /// No description provided for @createErrorFirstDueDate.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez la date de la première échéance.'**
  String get createErrorFirstDueDate;

  /// No description provided for @createErrorPenaltyValue.
  ///
  /// In fr, this message translates to:
  /// **'Indiquez une valeur de pénalité supérieure à zéro.'**
  String get createErrorPenaltyValue;

  /// No description provided for @createErrorGraceDays.
  ///
  /// In fr, this message translates to:
  /// **'Le délai de grâce doit être compris entre 0 et 30 jours.'**
  String get createErrorGraceDays;

  /// No description provided for @createSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Tontine créée avec succès. Ajoutez vos premiers membres.'**
  String get createSuccess;

  /// No description provided for @createPreviousStep.
  ///
  /// In fr, this message translates to:
  /// **'Étape précédente'**
  String get createPreviousStep;

  /// No description provided for @createTitle.
  ///
  /// In fr, this message translates to:
  /// **'Créer une tontine'**
  String get createTitle;

  /// No description provided for @createStepOf.
  ///
  /// In fr, this message translates to:
  /// **'Étape {step} sur {total}'**
  String createStepOf(int step, int total);

  /// No description provided for @createSubmit.
  ///
  /// In fr, this message translates to:
  /// **'Créer la tontine'**
  String get createSubmit;

  /// No description provided for @commonNext.
  ///
  /// In fr, this message translates to:
  /// **'Suivant'**
  String get commonNext;

  /// No description provided for @fieldGroupName.
  ///
  /// In fr, this message translates to:
  /// **'Nom du groupe'**
  String get fieldGroupName;

  /// No description provided for @fieldGroupNameHint.
  ///
  /// In fr, this message translates to:
  /// **'Tontine des Dames'**
  String get fieldGroupNameHint;

  /// No description provided for @fieldYourFullName.
  ///
  /// In fr, this message translates to:
  /// **'Votre nom complet'**
  String get fieldYourFullName;

  /// No description provided for @fieldFullNameHint.
  ///
  /// In fr, this message translates to:
  /// **'Adèle Tchoumi'**
  String get fieldFullNameHint;

  /// No description provided for @fieldAmountPerName.
  ///
  /// In fr, this message translates to:
  /// **'Montant par nom'**
  String get fieldAmountPerName;

  /// No description provided for @fieldAmountHint.
  ///
  /// In fr, this message translates to:
  /// **'25 000'**
  String get fieldAmountHint;

  /// No description provided for @fieldNamesCount.
  ///
  /// In fr, this message translates to:
  /// **'Nombre de noms'**
  String get fieldNamesCount;

  /// No description provided for @fieldNamesCountHelp.
  ///
  /// In fr, this message translates to:
  /// **'Combien de noms (parts) comptera la tontine au total ? Vous les attribuerez aux membres au fil des inscriptions.'**
  String get fieldNamesCountHelp;

  /// No description provided for @fieldFirstDueDate.
  ///
  /// In fr, this message translates to:
  /// **'Date de la première échéance'**
  String get fieldFirstDueDate;

  /// No description provided for @fieldChooseDate.
  ///
  /// In fr, this message translates to:
  /// **'Choisir une date'**
  String get fieldChooseDate;

  /// No description provided for @recapGroup.
  ///
  /// In fr, this message translates to:
  /// **'Groupe'**
  String get recapGroup;

  /// No description provided for @recapAdmin.
  ///
  /// In fr, this message translates to:
  /// **'Administratrice'**
  String get recapAdmin;

  /// No description provided for @recapFirstDueDate.
  ///
  /// In fr, this message translates to:
  /// **'Première échéance'**
  String get recapFirstDueDate;

  /// No description provided for @recapPenalty.
  ///
  /// In fr, this message translates to:
  /// **'Pénalité'**
  String get recapPenalty;

  /// No description provided for @recapPenaltyValue.
  ///
  /// In fr, this message translates to:
  /// **'Valeur de la pénalité'**
  String get recapPenaltyValue;

  /// No description provided for @recapGraceDays.
  ///
  /// In fr, this message translates to:
  /// **'Délai de grâce'**
  String get recapGraceDays;

  /// No description provided for @recapGraceDaysValue.
  ///
  /// In fr, this message translates to:
  /// **'{days, plural, =0{0 jour} =1{1 jour} other{{days} jours}}'**
  String recapGraceDaysValue(int days);

  /// No description provided for @editErrorNamesBelowExisting.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 nom existe déjà : le nombre de noms ne peut pas être réduit en dessous de ce total.} other{{count} noms existent déjà : le nombre de noms ne peut pas être réduit en dessous de ce total.}}'**
  String editErrorNamesBelowExisting(int count);

  /// No description provided for @editSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Tontine mise à jour.'**
  String get editSuccess;

  /// No description provided for @editTitleAdmin.
  ///
  /// In fr, this message translates to:
  /// **'Modifier la tontine'**
  String get editTitleAdmin;

  /// No description provided for @editTitleMember.
  ///
  /// In fr, this message translates to:
  /// **'Réglages de la tontine'**
  String get editTitleMember;

  /// No description provided for @errorLoadTontine.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger la tontine.'**
  String get errorLoadTontine;

  /// No description provided for @errorNoTontine.
  ///
  /// In fr, this message translates to:
  /// **'Aucune tontine associée à ce compte.'**
  String get errorNoTontine;

  /// No description provided for @editSave.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer les modifications'**
  String get editSave;

  /// No description provided for @editFrozenStarted.
  ///
  /// In fr, this message translates to:
  /// **'Figée — l\'échéancier a démarré'**
  String get editFrozenStarted;

  /// No description provided for @editReadOnlyAdminOnly.
  ///
  /// In fr, this message translates to:
  /// **'Lecture seule — réservé à l\'administratrice'**
  String get editReadOnlyAdminOnly;

  /// No description provided for @editFrozenExplanation.
  ///
  /// In fr, this message translates to:
  /// **'Toute modification invaliderait les montants dus et les tours déjà calculés. Ces informations ne peuvent plus changer une fois la collecte commencée.'**
  String get editFrozenExplanation;

  /// No description provided for @editAdminOnlyExplanation.
  ///
  /// In fr, this message translates to:
  /// **'Seule l\'administratrice de la tontine peut modifier ces informations.'**
  String get editAdminOnlyExplanation;

  /// No description provided for @homeAddMember.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un membre'**
  String get homeAddMember;

  /// No description provided for @homeLoading.
  ///
  /// In fr, this message translates to:
  /// **'Chargement de votre tontine…'**
  String get homeLoading;

  /// No description provided for @homeLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger votre tontine.'**
  String get homeLoadError;

  /// No description provided for @homeHello.
  ///
  /// In fr, this message translates to:
  /// **'Bonjour'**
  String get homeHello;

  /// No description provided for @homeHelloName.
  ///
  /// In fr, this message translates to:
  /// **'Bonjour, {name}'**
  String homeHelloName(String name);

  /// No description provided for @homeSubtitlePending.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Voici le résumé de votre tontine.} =1{Un paiement attend votre validation.} other{{count} paiements attendent votre validation.}}'**
  String homeSubtitlePending(int count);

  /// No description provided for @homeSubtitleMember.
  ///
  /// In fr, this message translates to:
  /// **'Voici le résumé de votre tontine.'**
  String get homeSubtitleMember;

  /// No description provided for @homeAtAGlance.
  ///
  /// In fr, this message translates to:
  /// **'En un coup d\'œil'**
  String get homeAtAGlance;

  /// No description provided for @commonSeeAll.
  ///
  /// In fr, this message translates to:
  /// **'Voir tout'**
  String get commonSeeAll;

  /// No description provided for @homeNoActiveMembers.
  ///
  /// In fr, this message translates to:
  /// **'Aucun membre actif pour le moment'**
  String get homeNoActiveMembers;

  /// No description provided for @homeActiveMembers.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 membre actif} other{{count} membres actifs}}'**
  String homeActiveMembers(int count);

  /// No description provided for @unknownName.
  ///
  /// In fr, this message translates to:
  /// **'Nom inconnu'**
  String get unknownName;

  /// No description provided for @tourScheduleToPrepare.
  ///
  /// In fr, this message translates to:
  /// **'Échéancier à préparer'**
  String get tourScheduleToPrepare;

  /// No description provided for @tourScheduleToPrepareMessage.
  ///
  /// In fr, this message translates to:
  /// **'L\'échéancier n\'a pas encore été généré. Attribuez les noms puis générez-le depuis Membres.'**
  String get tourScheduleToPrepareMessage;

  /// No description provided for @tourGoToMembers.
  ///
  /// In fr, this message translates to:
  /// **'Aller aux membres'**
  String get tourGoToMembers;

  /// No description provided for @tourTontineFinished.
  ///
  /// In fr, this message translates to:
  /// **'Tontine terminée'**
  String get tourTontineFinished;

  /// No description provided for @tourTontineFinishedMessage.
  ///
  /// In fr, this message translates to:
  /// **'Tous les tours ont été remis. Bravo !'**
  String get tourTontineFinishedMessage;

  /// No description provided for @tourCurrentOverline.
  ///
  /// In fr, this message translates to:
  /// **'TOUR {position} · EN COURS'**
  String tourCurrentOverline(int position);

  /// No description provided for @tourReceives.
  ///
  /// In fr, this message translates to:
  /// **'Reçoit {amount} · {date} ({relative})'**
  String tourReceives(String amount, String date, String relative);

  /// No description provided for @tourCollectedOf.
  ///
  /// In fr, this message translates to:
  /// **'collectés sur {amount}'**
  String tourCollectedOf(String amount);

  /// No description provided for @tourSeeCollection.
  ///
  /// In fr, this message translates to:
  /// **'Voir la collecte'**
  String get tourSeeCollection;

  /// No description provided for @tourCollect.
  ///
  /// In fr, this message translates to:
  /// **'Collecter les cotisations'**
  String get tourCollect;

  /// No description provided for @percentValue.
  ///
  /// In fr, this message translates to:
  /// **'{value} %'**
  String percentValue(int value);

  /// No description provided for @statsActiveMembers.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Membre actif} =1{Membre actif} other{Membres actifs}}'**
  String statsActiveMembers(int count);

  /// No description provided for @statsNamesAssigned.
  ///
  /// In fr, this message translates to:
  /// **'Noms attribués'**
  String get statsNamesAssigned;

  /// No description provided for @statsTurnsPaid.
  ///
  /// In fr, this message translates to:
  /// **'Tours remis'**
  String get statsTurnsPaid;

  /// No description provided for @statsOnTimeLate.
  ///
  /// In fr, this message translates to:
  /// **'À temps / en retard'**
  String get statsOnTimeLate;

  /// No description provided for @bannerPendingDeclarations.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 déclaration de paiement à traiter} other{{count} déclarations de paiement à traiter}}'**
  String bannerPendingDeclarations(int count);

  /// No description provided for @bannerCheckProofs.
  ///
  /// In fr, this message translates to:
  /// **'Vérifiez les preuves pour valider les paiements.'**
  String get bannerCheckProofs;

  /// No description provided for @settingsSignOutTitle.
  ///
  /// In fr, this message translates to:
  /// **'Se déconnecter ?'**
  String get settingsSignOutTitle;

  /// No description provided for @settingsSignOutMessage.
  ///
  /// In fr, this message translates to:
  /// **'Vous devrez vous reconnecter pour accéder à votre tontine.'**
  String get settingsSignOutMessage;

  /// No description provided for @settingsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Réglages'**
  String get settingsTitle;

  /// No description provided for @settingsSectionGroup.
  ///
  /// In fr, this message translates to:
  /// **'Groupe'**
  String get settingsSectionGroup;

  /// No description provided for @settingsTontineSettings.
  ///
  /// In fr, this message translates to:
  /// **'Réglages de la tontine'**
  String get settingsTontineSettings;

  /// No description provided for @settingsTontineSettingsAdmin.
  ///
  /// In fr, this message translates to:
  /// **'Nom, montant, pénalité, nombre de noms'**
  String get settingsTontineSettingsAdmin;

  /// No description provided for @settingsTontineSettingsMember.
  ///
  /// In fr, this message translates to:
  /// **'Consulter (lecture seule)'**
  String get settingsTontineSettingsMember;

  /// No description provided for @settingsSectionAccount.
  ///
  /// In fr, this message translates to:
  /// **'Compte'**
  String get settingsSectionAccount;

  /// No description provided for @settingsMyProfile.
  ///
  /// In fr, this message translates to:
  /// **'Mon profil'**
  String get settingsMyProfile;

  /// No description provided for @settingsMyProfileAdmin.
  ///
  /// In fr, this message translates to:
  /// **'Vos coordonnées et votre code d\'invitation'**
  String get settingsMyProfileAdmin;

  /// No description provided for @settingsMyProfileMember.
  ///
  /// In fr, this message translates to:
  /// **'Vos noms, vos cotisations et vos déclarations'**
  String get settingsMyProfileMember;

  /// No description provided for @settingsSectionPreferences.
  ///
  /// In fr, this message translates to:
  /// **'Préférences'**
  String get settingsSectionPreferences;

  /// No description provided for @settingsLanguage.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageSystem.
  ///
  /// In fr, this message translates to:
  /// **'Langue du téléphone'**
  String get settingsLanguageSystem;

  /// No description provided for @languageFrench.
  ///
  /// In fr, this message translates to:
  /// **'Français'**
  String get languageFrench;

  /// No description provided for @languageEnglish.
  ///
  /// In fr, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @namesCountWhole.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{0 nom} =1{1 nom} other{{count} noms}}'**
  String namesCountWhole(int count);

  /// No description provided for @namesCountHalfOnly.
  ///
  /// In fr, this message translates to:
  /// **'½ nom'**
  String get namesCountHalfOnly;

  /// No description provided for @namesCountWithHalf.
  ///
  /// In fr, this message translates to:
  /// **'{count}½ noms'**
  String namesCountWithHalf(int count);

  /// No description provided for @namesRemoveHalf.
  ///
  /// In fr, this message translates to:
  /// **'Retirer une demie'**
  String get namesRemoveHalf;

  /// No description provided for @namesAddHalf.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une demie'**
  String get namesAddHalf;

  /// No description provided for @membersTitle.
  ///
  /// In fr, this message translates to:
  /// **'Membres'**
  String get membersTitle;

  /// No description provided for @membersTabNames.
  ///
  /// In fr, this message translates to:
  /// **'Noms ({count})'**
  String membersTabNames(int count);

  /// No description provided for @membersTabMembers.
  ///
  /// In fr, this message translates to:
  /// **'Membres ({count})'**
  String membersTabMembers(int count);

  /// No description provided for @commonAdd.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter'**
  String get commonAdd;

  /// No description provided for @membersLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les membres.'**
  String get membersLoadError;

  /// No description provided for @membersSectionNames.
  ///
  /// In fr, this message translates to:
  /// **'Noms'**
  String get membersSectionNames;

  /// No description provided for @membersAssign.
  ///
  /// In fr, this message translates to:
  /// **'Attribuer'**
  String get membersAssign;

  /// No description provided for @membersNoNamesYet.
  ///
  /// In fr, this message translates to:
  /// **'Aucun nom n\'a encore été créé. Attribuez le premier pour commencer.'**
  String get membersNoNamesYet;

  /// No description provided for @membersAssignName.
  ///
  /// In fr, this message translates to:
  /// **'Attribuer un nom'**
  String get membersAssignName;

  /// No description provided for @membersGenerateSchedule.
  ///
  /// In fr, this message translates to:
  /// **'Générer l\'échéancier'**
  String get membersGenerateSchedule;

  /// No description provided for @membersNamesLeftBeforeSchedule.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{Encore 1 nom à attribuer avant de pouvoir générer l\'échéancier.} other{Encore {count} noms à attribuer avant de pouvoir générer l\'échéancier.}}'**
  String membersNamesLeftBeforeSchedule(int count);

  /// No description provided for @membersActiveSection.
  ///
  /// In fr, this message translates to:
  /// **'Membres actifs ({count})'**
  String membersActiveSection(int count);

  /// No description provided for @membersNoActive.
  ///
  /// In fr, this message translates to:
  /// **'Aucun membre actif pour le moment.'**
  String get membersNoActive;

  /// No description provided for @membersInactiveSection.
  ///
  /// In fr, this message translates to:
  /// **'Membres désactivés ({count})'**
  String membersInactiveSection(int count);

  /// No description provided for @unknownMember.
  ///
  /// In fr, this message translates to:
  /// **'Membre inconnu'**
  String get unknownMember;

  /// No description provided for @membersNoHolder.
  ///
  /// In fr, this message translates to:
  /// **'Aucun détenteur'**
  String get membersNoHolder;

  /// No description provided for @membersToComplete.
  ///
  /// In fr, this message translates to:
  /// **'À compléter'**
  String get membersToComplete;

  /// No description provided for @membersNoContact.
  ///
  /// In fr, this message translates to:
  /// **'Aucun contact'**
  String get membersNoContact;

  /// No description provided for @membersPending.
  ///
  /// In fr, this message translates to:
  /// **'En attente'**
  String get membersPending;

  /// No description provided for @membersNamesAssignedOf.
  ///
  /// In fr, this message translates to:
  /// **'/{total} noms attribués'**
  String membersNamesAssignedOf(int total);

  /// No description provided for @membersComplete.
  ///
  /// In fr, this message translates to:
  /// **'Complet'**
  String get membersComplete;

  /// No description provided for @addMemberCodeCopied.
  ///
  /// In fr, this message translates to:
  /// **'Code copié.'**
  String get addMemberCodeCopied;

  /// No description provided for @addMemberTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un membre'**
  String get addMemberTitle;

  /// No description provided for @addMemberSubmit.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter et générer le code'**
  String get addMemberSubmit;

  /// No description provided for @addMemberAddedFlash.
  ///
  /// In fr, this message translates to:
  /// **'{name} a été ajouté(e) à la tontine.'**
  String addMemberAddedFlash(String name);

  /// No description provided for @addMemberAddedTitle.
  ///
  /// In fr, this message translates to:
  /// **'{name} a été ajouté(e)'**
  String addMemberAddedTitle(String name);

  /// No description provided for @addMemberNoNamesYet.
  ///
  /// In fr, this message translates to:
  /// **'Sans nom attribué pour le moment.'**
  String get addMemberNoNamesYet;

  /// No description provided for @addMemberWithNames.
  ///
  /// In fr, this message translates to:
  /// **'Avec {names}.'**
  String addMemberWithNames(String names);

  /// No description provided for @addMemberShareCode.
  ///
  /// In fr, this message translates to:
  /// **'Transmettez-lui ce code pour qu\'il ou elle rejoigne la tontine.'**
  String get addMemberShareCode;

  /// No description provided for @addMemberInviteCodeOverline.
  ///
  /// In fr, this message translates to:
  /// **'CODE D\'INVITATION'**
  String get addMemberInviteCodeOverline;

  /// No description provided for @addMemberInviteCodeSemantics.
  ///
  /// In fr, this message translates to:
  /// **'Code d\'invitation {code}'**
  String addMemberInviteCodeSemantics(String code);

  /// No description provided for @addMemberCopyCode.
  ///
  /// In fr, this message translates to:
  /// **'Copier le code'**
  String get addMemberCopyCode;

  /// No description provided for @commonDone.
  ///
  /// In fr, this message translates to:
  /// **'Terminé'**
  String get commonDone;

  /// No description provided for @profileContactUpdated.
  ///
  /// In fr, this message translates to:
  /// **'Coordonnées mises à jour.'**
  String get profileContactUpdated;

  /// No description provided for @profileDeactivateTitle.
  ///
  /// In fr, this message translates to:
  /// **'Désactiver {name} ?'**
  String profileDeactivateTitle(String name);

  /// No description provided for @profileDeactivateMessage.
  ///
  /// In fr, this message translates to:
  /// **'Ce membre n\'apparaîtra plus dans les membres actifs. Vous pourrez le réactiver à tout moment.'**
  String get profileDeactivateMessage;

  /// No description provided for @profileDeactivate.
  ///
  /// In fr, this message translates to:
  /// **'Désactiver'**
  String get profileDeactivate;

  /// No description provided for @profileDeactivated.
  ///
  /// In fr, this message translates to:
  /// **'{name} a été désactivé(e).'**
  String profileDeactivated(String name);

  /// No description provided for @profileReactivated.
  ///
  /// In fr, this message translates to:
  /// **'{name} a été réactivé(e).'**
  String profileReactivated(String name);

  /// No description provided for @profileNamesAssigned.
  ///
  /// In fr, this message translates to:
  /// **'{names} attribué(s) à {name}.'**
  String profileNamesAssigned(String names, String name);

  /// No description provided for @profileLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger ce membre.'**
  String get profileLoadError;

  /// No description provided for @profileNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Ce membre est introuvable.'**
  String get profileNotFound;

  /// No description provided for @profileEditContact.
  ///
  /// In fr, this message translates to:
  /// **'Modifier les coordonnées'**
  String get profileEditContact;

  /// No description provided for @commonSave.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get commonSave;

  /// No description provided for @contactWhatsApp.
  ///
  /// In fr, this message translates to:
  /// **'WhatsApp'**
  String get contactWhatsApp;

  /// No description provided for @profileNamesHeld.
  ///
  /// In fr, this message translates to:
  /// **'Noms détenus'**
  String get profileNamesHeld;

  /// No description provided for @profileNoNamesYet.
  ///
  /// In fr, this message translates to:
  /// **'Aucun nom attribué pour le moment.'**
  String get profileNoNamesYet;

  /// No description provided for @profileDeactivateMember.
  ///
  /// In fr, this message translates to:
  /// **'Désactiver ce membre'**
  String get profileDeactivateMember;

  /// No description provided for @profileReactivateMember.
  ///
  /// In fr, this message translates to:
  /// **'Réactiver ce membre'**
  String get profileReactivateMember;

  /// No description provided for @profileInviteCodeUsed.
  ///
  /// In fr, this message translates to:
  /// **'Code d\'invitation (utilisé)'**
  String get profileInviteCodeUsed;

  /// No description provided for @profileInviteCode.
  ///
  /// In fr, this message translates to:
  /// **'Code d\'invitation'**
  String get profileInviteCode;

  /// No description provided for @profileRegistered.
  ///
  /// In fr, this message translates to:
  /// **'Inscrit'**
  String get profileRegistered;

  /// No description provided for @profileShareCodeWith.
  ///
  /// In fr, this message translates to:
  /// **'À transmettre à {name} pour qu\'il ou elle rejoigne la tontine.'**
  String profileShareCodeWith(String name);

  /// No description provided for @profileDuePerDueDate.
  ///
  /// In fr, this message translates to:
  /// **'DÛ PAR ÉCHÉANCE'**
  String get profileDuePerDueDate;

  /// No description provided for @profileNamesHeldCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 nom détenu} other{{count} noms détenus}}'**
  String profileNamesHeldCount(int count);

  /// No description provided for @statusDeactivated.
  ///
  /// In fr, this message translates to:
  /// **'Désactivé'**
  String get statusDeactivated;

  /// No description provided for @statusAwaitingSignup.
  ///
  /// In fr, this message translates to:
  /// **'En attente d\'inscription'**
  String get statusAwaitingSignup;

  /// No description provided for @statusActive.
  ///
  /// In fr, this message translates to:
  /// **'Actif'**
  String get statusActive;

  /// No description provided for @profileAssignNamesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Attribuer des noms'**
  String get profileAssignNamesTitle;

  /// No description provided for @profileAssignNamesQuestion.
  ///
  /// In fr, this message translates to:
  /// **'Combien de noms supplémentaires pour {name} ?'**
  String profileAssignNamesQuestion(String name);

  /// No description provided for @memberFormContactRequired.
  ///
  /// In fr, this message translates to:
  /// **'Indiquez au moins un email ou un numéro WhatsApp.'**
  String get memberFormContactRequired;

  /// No description provided for @memberFormFullName.
  ///
  /// In fr, this message translates to:
  /// **'Nom complet'**
  String get memberFormFullName;

  /// No description provided for @memberFormNameTooShort.
  ///
  /// In fr, this message translates to:
  /// **'Le nom doit contenir au moins 2 caractères.'**
  String get memberFormNameTooShort;

  /// No description provided for @memberFormWhatsApp.
  ///
  /// In fr, this message translates to:
  /// **'Numéro WhatsApp'**
  String get memberFormWhatsApp;

  /// No description provided for @memberFormEmail.
  ///
  /// In fr, this message translates to:
  /// **'Email'**
  String get memberFormEmail;

  /// No description provided for @memberFormOneContactRequired.
  ///
  /// In fr, this message translates to:
  /// **'Au moins un des deux moyens de contact est requis.'**
  String get memberFormOneContactRequired;

  /// No description provided for @memberFormHalfNamesHelp.
  ///
  /// In fr, this message translates to:
  /// **'Un nom peut être partagé en demies entre deux membres ; le nom entier lui appartient exclusivement.'**
  String get memberFormHalfNamesHelp;

  /// No description provided for @errorNamesQuotaExceeded.
  ///
  /// In fr, this message translates to:
  /// **'Cette attribution dépasserait le nombre de noms prévu pour la tontine ({total}).'**
  String errorNamesQuotaExceeded(int total);

  /// No description provided for @defaultNameLabel.
  ///
  /// In fr, this message translates to:
  /// **'Nom {position}'**
  String defaultNameLabel(int position);

  /// No description provided for @assignSharesMustTotal100.
  ///
  /// In fr, this message translates to:
  /// **'La somme des parts doit être égale à 100 %.'**
  String get assignSharesMustTotal100;

  /// No description provided for @assignSharesSaved.
  ///
  /// In fr, this message translates to:
  /// **'Parts enregistrées.'**
  String get assignSharesSaved;

  /// No description provided for @assignLoadNamesError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les noms.'**
  String get assignLoadNamesError;

  /// No description provided for @assignNameNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Ce nom est introuvable.'**
  String get assignNameNotFound;

  /// No description provided for @assignNewName.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau nom'**
  String get assignNewName;

  /// No description provided for @assignEditShares.
  ///
  /// In fr, this message translates to:
  /// **'Modifier les parts'**
  String get assignEditShares;

  /// No description provided for @assignAddActiveMembersFirst.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez d\'abord des membres actifs pour pouvoir leur attribuer ce nom.'**
  String get assignAddActiveMembersFirst;

  /// No description provided for @assignFrozen.
  ///
  /// In fr, this message translates to:
  /// **'Figé — l\'échéancier a déjà démarré. Modifier ces parts fausserait les montants dus déjà calculés.'**
  String get assignFrozen;

  /// No description provided for @partsHolders.
  ///
  /// In fr, this message translates to:
  /// **'Détenteurs de part'**
  String get partsHolders;

  /// No description provided for @partsSplitEqually.
  ///
  /// In fr, this message translates to:
  /// **'Répartir également'**
  String get partsSplitEqually;

  /// No description provided for @partsTotal.
  ///
  /// In fr, this message translates to:
  /// **'Total : {percent} %'**
  String partsTotal(int percent);

  /// No description provided for @scheduleTabUpcoming.
  ///
  /// In fr, this message translates to:
  /// **'À venir ({count})'**
  String scheduleTabUpcoming(int count);

  /// No description provided for @scheduleTabHistory.
  ///
  /// In fr, this message translates to:
  /// **'Historique ({count})'**
  String scheduleTabHistory(int count);

  /// No description provided for @scheduleLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger l\'échéancier.'**
  String get scheduleLoadError;

  /// No description provided for @scheduleNoCalendarYet.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore de calendrier'**
  String get scheduleNoCalendarYet;

  /// No description provided for @scheduleDragHint.
  ///
  /// In fr, this message translates to:
  /// **'Maintenez et faites glisser pour changer l\'ordre.'**
  String get scheduleDragHint;

  /// No description provided for @scheduleNoTurnPaid.
  ///
  /// In fr, this message translates to:
  /// **'Aucun tour remis pour le moment. Les tours apparaîtront ici une fois la cagnotte remise.'**
  String get scheduleNoTurnPaid;

  /// No description provided for @reorderReasonRequired.
  ///
  /// In fr, this message translates to:
  /// **'Indiquez la raison de ce changement.'**
  String get reorderReasonRequired;

  /// No description provided for @reorderTitle.
  ///
  /// In fr, this message translates to:
  /// **'Déplacer ce tour'**
  String get reorderTitle;

  /// No description provided for @reorderExplanation.
  ///
  /// In fr, this message translates to:
  /// **'Les dates des tours suivants seront recalculées. Expliquez pourquoi l\'ordre change.'**
  String get reorderExplanation;

  /// No description provided for @reorderHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex. absence exceptionnelle, demande du membre…'**
  String get reorderHint;

  /// No description provided for @commonConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer'**
  String get commonConfirm;

  /// No description provided for @turnStatusUpcoming.
  ///
  /// In fr, this message translates to:
  /// **'À venir'**
  String get turnStatusUpcoming;

  /// No description provided for @turnStatusInProgress.
  ///
  /// In fr, this message translates to:
  /// **'En cours'**
  String get turnStatusInProgress;

  /// No description provided for @turnStatusPaid.
  ///
  /// In fr, this message translates to:
  /// **'Remis'**
  String get turnStatusPaid;

  /// No description provided for @turnStatusPostponed.
  ///
  /// In fr, this message translates to:
  /// **'Reporté'**
  String get turnStatusPostponed;

  /// No description provided for @turnHistoryTitle.
  ///
  /// In fr, this message translates to:
  /// **'Historique du tour'**
  String get turnHistoryTitle;

  /// No description provided for @turnPositionChange.
  ///
  /// In fr, this message translates to:
  /// **'Position {from} → {to}'**
  String turnPositionChange(int from, int to);

  /// No description provided for @turnPaidOn.
  ///
  /// In fr, this message translates to:
  /// **'Remis le {date}'**
  String turnPaidOn(String date);

  /// No description provided for @turnPlannedOn.
  ///
  /// In fr, this message translates to:
  /// **'Prévu le {date}'**
  String turnPlannedOn(String date);

  /// No description provided for @turnChangesSeeHistory.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{Repositionné — voir l\'historique} other{{count} changements — voir l\'historique}}'**
  String turnChangesSeeHistory(int count);

  /// No description provided for @turnsPaidOf.
  ///
  /// In fr, this message translates to:
  /// **' / {total} tours remis'**
  String turnsPaidOf(int total);

  /// No description provided for @collectLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger la collecte.'**
  String get collectLoadError;

  /// No description provided for @collectTurnNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Ce tour est introuvable.'**
  String get collectTurnNotFound;

  /// No description provided for @collectRecorded.
  ///
  /// In fr, this message translates to:
  /// **'Cotisation de {name} enregistrée.'**
  String collectRecorded(String name);

  /// No description provided for @collectTitleAdmin.
  ///
  /// In fr, this message translates to:
  /// **'Collecte — Tour {position}'**
  String collectTitleAdmin(int position);

  /// No description provided for @collectTitleMember.
  ///
  /// In fr, this message translates to:
  /// **'Tour {position} — Contributions'**
  String collectTitleMember(int position);

  /// No description provided for @collectTabToCollect.
  ///
  /// In fr, this message translates to:
  /// **'À collecter ({count})'**
  String collectTabToCollect(int count);

  /// No description provided for @collectTabSettled.
  ///
  /// In fr, this message translates to:
  /// **'Réglé ({count})'**
  String collectTabSettled(int count);

  /// No description provided for @collectNoHolders.
  ///
  /// In fr, this message translates to:
  /// **'Aucun détenteur de part pour ce tour.'**
  String get collectNoHolders;

  /// No description provided for @collectEveryonePaid.
  ///
  /// In fr, this message translates to:
  /// **'Tout le monde a réglé ce tour.'**
  String get collectEveryonePaid;

  /// No description provided for @collectNoPaymentsYet.
  ///
  /// In fr, this message translates to:
  /// **'Aucun règlement enregistré pour le moment.'**
  String get collectNoPaymentsYet;

  /// No description provided for @collectDueOverline.
  ///
  /// In fr, this message translates to:
  /// **'ÉCHÉANCE · {date}'**
  String collectDueOverline(String date);

  /// No description provided for @collectComplete.
  ///
  /// In fr, this message translates to:
  /// **'Collecte complète'**
  String get collectComplete;

  /// No description provided for @collectPeopleLeft.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 personne à encaisser} other{{count} personnes à encaisser}}'**
  String collectPeopleLeft(int count);

  /// No description provided for @statusUnpaid.
  ///
  /// In fr, this message translates to:
  /// **'Impayé'**
  String get statusUnpaid;

  /// No description provided for @collectRemainingOf.
  ///
  /// In fr, this message translates to:
  /// **'reste sur {amount}'**
  String collectRemainingOf(String amount);

  /// No description provided for @contribInvalidAmount.
  ///
  /// In fr, this message translates to:
  /// **'Indiquez un montant versé valide.'**
  String get contribInvalidAmount;

  /// No description provided for @contribAmountExceedsDue.
  ///
  /// In fr, this message translates to:
  /// **'Le montant versé ne peut pas dépasser le montant dû.'**
  String get contribAmountExceedsDue;

  /// No description provided for @contribMarkedOnTimeReason.
  ///
  /// In fr, this message translates to:
  /// **'Marqué comme à temps par l’administratrice.'**
  String get contribMarkedOnTimeReason;

  /// No description provided for @contribAmountDue.
  ///
  /// In fr, this message translates to:
  /// **'Montant dû : {amount}'**
  String contribAmountDue(String amount);

  /// No description provided for @contribAmountPaid.
  ///
  /// In fr, this message translates to:
  /// **'Montant versé'**
  String get contribAmountPaid;

  /// No description provided for @contribPaymentDate.
  ///
  /// In fr, this message translates to:
  /// **'Date du paiement'**
  String get contribPaymentDate;

  /// No description provided for @contribIsLate.
  ///
  /// In fr, this message translates to:
  /// **'Ce paiement est-il en retard ?'**
  String get contribIsLate;

  /// No description provided for @contribOnTime.
  ///
  /// In fr, this message translates to:
  /// **'À temps'**
  String get contribOnTime;

  /// No description provided for @contribPenaltyWaived.
  ///
  /// In fr, this message translates to:
  /// **'Pénalité levée'**
  String get contribPenaltyWaived;

  /// No description provided for @contribPenaltyComputed.
  ///
  /// In fr, this message translates to:
  /// **'Pénalité calculée'**
  String get contribPenaltyComputed;

  /// No description provided for @contribCancelWaiver.
  ///
  /// In fr, this message translates to:
  /// **'Annuler la levée'**
  String get contribCancelWaiver;

  /// No description provided for @contribWaivePenalty.
  ///
  /// In fr, this message translates to:
  /// **'Lever la pénalité'**
  String get contribWaivePenalty;

  /// No description provided for @contribSubmit.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer la cotisation'**
  String get contribSubmit;

  /// No description provided for @declValidated.
  ///
  /// In fr, this message translates to:
  /// **'Déclaration validée.'**
  String get declValidated;

  /// No description provided for @declRejected.
  ///
  /// In fr, this message translates to:
  /// **'Déclaration refusée.'**
  String get declRejected;

  /// No description provided for @declTitle.
  ///
  /// In fr, this message translates to:
  /// **'Déclaration'**
  String get declTitle;

  /// No description provided for @declLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger cette déclaration.'**
  String get declLoadError;

  /// No description provided for @declNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Cette déclaration est introuvable.'**
  String get declNotFound;

  /// No description provided for @turnLabel.
  ///
  /// In fr, this message translates to:
  /// **'Tour {position}'**
  String turnLabel(int position);

  /// No description provided for @declAmountDeclared.
  ///
  /// In fr, this message translates to:
  /// **'Montant déclaré'**
  String get declAmountDeclared;

  /// No description provided for @declPaidOn.
  ///
  /// In fr, this message translates to:
  /// **'Payé le {date}'**
  String declPaidOn(String date);

  /// No description provided for @declRejectionReason.
  ///
  /// In fr, this message translates to:
  /// **'Motif du refus : {reason}'**
  String declRejectionReason(String reason);

  /// No description provided for @declProofOfPayment.
  ///
  /// In fr, this message translates to:
  /// **'Preuve de paiement'**
  String get declProofOfPayment;

  /// No description provided for @declApprove.
  ///
  /// In fr, this message translates to:
  /// **'Valider la déclaration'**
  String get declApprove;

  /// No description provided for @declReject.
  ///
  /// In fr, this message translates to:
  /// **'Refuser'**
  String get declReject;

  /// No description provided for @declNewDeclaration.
  ///
  /// In fr, this message translates to:
  /// **'Faire une nouvelle déclaration'**
  String get declNewDeclaration;

  /// No description provided for @declStatusPending.
  ///
  /// In fr, this message translates to:
  /// **'En attente'**
  String get declStatusPending;

  /// No description provided for @declStatusApproved.
  ///
  /// In fr, this message translates to:
  /// **'Validée'**
  String get declStatusApproved;

  /// No description provided for @declStatusDisputed.
  ///
  /// In fr, this message translates to:
  /// **'Contestée'**
  String get declStatusDisputed;

  /// No description provided for @declProofLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger la preuve.'**
  String get declProofLoadError;

  /// No description provided for @declNoProof.
  ///
  /// In fr, this message translates to:
  /// **'Aucune preuve disponible.'**
  String get declNoProof;

  /// No description provided for @declEnlargeProof.
  ///
  /// In fr, this message translates to:
  /// **'Agrandir la preuve'**
  String get declEnlargeProof;

  /// No description provided for @declRejectReasonRequired.
  ///
  /// In fr, this message translates to:
  /// **'Indiquez la raison du refus.'**
  String get declRejectReasonRequired;

  /// No description provided for @declRejectTitle.
  ///
  /// In fr, this message translates to:
  /// **'Refuser cette déclaration'**
  String get declRejectTitle;

  /// No description provided for @declRejectHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex. preuve illisible, montant incorrect…'**
  String get declRejectHint;

  /// No description provided for @declListLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les déclarations.'**
  String get declListLoadError;

  /// No description provided for @declNone.
  ///
  /// In fr, this message translates to:
  /// **'Aucune déclaration'**
  String get declNone;

  /// No description provided for @declNoneMessage.
  ///
  /// In fr, this message translates to:
  /// **'Quand un membre signale avoir payé, sa déclaration et sa preuve apparaissent ici.'**
  String get declNoneMessage;

  /// No description provided for @unknownTurn.
  ///
  /// In fr, this message translates to:
  /// **'Tour inconnu'**
  String get unknownTurn;

  /// No description provided for @declGroupTitle.
  ///
  /// In fr, this message translates to:
  /// **'Tour {position} — {beneficiaries}'**
  String declGroupTitle(int position, String beneficiaries);

  /// No description provided for @declPendingOf.
  ///
  /// In fr, this message translates to:
  /// **'{pending} en attente sur {total}'**
  String declPendingOf(int pending, int total);

  /// No description provided for @declCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 déclaration} other{{count} déclarations}}'**
  String declCount(int count);

  /// No description provided for @waiverReasonRequired.
  ///
  /// In fr, this message translates to:
  /// **'Indiquez la raison de cette exception.'**
  String get waiverReasonRequired;

  /// No description provided for @waiverExplanation.
  ///
  /// In fr, this message translates to:
  /// **'La pénalité de retard calculée ne sera pas appliquée à cette cotisation. Expliquez pourquoi.'**
  String get waiverExplanation;

  /// No description provided for @waiverHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex. panne réseau signalée à l’avance'**
  String get waiverHint;

  /// No description provided for @proofImageError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de récupérer l\'image. Réessayez.'**
  String get proofImageError;

  /// No description provided for @proofTakePhoto.
  ///
  /// In fr, this message translates to:
  /// **'Prendre une photo'**
  String get proofTakePhoto;

  /// No description provided for @proofChooseFromGallery.
  ///
  /// In fr, this message translates to:
  /// **'Choisir dans la galerie'**
  String get proofChooseFromGallery;

  /// No description provided for @proofRequired.
  ///
  /// In fr, this message translates to:
  /// **'Preuve (obligatoire)'**
  String get proofRequired;

  /// No description provided for @proofOptional.
  ///
  /// In fr, this message translates to:
  /// **'Preuve (optionnelle)'**
  String get proofOptional;

  /// No description provided for @proofRemove.
  ///
  /// In fr, this message translates to:
  /// **'Retirer la preuve'**
  String get proofRemove;

  /// No description provided for @proofCompressing.
  ///
  /// In fr, this message translates to:
  /// **'Compression en cours…'**
  String get proofCompressing;

  /// No description provided for @proofAdd.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une preuve'**
  String get proofAdd;

  /// No description provided for @memberSpaceTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mon espace'**
  String get memberSpaceTitle;

  /// No description provided for @memberSpaceLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger votre espace.'**
  String get memberSpaceLoadError;

  /// No description provided for @memberSpaceNoMember.
  ///
  /// In fr, this message translates to:
  /// **'Aucune fiche membre associée à ce compte.'**
  String get memberSpaceNoMember;

  /// No description provided for @memberSpaceScheduleNotGenerated.
  ///
  /// In fr, this message translates to:
  /// **'L\'échéancier n\'a pas encore été généré par l\'administratrice.'**
  String get memberSpaceScheduleNotGenerated;

  /// No description provided for @memberSpaceAllTurnsPaid.
  ///
  /// In fr, this message translates to:
  /// **'Tous les tours ont été remis.'**
  String get memberSpaceAllTurnsPaid;

  /// No description provided for @memberSpaceToPayThisTurn.
  ///
  /// In fr, this message translates to:
  /// **'À régler pour ce tour'**
  String get memberSpaceToPayThisTurn;

  /// No description provided for @memberSpaceMyDeclarations.
  ///
  /// In fr, this message translates to:
  /// **'Mes déclarations'**
  String get memberSpaceMyDeclarations;

  /// No description provided for @memberSpaceDeclaredOn.
  ///
  /// In fr, this message translates to:
  /// **'Déclaré le {date}'**
  String memberSpaceDeclaredOn(String date);

  /// No description provided for @memberSpaceContributionHistory.
  ///
  /// In fr, this message translates to:
  /// **'Historique des cotisations'**
  String get memberSpaceContributionHistory;

  /// No description provided for @declareInvalidAmount.
  ///
  /// In fr, this message translates to:
  /// **'Indiquez un montant valide.'**
  String get declareInvalidAmount;

  /// No description provided for @declareAmountExceedsRemaining.
  ///
  /// In fr, this message translates to:
  /// **'Le montant ne peut pas dépasser le reste à devoir.'**
  String get declareAmountExceedsRemaining;

  /// No description provided for @declareProofRequired.
  ///
  /// In fr, this message translates to:
  /// **'Une preuve est obligatoire pour déclarer un paiement.'**
  String get declareProofRequired;

  /// No description provided for @declareSent.
  ///
  /// In fr, this message translates to:
  /// **'Déclaration envoyée. En attente de validation par l\'administratrice.'**
  String get declareSent;

  /// No description provided for @declareTitle.
  ///
  /// In fr, this message translates to:
  /// **'J\'ai payé'**
  String get declareTitle;

  /// No description provided for @declareNotAllowed.
  ///
  /// In fr, this message translates to:
  /// **'Ce nom ne peut plus être déclaré pour le tour en cours.'**
  String get declareNotAllowed;

  /// No description provided for @declareRemaining.
  ///
  /// In fr, this message translates to:
  /// **'Reste à devoir : {amount}'**
  String declareRemaining(String amount);

  /// No description provided for @declareSubmit.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer la déclaration'**
  String get declareSubmit;

  /// No description provided for @myNamesNoCurrentTurn.
  ///
  /// In fr, this message translates to:
  /// **'Aucun tour en cours pour vos noms.'**
  String get myNamesNoCurrentTurn;

  /// No description provided for @myNamesDeclarationPending.
  ///
  /// In fr, this message translates to:
  /// **'Déclaration en attente'**
  String get myNamesDeclarationPending;

  /// No description provided for @myNamesDeclarationDisputed.
  ///
  /// In fr, this message translates to:
  /// **'Déclaration contestée'**
  String get myNamesDeclarationDisputed;

  /// No description provided for @myNamesShare.
  ///
  /// In fr, this message translates to:
  /// **'Part : {fraction}'**
  String myNamesShare(String fraction);

  /// No description provided for @situationNoUpcomingTurn.
  ///
  /// In fr, this message translates to:
  /// **'Aucun tour à venir pour vos noms.'**
  String get situationNoUpcomingTurn;

  /// No description provided for @situationYourNextTurn.
  ///
  /// In fr, this message translates to:
  /// **'Votre prochain tour'**
  String get situationYourNextTurn;

  /// No description provided for @situationTurnLine.
  ///
  /// In fr, this message translates to:
  /// **'{name} · tour {position} · {relative}'**
  String situationTurnLine(String name, int position, String relative);

  /// No description provided for @onboarding1Title.
  ///
  /// In fr, this message translates to:
  /// **'Votre tontine,\nsans cahier ni calculs'**
  String get onboarding1Title;

  /// No description provided for @onboarding1Text.
  ///
  /// In fr, this message translates to:
  /// **'Membres, noms, parts et ordre des tours : tout le cercle est réglé une fois, puis {appName} tient le calendrier pour vous.'**
  String onboarding1Text(String appName);

  /// No description provided for @onboarding2Title.
  ///
  /// In fr, this message translates to:
  /// **'Chaque franc,\nsuivi en direct'**
  String get onboarding2Title;

  /// No description provided for @onboarding2Text.
  ///
  /// In fr, this message translates to:
  /// **'Voyez qui a payé, qui est en retard et combien il reste à collecter pour le tour en cours. Les pénalités se calculent toutes seules.'**
  String get onboarding2Text;

  /// No description provided for @onboarding3Title.
  ///
  /// In fr, this message translates to:
  /// **'Les membres déclarent,\nvous validez'**
  String get onboarding3Title;

  /// No description provided for @onboarding3Text.
  ///
  /// In fr, this message translates to:
  /// **'Chaque membre signale son paiement avec une preuve, depuis son téléphone. L\'administratrice vérifie et valide en un geste.'**
  String get onboarding3Text;

  /// No description provided for @onboardingSkip.
  ///
  /// In fr, this message translates to:
  /// **'Passer'**
  String get onboardingSkip;

  /// No description provided for @onboardingStart.
  ///
  /// In fr, this message translates to:
  /// **'Commencer'**
  String get onboardingStart;

  /// No description provided for @onboardingHaveCode.
  ///
  /// In fr, this message translates to:
  /// **'J\'ai reçu un code d\'invitation'**
  String get onboardingHaveCode;

  /// No description provided for @onboardingCircleCaption.
  ///
  /// In fr, this message translates to:
  /// **'Tour 5 · Aïcha reçoit la cagnotte'**
  String get onboardingCircleCaption;

  /// No description provided for @onboardingCollectOverline.
  ///
  /// In fr, this message translates to:
  /// **'COLLECTE · TOUR 3'**
  String get onboardingCollectOverline;

  /// No description provided for @onboardingDeclaredPayment.
  ///
  /// In fr, this message translates to:
  /// **'a déclaré un paiement'**
  String get onboardingDeclaredPayment;

  /// No description provided for @onboardingMobileMoneyReceipt.
  ///
  /// In fr, this message translates to:
  /// **'Reçu Mobile Money joint'**
  String get onboardingMobileMoneyReceipt;

  /// No description provided for @errorAlreadyMember.
  ///
  /// In fr, this message translates to:
  /// **'Vous faites déjà partie de ce groupe.'**
  String get errorAlreadyMember;

  /// No description provided for @errorForbidden.
  ///
  /// In fr, this message translates to:
  /// **'Cette action est réservée au bureau du groupe.'**
  String get errorForbidden;

  /// No description provided for @errorDeclarationNotPending.
  ///
  /// In fr, this message translates to:
  /// **'Cette déclaration a déjà été traitée.'**
  String get errorDeclarationNotPending;

  /// No description provided for @errorTurnAlreadyPaid.
  ///
  /// In fr, this message translates to:
  /// **'Un tour déjà remis ne peut pas être déplacé.'**
  String get errorTurnAlreadyPaid;

  /// No description provided for @errorLastOwner.
  ///
  /// In fr, this message translates to:
  /// **'Le groupe doit garder au moins un propriétaire.'**
  String get errorLastOwner;

  /// No description provided for @errorNamesQuotaReached.
  ///
  /// In fr, this message translates to:
  /// **'Tous les noms prévus pour la tontine sont déjà attribués.'**
  String get errorNamesQuotaReached;

  /// No description provided for @errorServerNotConfigured.
  ///
  /// In fr, this message translates to:
  /// **'L\'application n\'est pas reliée à son serveur. Contactez le support.'**
  String get errorServerNotConfigured;

  /// No description provided for @errorEmailNotConfirmed.
  ///
  /// In fr, this message translates to:
  /// **'Confirmez d\'abord votre adresse : ouvrez le lien reçu par email.'**
  String get errorEmailNotConfirmed;

  /// No description provided for @verifyBodyLink.
  ///
  /// In fr, this message translates to:
  /// **'Un lien de confirmation a été envoyé à {email}. Ouvrez-le depuis ce téléphone pour entrer directement dans l\'application, ou connectez-vous ensuite.'**
  String verifyBodyLink(String email);

  /// No description provided for @verifyDoneSignIn.
  ///
  /// In fr, this message translates to:
  /// **'J\'ai confirmé, me connecter'**
  String get verifyDoneSignIn;

  /// No description provided for @roleOwner.
  ///
  /// In fr, this message translates to:
  /// **'Propriétaire'**
  String get roleOwner;

  /// No description provided for @rolePresident.
  ///
  /// In fr, this message translates to:
  /// **'Président(e)'**
  String get rolePresident;

  /// No description provided for @roleTreasurer.
  ///
  /// In fr, this message translates to:
  /// **'Trésorier(ère)'**
  String get roleTreasurer;

  /// No description provided for @roleAuditor.
  ///
  /// In fr, this message translates to:
  /// **'Commissaire aux comptes'**
  String get roleAuditor;

  /// No description provided for @roleMember.
  ///
  /// In fr, this message translates to:
  /// **'Membre'**
  String get roleMember;

  /// No description provided for @groupsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mes groupes'**
  String get groupsTitle;

  /// No description provided for @groupsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Touchez un groupe pour l\'afficher.'**
  String get groupsSubtitle;

  /// No description provided for @groupsCurrent.
  ///
  /// In fr, this message translates to:
  /// **'Affiché'**
  String get groupsCurrent;

  /// No description provided for @groupsJoinWithCode.
  ///
  /// In fr, this message translates to:
  /// **'Rejoindre avec un code'**
  String get groupsJoinWithCode;

  /// No description provided for @groupsSwitch.
  ///
  /// In fr, this message translates to:
  /// **'Changer de groupe'**
  String get groupsSwitch;

  /// No description provided for @settingsMyGroups.
  ///
  /// In fr, this message translates to:
  /// **'Mes groupes'**
  String get settingsMyGroups;

  /// No description provided for @settingsMyGroupsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 groupe · créer ou rejoindre un autre} other{{count} groupes · changer, créer ou rejoindre}}'**
  String settingsMyGroupsSubtitle(int count);

  /// No description provided for @loginContinueWithApple.
  ///
  /// In fr, this message translates to:
  /// **'Continuer avec Apple'**
  String get loginContinueWithApple;

  /// No description provided for @newPasswordTitle.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez un nouveau mot de passe'**
  String get newPasswordTitle;

  /// No description provided for @newPasswordSubmit.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer le mot de passe'**
  String get newPasswordSubmit;

  /// No description provided for @newPasswordSaved.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe modifié.'**
  String get newPasswordSaved;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
