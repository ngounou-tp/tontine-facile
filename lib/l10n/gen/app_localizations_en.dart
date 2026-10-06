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

  @override
  String get homeAddMember => 'Add a member';

  @override
  String get homeLoading => 'Loading your tontine…';

  @override
  String get homeLoadError => 'Couldn\'t load your tontine.';

  @override
  String get homeHello => 'Hello';

  @override
  String homeHelloName(String name) {
    return 'Hello, $name';
  }

  @override
  String homeSubtitlePending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count payments are waiting for your approval.',
      one: 'One payment is waiting for your approval.',
      zero: 'Here\'s your tontine at a glance.',
    );
    return '$_temp0';
  }

  @override
  String get homeSubtitleMember => 'Here\'s your tontine at a glance.';

  @override
  String get homeAtAGlance => 'At a glance';

  @override
  String get commonSeeAll => 'See all';

  @override
  String get homeNoActiveMembers => 'No active members yet';

  @override
  String homeActiveMembers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count active members',
      one: '1 active member',
    );
    return '$_temp0';
  }

  @override
  String get unknownName => 'Unknown name';

  @override
  String get tourScheduleToPrepare => 'Schedule to prepare';

  @override
  String get tourScheduleToPrepareMessage =>
      'The schedule hasn\'t been generated yet. Assign the names, then generate it from Members.';

  @override
  String get tourGoToMembers => 'Go to members';

  @override
  String get tourTontineFinished => 'Tontine finished';

  @override
  String get tourTontineFinishedMessage =>
      'Every turn has been paid out. Well done!';

  @override
  String tourCurrentOverline(int position) {
    return 'TURN $position · IN PROGRESS';
  }

  @override
  String tourReceives(String amount, String date, String relative) {
    return 'Receives $amount · $date ($relative)';
  }

  @override
  String tourCollectedOf(String amount) {
    return 'collected out of $amount';
  }

  @override
  String get tourSeeCollection => 'View collection';

  @override
  String get tourCollect => 'Collect contributions';

  @override
  String percentValue(int value) {
    return '$value%';
  }

  @override
  String statsActiveMembers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Active members',
      one: 'Active member',
      zero: 'Active member',
    );
    return '$_temp0';
  }

  @override
  String get statsNamesAssigned => 'Names assigned';

  @override
  String get statsTurnsPaid => 'Turns paid out';

  @override
  String get statsOnTimeLate => 'On time / late';

  @override
  String bannerPendingDeclarations(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count payment declarations to review',
      one: '1 payment declaration to review',
    );
    return '$_temp0';
  }

  @override
  String get bannerCheckProofs => 'Check the proofs to approve the payments.';

  @override
  String get settingsSignOutTitle => 'Sign out?';

  @override
  String get settingsSignOutMessage =>
      'You\'ll need to sign in again to access your tontine.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSectionGroup => 'Group';

  @override
  String get settingsTontineSettings => 'Tontine settings';

  @override
  String get settingsTontineSettingsAdmin =>
      'Name, amount, penalty, number of names';

  @override
  String get settingsTontineSettingsMember => 'View (read-only)';

  @override
  String get settingsSectionAccount => 'Account';

  @override
  String get settingsMyProfile => 'My profile';

  @override
  String get settingsMyProfileAdmin =>
      'Your contact details and invitation code';

  @override
  String get settingsMyProfileMember =>
      'Your names, contributions and declarations';

  @override
  String get settingsSectionPreferences => 'Preferences';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageSystem => 'Phone language';

  @override
  String get languageFrench => 'Français';

  @override
  String get languageEnglish => 'English';

  @override
  String namesCountWhole(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count names',
      one: '1 name',
      zero: '0 names',
    );
    return '$_temp0';
  }

  @override
  String get namesCountHalfOnly => '½ name';

  @override
  String namesCountWithHalf(int count) {
    return '$count½ names';
  }

  @override
  String get namesRemoveHalf => 'Remove a half';

  @override
  String get namesAddHalf => 'Add a half';

  @override
  String get membersTitle => 'Members';

  @override
  String membersTabNames(int count) {
    return 'Names ($count)';
  }

  @override
  String membersTabMembers(int count) {
    return 'Members ($count)';
  }

  @override
  String get commonAdd => 'Add';

  @override
  String get membersLoadError => 'Couldn\'t load the members.';

  @override
  String get membersSectionNames => 'Names';

  @override
  String get membersAssign => 'Assign';

  @override
  String get membersNoNamesYet =>
      'No names have been created yet. Assign the first one to get started.';

  @override
  String get membersAssignName => 'Assign a name';

  @override
  String get membersGenerateSchedule => 'Generate the schedule';

  @override
  String membersNamesLeftBeforeSchedule(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count more names to assign before you can generate the schedule.',
      one: '1 more name to assign before you can generate the schedule.',
    );
    return '$_temp0';
  }

  @override
  String membersActiveSection(int count) {
    return 'Active members ($count)';
  }

  @override
  String get membersNoActive => 'No active members yet.';

  @override
  String membersInactiveSection(int count) {
    return 'Deactivated members ($count)';
  }

  @override
  String get unknownMember => 'Unknown member';

  @override
  String get membersNoHolder => 'No holder';

  @override
  String get membersToComplete => 'Incomplete';

  @override
  String get membersNoContact => 'No contact';

  @override
  String get membersPending => 'Pending';

  @override
  String membersNamesAssignedOf(int total) {
    return '/$total names assigned';
  }

  @override
  String get membersComplete => 'Complete';

  @override
  String get addMemberCodeCopied => 'Code copied.';

  @override
  String get addMemberTitle => 'Add a member';

  @override
  String get addMemberSubmit => 'Add and generate the code';

  @override
  String addMemberAddedFlash(String name) {
    return '$name has been added to the tontine.';
  }

  @override
  String addMemberAddedTitle(String name) {
    return '$name has been added';
  }

  @override
  String get addMemberNoNamesYet => 'No name assigned yet.';

  @override
  String addMemberWithNames(String names) {
    return 'With $names.';
  }

  @override
  String get addMemberShareCode =>
      'Share this code with them so they can join the tontine.';

  @override
  String get addMemberInviteCodeOverline => 'INVITATION CODE';

  @override
  String addMemberInviteCodeSemantics(String code) {
    return 'Invitation code $code';
  }

  @override
  String get addMemberCopyCode => 'Copy the code';

  @override
  String get commonDone => 'Done';

  @override
  String get profileContactUpdated => 'Contact details updated.';

  @override
  String profileDeactivateTitle(String name) {
    return 'Deactivate $name?';
  }

  @override
  String get profileDeactivateMessage =>
      'This member will no longer appear among active members. You can reactivate them at any time.';

  @override
  String get profileDeactivate => 'Deactivate';

  @override
  String profileDeactivated(String name) {
    return '$name has been deactivated.';
  }

  @override
  String profileReactivated(String name) {
    return '$name has been reactivated.';
  }

  @override
  String profileNamesAssigned(String names, String name) {
    return '$names assigned to $name.';
  }

  @override
  String get profileLoadError => 'Couldn\'t load this member.';

  @override
  String get profileNotFound => 'This member can\'t be found.';

  @override
  String get profileEditContact => 'Edit contact details';

  @override
  String get commonSave => 'Save';

  @override
  String get contactWhatsApp => 'WhatsApp';

  @override
  String get profileNamesHeld => 'Names held';

  @override
  String get profileNoNamesYet => 'No names assigned yet.';

  @override
  String get profileDeactivateMember => 'Deactivate this member';

  @override
  String get profileReactivateMember => 'Reactivate this member';

  @override
  String get profileInviteCodeUsed => 'Invitation code (used)';

  @override
  String get profileInviteCode => 'Invitation code';

  @override
  String get profileRegistered => 'Registered';

  @override
  String profileShareCodeWith(String name) {
    return 'Share with $name so they can join the tontine.';
  }

  @override
  String get profileDuePerDueDate => 'DUE PER DUE DATE';

  @override
  String profileNamesHeldCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count names held',
      one: '1 name held',
    );
    return '$_temp0';
  }

  @override
  String get statusDeactivated => 'Deactivated';

  @override
  String get statusAwaitingSignup => 'Awaiting sign-up';

  @override
  String get statusActive => 'Active';

  @override
  String get profileAssignNamesTitle => 'Assign names';

  @override
  String profileAssignNamesQuestion(String name) {
    return 'How many more names for $name?';
  }

  @override
  String get memberFormContactRequired =>
      'Enter at least an email or a WhatsApp number.';

  @override
  String get memberFormFullName => 'Full name';

  @override
  String get memberFormNameTooShort =>
      'The name must be at least 2 characters.';

  @override
  String get memberFormWhatsApp => 'WhatsApp number';

  @override
  String get memberFormEmail => 'Email';

  @override
  String get memberFormOneContactRequired =>
      'At least one of the two contact methods is required.';

  @override
  String get memberFormHalfNamesHelp =>
      'A name can be split in halves between two members; a whole name belongs to them alone.';

  @override
  String errorNamesQuotaExceeded(int total) {
    return 'This would exceed the number of names planned for the tontine ($total).';
  }

  @override
  String defaultNameLabel(int position) {
    return 'Name $position';
  }

  @override
  String get assignSharesMustTotal100 => 'Shares must add up to 100%.';

  @override
  String get assignSharesSaved => 'Shares saved.';

  @override
  String get assignLoadNamesError => 'Couldn\'t load the names.';

  @override
  String get assignNameNotFound => 'This name can\'t be found.';

  @override
  String get assignNewName => 'New name';

  @override
  String get assignEditShares => 'Edit shares';

  @override
  String get assignAddActiveMembersFirst =>
      'Add active members first so you can assign them this name.';

  @override
  String get assignFrozen =>
      'Locked — the schedule has already started. Changing these shares would distort amounts already calculated.';

  @override
  String get partsHolders => 'Shareholders';

  @override
  String get partsSplitEqually => 'Split equally';

  @override
  String partsTotal(int percent) {
    return 'Total: $percent%';
  }

  @override
  String scheduleTabUpcoming(int count) {
    return 'Upcoming ($count)';
  }

  @override
  String scheduleTabHistory(int count) {
    return 'History ($count)';
  }

  @override
  String get scheduleLoadError => 'Couldn\'t load the schedule.';

  @override
  String get scheduleNoCalendarYet => 'No calendar yet';

  @override
  String get scheduleDragHint =>
      'Press and hold, then drag to change the order.';

  @override
  String get scheduleNoTurnPaid =>
      'No turns paid out yet. Turns will appear here once the pot is handed over.';

  @override
  String get reorderReasonRequired => 'Give the reason for this change.';

  @override
  String get reorderTitle => 'Move this turn';

  @override
  String get reorderExplanation =>
      'The following turns\' dates will be recalculated. Explain why the order is changing.';

  @override
  String get reorderHint => 'E.g. exceptional absence, member\'s request…';

  @override
  String get commonConfirm => 'Confirm';

  @override
  String get turnStatusUpcoming => 'Upcoming';

  @override
  String get turnStatusInProgress => 'In progress';

  @override
  String get turnStatusPaid => 'Paid out';

  @override
  String get turnStatusPostponed => 'Postponed';

  @override
  String get turnHistoryTitle => 'Turn history';

  @override
  String turnPositionChange(int from, int to) {
    return 'Position $from → $to';
  }

  @override
  String turnPaidOn(String date) {
    return 'Paid out on $date';
  }

  @override
  String turnPlannedOn(String date) {
    return 'Planned for $date';
  }

  @override
  String turnChangesSeeHistory(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count changes — see history',
      one: 'Moved — see history',
    );
    return '$_temp0';
  }

  @override
  String turnsPaidOf(int total) {
    return ' / $total turns paid out';
  }

  @override
  String get collectLoadError => 'Couldn\'t load the collection.';

  @override
  String get collectTurnNotFound => 'This turn can\'t be found.';

  @override
  String collectRecorded(String name) {
    return '$name\'s contribution recorded.';
  }

  @override
  String collectTitleAdmin(int position) {
    return 'Collection — Turn $position';
  }

  @override
  String collectTitleMember(int position) {
    return 'Turn $position — Contributions';
  }

  @override
  String collectTabToCollect(int count) {
    return 'To collect ($count)';
  }

  @override
  String collectTabSettled(int count) {
    return 'Settled ($count)';
  }

  @override
  String get collectNoHolders => 'No shareholders for this turn.';

  @override
  String get collectEveryonePaid => 'Everyone has paid for this turn.';

  @override
  String get collectNoPaymentsYet => 'No payments recorded yet.';

  @override
  String collectDueOverline(String date) {
    return 'DUE · $date';
  }

  @override
  String get collectComplete => 'Collection complete';

  @override
  String collectPeopleLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people left to collect',
      one: '1 person left to collect',
    );
    return '$_temp0';
  }

  @override
  String get statusUnpaid => 'Unpaid';

  @override
  String collectRemainingOf(String amount) {
    return 'balance on $amount';
  }

  @override
  String get contribInvalidAmount => 'Enter a valid amount paid.';

  @override
  String get contribAmountExceedsDue =>
      'The amount paid can\'t exceed the amount due.';

  @override
  String get contribMarkedOnTimeReason =>
      'Marked as on time by the administrator.';

  @override
  String contribAmountDue(String amount) {
    return 'Amount due: $amount';
  }

  @override
  String get contribAmountPaid => 'Amount paid';

  @override
  String get contribPaymentDate => 'Payment date';

  @override
  String get contribIsLate => 'Is this payment late?';

  @override
  String get contribOnTime => 'On time';

  @override
  String get contribPenaltyWaived => 'Penalty waived';

  @override
  String get contribPenaltyComputed => 'Calculated penalty';

  @override
  String get contribCancelWaiver => 'Undo waiver';

  @override
  String get contribWaivePenalty => 'Waive the penalty';

  @override
  String get contribSubmit => 'Record the contribution';

  @override
  String get declValidated => 'Declaration approved.';

  @override
  String get declRejected => 'Declaration rejected.';

  @override
  String get declTitle => 'Declaration';

  @override
  String get declLoadError => 'Couldn\'t load this declaration.';

  @override
  String get declNotFound => 'This declaration can\'t be found.';

  @override
  String turnLabel(int position) {
    return 'Turn $position';
  }

  @override
  String get declAmountDeclared => 'Amount declared';

  @override
  String declPaidOn(String date) {
    return 'Paid on $date';
  }

  @override
  String declRejectionReason(String reason) {
    return 'Reason for rejection: $reason';
  }

  @override
  String get declProofOfPayment => 'Proof of payment';

  @override
  String get declApprove => 'Approve the declaration';

  @override
  String get declReject => 'Reject';

  @override
  String get declNewDeclaration => 'Make a new declaration';

  @override
  String get declStatusPending => 'Pending';

  @override
  String get declStatusApproved => 'Approved';

  @override
  String get declStatusDisputed => 'Disputed';

  @override
  String get declProofLoadError => 'Couldn\'t load the proof.';

  @override
  String get declNoProof => 'No proof available.';

  @override
  String get declEnlargeProof => 'Enlarge the proof';

  @override
  String get declRejectReasonRequired => 'Give the reason for rejection.';

  @override
  String get declRejectTitle => 'Reject this declaration';

  @override
  String get declRejectHint => 'E.g. unreadable proof, wrong amount…';

  @override
  String get declListLoadError => 'Couldn\'t load the declarations.';

  @override
  String get declNone => 'No declarations';

  @override
  String get declNoneMessage =>
      'When a member reports a payment, their declaration and proof appear here.';

  @override
  String get unknownTurn => 'Unknown turn';

  @override
  String declGroupTitle(int position, String beneficiaries) {
    return 'Turn $position — $beneficiaries';
  }

  @override
  String declPendingOf(int pending, int total) {
    return '$pending pending of $total';
  }

  @override
  String declCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count declarations',
      one: '1 declaration',
    );
    return '$_temp0';
  }

  @override
  String get waiverReasonRequired => 'Give the reason for this exception.';

  @override
  String get waiverExplanation =>
      'The calculated late penalty won\'t be applied to this contribution. Explain why.';

  @override
  String get waiverHint => 'E.g. network outage reported in advance';

  @override
  String get proofImageError => 'Couldn\'t get the image. Please try again.';

  @override
  String get proofTakePhoto => 'Take a photo';

  @override
  String get proofChooseFromGallery => 'Choose from gallery';

  @override
  String get proofRequired => 'Proof (required)';

  @override
  String get proofOptional => 'Proof (optional)';

  @override
  String get proofRemove => 'Remove the proof';

  @override
  String get proofCompressing => 'Compressing…';

  @override
  String get proofAdd => 'Add a proof';

  @override
  String get memberSpaceTitle => 'My space';

  @override
  String get memberSpaceLoadError => 'Couldn\'t load your space.';

  @override
  String get memberSpaceNoMember =>
      'No member profile is linked to this account.';

  @override
  String get memberSpaceScheduleNotGenerated =>
      'The administrator hasn\'t generated the schedule yet.';

  @override
  String get memberSpaceAllTurnsPaid => 'Every turn has been paid out.';

  @override
  String get memberSpaceToPayThisTurn => 'To pay for this turn';

  @override
  String get memberSpaceMyDeclarations => 'My declarations';

  @override
  String memberSpaceDeclaredOn(String date) {
    return 'Declared on $date';
  }

  @override
  String get memberSpaceContributionHistory => 'Contribution history';

  @override
  String get declareInvalidAmount => 'Enter a valid amount.';

  @override
  String get declareAmountExceedsRemaining =>
      'The amount can\'t exceed what\'s still owed.';

  @override
  String get declareProofRequired =>
      'A proof is required to declare a payment.';

  @override
  String get declareSent =>
      'Declaration sent. Waiting for the administrator\'s approval.';

  @override
  String get declareTitle => 'I\'ve paid';

  @override
  String get declareNotAllowed =>
      'This name can no longer be declared for the current turn.';

  @override
  String declareRemaining(String amount) {
    return 'Still owed: $amount';
  }

  @override
  String get declareSubmit => 'Send the declaration';

  @override
  String get myNamesNoCurrentTurn => 'No turn in progress for your names.';

  @override
  String get myNamesDeclarationPending => 'Declaration pending';

  @override
  String get myNamesDeclarationDisputed => 'Declaration disputed';

  @override
  String myNamesShare(String fraction) {
    return 'Share: $fraction';
  }

  @override
  String get situationNoUpcomingTurn => 'No upcoming turn for your names.';

  @override
  String get situationYourNextTurn => 'Your next turn';

  @override
  String situationTurnLine(String name, int position, String relative) {
    return '$name · turn $position · $relative';
  }

  @override
  String get onboarding1Title => 'Your tontine,\nno notebook, no maths';

  @override
  String onboarding1Text(String appName) {
    return 'Members, names, shares and turn order: set the circle up once, then $appName keeps the calendar for you.';
  }

  @override
  String get onboarding2Title => 'Every franc,\ntracked live';

  @override
  String get onboarding2Text =>
      'See who has paid, who is late and how much is left to collect for the current turn. Penalties are calculated automatically.';

  @override
  String get onboarding3Title => 'Members declare,\nyou approve';

  @override
  String get onboarding3Text =>
      'Each member reports their payment with a proof, from their phone. The administrator checks and approves in one tap.';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingStart => 'Get started';

  @override
  String get onboardingHaveCode => 'I received an invitation code';

  @override
  String get onboardingCircleCaption => 'Turn 5 · Aïcha receives the pot';

  @override
  String get onboardingCollectOverline => 'COLLECTION · TURN 3';

  @override
  String get onboardingDeclaredPayment => 'declared a payment';

  @override
  String get onboardingMobileMoneyReceipt => 'Mobile Money receipt attached';
}
