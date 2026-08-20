// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Cosmic Wish';

  @override
  String get homeTagline => 'Send your wish, the universe will listen';

  @override
  String get startButton => 'BEGIN';

  @override
  String get selectCategory => 'Choose a domain';

  @override
  String get selectCategoryHint => 'What is your wish about?';

  @override
  String get continueButton => 'CONTINUE';

  @override
  String get centerYourself => 'Center yourself';

  @override
  String get universeListens => 'The universe is listening...';

  @override
  String get speakYourWish => 'Speak your wish';

  @override
  String get sendingToUniverse => 'Sending to the universe...';

  @override
  String get wishEngraved => 'Your wish has been engraved into the universe';

  @override
  String get returnHome => 'RETURN';

  @override
  String get history => 'Wish journey';

  @override
  String get settings => 'Settings';

  @override
  String get noWishesYet => 'No wishes yet';

  @override
  String get beginYourJourney => 'Begin your journey...';

  @override
  String get yourWish => 'Your wish:';

  @override
  String get deleteAllConfirm => 'Delete all?';

  @override
  String get deleteAllMessage =>
      'Your wish journey will be permanently deleted.';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get soundEffects => 'Sound';

  @override
  String get soundEffectsSubtitle => 'Ambient music and effects';

  @override
  String get haptics => 'Haptic feedback';

  @override
  String get hapticsSubtitle => 'Subtle vibration on interaction';

  @override
  String get effects => 'Effects';

  @override
  String get starDensity => 'Star density';

  @override
  String get animationSpeed => 'Animation speed';

  @override
  String get reminder => 'Reminder';

  @override
  String get dailyReminder => 'Daily reminder';

  @override
  String get dailyReminderSubtitle => 'Notify daily to remind you of your wish';

  @override
  String get reminderTime => 'Reminder time';

  @override
  String get info => 'Information';

  @override
  String get version => 'Version';

  @override
  String get aiModel => 'AI Model';

  @override
  String get purpose => 'Purpose';

  @override
  String get purposeValue => 'Spiritual experience';

  @override
  String get footer => 'Cosmic Wish · send wishes to the universe';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'System';

  @override
  String get languageSystemSub => 'Follow device';

  @override
  String get languageVietnamese => 'Tiếng Việt';

  @override
  String get languageEnglish => 'English';

  @override
  String get back => 'Back';

  @override
  String get importFile => 'Import from file';

  @override
  String get exportFile => 'Export to file';

  @override
  String get deleteAll => 'Delete all';

  @override
  String get sendWish => 'Send your wish';

  @override
  String get close => 'Close';

  @override
  String get wishDetail => 'Wish detail';

  @override
  String imported(int count) {
    return 'Imported $count wishes';
  }

  @override
  String get noNewData => 'No new data';

  @override
  String get ready => 'READY';

  @override
  String get readySemantic => 'I\'m ready, continue';

  @override
  String wishWillRespond(String time) {
    return 'The universe will respond in $time';
  }

  @override
  String get wishResponded => 'The universe has responded';

  @override
  String get wishHistory => 'History';

  @override
  String get historyTooltip => 'History';

  @override
  String get settingsTooltip => 'Settings';

  @override
  String get selectCategoryHeader => 'Choose a domain';

  @override
  String get selectCategorySub => 'What is your wish about?';

  @override
  String get centerYourselfHeader => 'Center yourself';

  @override
  String get universeListensSub => 'The universe is listening';

  @override
  String get enterWishEmpty => 'Please enter your wish.';

  @override
  String get tapToWriteWish => 'Tap to write your wish...';

  @override
  String get sendWishButton => 'SEND YOUR WISH';

  @override
  String get cameraPermissionNeeded =>
      'Camera access is off. You can still type and send your wish.';

  @override
  String get noCameraFound => 'This device has no camera.';

  @override
  String get cameraOpenError => 'Could not open the camera.';

  @override
  String get permissionRequired => 'Permission required';

  @override
  String get openSettings => 'OPEN SETTINGS';

  @override
  String get openSettingsSemantic => 'Open system settings';

  @override
  String errorPrefix(String message) {
    return 'Error: $message';
  }

  @override
  String get wishNotRecorded =>
      'You haven\'t said anything. Try again and speak your wish.';

  @override
  String get readySemantic2 => 'I\'m ready, continue';

  @override
  String get thinkingPrompt => 'What are you thinking?';

  @override
  String get weavingProphecy => 'Weaving the prophecy…';

  @override
  String get starsAligning => 'The stars are aligning';

  @override
  String get almostThere => 'Almost there…';

  @override
  String get wishEngravedHeader =>
      'Your wish has been engraved into the universe';

  @override
  String get notifResponseTitle => 'The universe has answered';

  @override
  String get notifResponseBody =>
      'Your wish is waiting to be heard... Open Cosmic Wish to see.';

  @override
  String get notifFarewellTitle => 'The universe has released your wish';

  @override
  String get notifFarewellBody =>
      '30 days have passed. The wish has dissolved into the cosmos. Send a new wish if you\'d like.';

  @override
  String get wishLabel => 'Your wish:';

  @override
  String get justNow => 'Just now';

  @override
  String minutesAgo(int count) {
    return '$count minutes ago';
  }

  @override
  String hoursAgo(int count) {
    return '$count hours ago';
  }

  @override
  String daysAgo(int count) {
    return '$count days ago';
  }

  @override
  String get prophecy => 'Prophecy';

  @override
  String get prophecySignsLabel => 'Signs to watch';

  @override
  String get prophecyActionLabel => 'One small thing today';

  @override
  String get prophecyAffirmationLabel => 'Affirmation';

  @override
  String get reflectNow => 'Reflect';

  @override
  String get reflectTitle => 'A few days have passed…';

  @override
  String get reflectNoteHint => 'Write what you noticed…';

  @override
  String get reflectMoodLabel => 'How do you feel?';

  @override
  String get reflectOutcomeLabel => 'Is the wish coming true?';

  @override
  String get reflectSave => 'SAVE';

  @override
  String get reflectSkip => 'Skip for now';

  @override
  String get reflectSaved => 'Reflection saved';

  @override
  String get moodHopeful => 'Hopeful';

  @override
  String get moodPeaceful => 'Peaceful';

  @override
  String get moodRestless => 'Restless';

  @override
  String get moodSad => 'Sad';

  @override
  String get moodGrateful => 'Grateful';

  @override
  String get outcomeFulfilled => 'Yes, in its own way';

  @override
  String get outcomePartial => 'Partially';

  @override
  String get outcomeUnfulfilled => 'Not yet';

  @override
  String get journeyReflected => 'Reflected';

  @override
  String get journeyPending => 'Waiting';

  @override
  String reflectedNudge(int count) {
    return '$count of your wishes are waiting for a quiet moment';
  }

  @override
  String get open => 'OPEN';

  @override
  String get tryAgain => 'Try again';

  @override
  String get categoryLove => 'Love';

  @override
  String get categoryCareer => 'Career';

  @override
  String get categoryHealth => 'Health';

  @override
  String get categoryFamily => 'Family';

  @override
  String get categoryOther => 'Other';

  @override
  String get categoryLoveDesc => 'Love and relationships';

  @override
  String get categoryCareerDesc => 'Work and success';

  @override
  String get categoryHealthDesc => 'Physical and mental health';

  @override
  String get categoryFamilyDesc => 'Family and loved ones';

  @override
  String get categoryOtherDesc => 'Other wishes in the universe';

  @override
  String get aiReflectionEyebrow => 'BEFORE THE UNIVERSE ANSWERS';

  @override
  String get aiReflectionHint => 'Write what first came to mind…';

  @override
  String get aiReflectionRequired => 'Share one thought before continuing.';

  @override
  String get aiReflectionCta => 'HEAR THE PROPHECY';

  @override
  String get privacy => 'PRIVACY';

  @override
  String get shareAnonymousWishes => 'Share wishes with the community';

  @override
  String get shareAnonymousWishesSubtitle =>
      'When enabled, new wishes are posted publicly without your identity';

  @override
  String get adminLoginTitle => 'Admin Gate';

  @override
  String get adminPasswordHint => 'Admin password';

  @override
  String get adminLoginButton => 'OPEN GATE';

  @override
  String get adminLoginFailed => 'Wrong password.';

  @override
  String get adminRateLimited => 'Too many attempts. Try again in 5 minutes.';

  @override
  String get adminNotConfigured => 'No admin password set on the server.';

  @override
  String get adminTitle => 'Admin';

  @override
  String get adminMode => 'Config source';

  @override
  String adminModeDatabase(Object time) {
    return 'Database · updated $time';
  }

  @override
  String get adminModeFallback => 'Server defaults (env)';

  @override
  String get adminPreset => 'Provider';

  @override
  String get adminPresetCustom => 'Custom';

  @override
  String get adminBaseUrl => 'Base URL';

  @override
  String get adminModel => 'Model name';

  @override
  String get adminApiKey => 'API key';

  @override
  String adminApiKeyKeep(Object masked) {
    return 'Leave blank to keep the current key ($masked)';
  }

  @override
  String get adminApiKeyNone => 'No key configured yet';

  @override
  String get adminTestConnection => 'TEST CONNECTION';

  @override
  String get adminTesting => 'Testing…';

  @override
  String adminTestOk(Object latency) {
    return 'Connected · $latency ms';
  }

  @override
  String get adminTestFailed => 'Connection failed';

  @override
  String get adminSave => 'SAVE CONFIG';

  @override
  String get adminSaved => 'Configuration saved';

  @override
  String get adminReset => 'Back to server defaults';

  @override
  String get adminResetConfirmTitle => 'Delete configuration?';

  @override
  String get adminResetConfirmMessage =>
      'Return to the server default configuration (env secret).';

  @override
  String get adminNetworkError =>
      'Network error. Check your connection and try again.';

  @override
  String get adminSessionExpired => 'Session expired. Log in again.';

  @override
  String updateAvailableTitle(String version) {
    return 'Version $version is available';
  }

  @override
  String get updateWhatsNew => 'What\'s new';

  @override
  String get updateNow => 'UPDATE NOW';

  @override
  String get updateLater => 'Later';

  @override
  String get updateSkipVersion => 'Skip this version';

  @override
  String updateDownloading(int percent) {
    return 'Downloading… $percent%';
  }

  @override
  String get updateInstallConsent =>
      'Android will ask to let Cosmic Wish install updates. Allow it once — the update then installs by itself.';

  @override
  String get updateFailed =>
      'Download failed. Check your connection and try again.';

  @override
  String get updateRetry => 'Retry';

  @override
  String get updateUpToDate => 'You\'re on the latest version.';

  @override
  String get updateCheckButton => 'Check for updates';
}
