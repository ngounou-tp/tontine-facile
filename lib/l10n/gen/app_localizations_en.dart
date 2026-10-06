// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get relativeToday => 'today';

  @override
  String get relativeTomorrow => 'tomorrow';

  @override
  String get relativeYesterday => 'yesterday';

  @override
  String relativeInDays(int days) {
    return 'in $days days';
  }

  @override
  String relativeDaysAgo(int days) {
    return '$days days ago';
  }

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get errorNetwork =>
      'The connection timed out. Check your connection and try again.';

  @override
  String get errorInvalidCredentials => 'Incorrect email or password.';

  @override
  String get errorEmailAlreadyInUse =>
      'An account already exists with this email.';

  @override
  String get errorWeakPassword =>
      'The password is too weak (6 characters minimum).';

  @override
  String get errorInvalidEmail => 'The email address is invalid.';

  @override
  String get errorUserDisabled => 'This account has been disabled.';

  @override
  String get errorTooManyRequests => 'Too many attempts. Try again later.';

  @override
  String get errorSignInRequired => 'Sign in to continue.';

  @override
  String get errorExternalSignIn =>
      'Signing in with this account failed. Please try again.';

  @override
  String get errorAuthUnknown => 'Authentication error. Please try again.';

  @override
  String get errorInvitationNotFound => 'This invitation code was not found.';

  @override
  String get errorInvitationAlreadyUsed =>
      'This invitation has already been used.';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonBack => 'Back';

  @override
  String get commonLoading => 'Loading';

  @override
  String get commonComingSoon => 'This feature is coming soon.';

  @override
  String get amountFieldLabel => 'Contribution amount';

  @override
  String get amountFieldHint => '25,000 FCFA';

  @override
  String get navHome => 'Home';

  @override
  String get navMembers => 'Members';

  @override
  String get navSchedule => 'Schedule';

  @override
  String get navDeclarations => 'Declarations';

  @override
  String get navSettings => 'Settings';

  @override
  String get statusPaid => 'Paid';

  @override
  String get statusLate => 'Late';

  @override
  String get statusPartial => 'Partial';

  @override
  String get statusException => 'Exception';

  @override
  String get statusToCollect => 'To collect';

  @override
  String get memberCardRecordPayment => 'Record a payment';

  @override
  String get memberCardMoreOptions => 'More options';

  @override
  String get authEmailLabel => 'Email';

  @override
  String get authPasswordLabel => 'Password';

  @override
  String get authConfirmPasswordLabel => 'Confirm password';

  @override
  String get authTogglePasswordVisibility => 'Show or hide password';

  @override
  String get authPasswordsDoNotMatch => 'Passwords do not match.';

  @override
  String get authInvalidEmail => 'Enter a valid email address.';

  @override
  String get authPasswordTooShort =>
      'The password must be at least 6 characters.';

  @override
  String get authTagline => 'Your tontine\'s records, always up to date';

  @override
  String get loginEnterEmailForReset =>
      'Enter your email to receive the reset link.';

  @override
  String get loginResetLinkSent =>
      'A reset link has been sent to your email address.';

  @override
  String get loginSubmit => 'Sign in';

  @override
  String get loginForgotPassword => 'Forgot password?';

  @override
  String get commonOr => 'or';

  @override
  String get loginContinueWithGoogle => 'Continue with Google';

  @override
  String get loginCreateAccount => 'Create an account';

  @override
  String get signupTitle => 'Create an account';

  @override
  String get signupSubmit => 'Create my account';

  @override
  String get signupHaveAccount => 'I already have an account';

  @override
  String welcomeTitle(String appName) {
    return 'Welcome to $appName';
  }

  @override
  String get welcomeSubtitle => 'How would you like to start?';

  @override
  String get welcomeCreateTitle => 'Create a tontine';

  @override
  String get welcomeCreateDescription =>
      'Start a new group, invite your members and track contributions today.';

  @override
  String get welcomeJoinTitle => 'Join a tontine';

  @override
  String get welcomeJoinDescription =>
      'Got a code from your treasurer? Join their group in seconds.';

  @override
  String get commonSignOut => 'Sign out';

  @override
  String get joinEnterSixChars =>
      'Enter the 6 characters of the invitation code.';

  @override
  String get joinSuccess => 'You have joined the tontine.';

  @override
  String get joinTitle => 'Enter your invitation code';

  @override
  String get joinSubtitle => 'Six characters, given by the group\'s treasurer.';

  @override
  String get joinPasteHint => 'You can paste the code';

  @override
  String get joinSubmit => 'Join';

  @override
  String get joinSearching => 'Looking up the tontine…';

  @override
  String joinMembersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count members',
      one: '1 member',
      zero: 'no members',
    );
    return ' · $_temp0';
  }

  @override
  String get verifyStillNotVerified =>
      'Still not verified. Remember to check your spam folder.';

  @override
  String get verifyEmailResent => 'Verification email sent again.';

  @override
  String get verifyYourAddressFallback => 'your address';

  @override
  String get verifyTitle => 'Verify your email address';

  @override
  String verifyBody(String email) {
    return 'A verification link has been sent to $email. Open it, then come back to this screen.';
  }

  @override
  String get verifyDone => 'I\'ve verified my address';

  @override
  String verifyResendIn(int seconds) {
    return 'Resend email ($seconds s)';
  }

  @override
  String get verifyResend => 'Resend email';

  @override
  String get weekdayMonday => 'Monday';

  @override
  String get weekdayTuesday => 'Tuesday';

  @override
  String get weekdayWednesday => 'Wednesday';

  @override
  String get weekdayThursday => 'Thursday';

  @override
  String get weekdayFriday => 'Friday';

  @override
  String get weekdaySaturday => 'Saturday';

  @override
  String get weekdaySunday => 'Sunday';

  @override
  String get occurrenceFirst => 'First';

  @override
  String get occurrenceSecond => 'Second';

  @override
  String get occurrenceThird => 'Third';

  @override
  String get occurrenceFourth => 'Fourth';

  @override
  String get occurrenceLast => 'Last';

  @override
  String get sharesModeFixed => 'Fixed amount per share';

  @override
  String get sharesModeProportional => 'Proportional split';

  @override
  String get sharesModeEqual => 'Equal shares';

  @override
  String get sharesModeFixedDescription =>
      'Each shareholder pays the same fixed amount, whatever their fraction.';

  @override
  String get sharesModeProportionalDescription =>
      'Each holder pays an amount proportional to their fraction of the name.';

  @override
  String get sharesModeEqualDescription =>
      'The name\'s amount is split equally among its holders.';

  @override
  String get penaltyNone => 'No penalty';

  @override
  String get penaltyFlat => 'Flat penalty (fixed amount)';

  @override
  String get penaltyProportional => 'Proportional penalty (% of amount due)';

  @override
  String periodEveryNDays(int days) {
    return 'Every $days days';
  }

  @override
  String periodWeekly(String day) {
    return 'Every $day';
  }

  @override
  String periodBiweekly(String day) {
    return 'Every other week, on $day';
  }

  @override
  String periodMonthlyDay(int day) {
    return 'Every month, on day $day';
  }

  @override
  String periodMonthlyWeekday(String occurrence, String day) {
    return '$occurrence $day of the month';
  }

  @override
  String get periodTypeEveryNDays => 'Every N days';

  @override
  String get periodTypeWeekly => 'Every week';

  @override
  String get periodTypeBiweekly => 'Every two weeks';

  @override
  String get periodTypeMonthlyDay => 'Every month, fixed day';

  @override
  String get periodTypeMonthlyWeekday => 'Every month, Nth weekday';

  @override
  String get fieldFrequency => 'Frequency';

  @override
  String get fieldDaysBetweenDueDates => 'Number of days between due dates';

  @override
  String get fieldDayOfMonth => 'Day of the month (1 to 31)';

  @override
  String get fieldWeekday => 'Day of the week';

  @override
  String get fieldOccurrenceInMonth => 'Occurrence in the month';

  @override
  String get fieldPenaltyRule => 'Penalty rule';

  @override
  String get fieldPenaltyAmount => 'Penalty amount (FCFA)';

  @override
  String get fieldPenaltyPercent => 'Penalty percentage (%)';

  @override
  String get fieldGraceDays => 'Grace period (days, 0 to 30)';

  @override
  String get createStepGroup => 'The group';

  @override
  String get createStepFrequency => 'Due date frequency';

  @override
  String get createStepPenalty => 'Penalty and grace period';

  @override
  String get createStepShares => 'Share split';

  @override
  String get createStepConfirm => 'Confirmation';

  @override
  String get createErrorGroupName =>
      'The group name must be at least 2 characters.';

  @override
  String get createErrorFullName => 'Enter your full name.';

  @override
  String get createErrorAmount => 'Enter a valid amount per name.';

  @override
  String get createErrorNamesCount =>
      'Enter how many names the tontine will have.';

  @override
  String get createErrorFirstDueDate => 'Choose the first due date.';

  @override
  String get createErrorPenaltyValue =>
      'Enter a penalty value greater than zero.';

  @override
  String get createErrorGraceDays =>
      'The grace period must be between 0 and 30 days.';

  @override
  String get createSuccess => 'Tontine created. Add your first members.';

  @override
  String get createPreviousStep => 'Previous step';

  @override
  String get createTitle => 'Create a tontine';

  @override
  String createStepOf(int step, int total) {
    return 'Step $step of $total';
  }

  @override
  String get createSubmit => 'Create the tontine';

  @override
  String get commonNext => 'Next';

  @override
  String get fieldGroupName => 'Group name';

  @override
  String get fieldGroupNameHint => 'Ladies\' Njangi';

  @override
  String get fieldYourFullName => 'Your full name';

  @override
  String get fieldFullNameHint => 'Adèle Tchoumi';

  @override
  String get fieldAmountPerName => 'Amount per name';

  @override
  String get fieldAmountHint => '25,000';

  @override
  String get fieldNamesCount => 'Number of names';

  @override
  String get fieldNamesCountHelp =>
      'How many names (shares) will the tontine have in total? You\'ll assign them to members as they join.';

  @override
  String get fieldFirstDueDate => 'First due date';

  @override
  String get fieldChooseDate => 'Choose a date';

  @override
  String get recapGroup => 'Group';

  @override
  String get recapAdmin => 'Administrator';

  @override
  String get recapFirstDueDate => 'First due date';

  @override
  String get recapPenalty => 'Penalty';

  @override
  String get recapPenaltyValue => 'Penalty value';

  @override
  String get recapGraceDays => 'Grace period';

  @override
  String recapGraceDaysValue(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
      zero: '0 days',
    );
    return '$_temp0';
  }

  @override
  String editErrorNamesBelowExisting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count names already exist: the number of names can\'t go below that.',
      one: '1 name already exists: the number of names can\'t go below that.',
    );
    return '$_temp0';
  }

  @override
  String get editSuccess => 'Tontine updated.';

  @override
  String get editTitleAdmin => 'Edit the tontine';

  @override
  String get editTitleMember => 'Tontine settings';

  @override
  String get errorLoadTontine => 'Couldn\'t load the tontine.';

  @override
  String get errorNoTontine => 'No tontine is linked to this account.';

  @override
  String get editSave => 'Save changes';

  @override
  String get editFrozenStarted => 'Locked — the schedule has started';

  @override
  String get editReadOnlyAdminOnly => 'Read-only — administrator only';

  @override
  String get editFrozenExplanation =>
      'Any change would invalidate amounts due and turns already calculated. This information can\'t change once collection has started.';

  @override
  String get editAdminOnlyExplanation =>
      'Only the tontine\'s administrator can change this information.';
}
