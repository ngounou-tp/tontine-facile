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

  /// No description provided for @verifyStillNotVerified.
  ///
  /// In fr, this message translates to:
  /// **'Toujours pas vérifié. Pensez à vérifier vos courriers indésirables.'**
  String get verifyStillNotVerified;

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

  /// No description provided for @verifyBody.
  ///
  /// In fr, this message translates to:
  /// **'Un lien de vérification a été envoyé à {email}. Ouvrez-le, puis revenez sur cet écran.'**
  String verifyBody(String email);

  /// No description provided for @verifyDone.
  ///
  /// In fr, this message translates to:
  /// **'J\'ai vérifié mon adresse'**
  String get verifyDone;

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
