import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

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
    Locale('en'),
    Locale('vi'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Cosmic Wish'**
  String get appTitle;

  /// No description provided for @homeTagline.
  ///
  /// In en, this message translates to:
  /// **'Send your wish, the universe will listen'**
  String get homeTagline;

  /// No description provided for @startButton.
  ///
  /// In en, this message translates to:
  /// **'BEGIN'**
  String get startButton;

  /// No description provided for @selectCategory.
  ///
  /// In en, this message translates to:
  /// **'Choose a domain'**
  String get selectCategory;

  /// No description provided for @selectCategoryHint.
  ///
  /// In en, this message translates to:
  /// **'What is your wish about?'**
  String get selectCategoryHint;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'CONTINUE'**
  String get continueButton;

  /// No description provided for @centerYourself.
  ///
  /// In en, this message translates to:
  /// **'Center yourself'**
  String get centerYourself;

  /// No description provided for @universeListens.
  ///
  /// In en, this message translates to:
  /// **'The universe is listening...'**
  String get universeListens;

  /// No description provided for @speakYourWish.
  ///
  /// In en, this message translates to:
  /// **'Speak your wish'**
  String get speakYourWish;

  /// No description provided for @sendingToUniverse.
  ///
  /// In en, this message translates to:
  /// **'Sending to the universe...'**
  String get sendingToUniverse;

  /// No description provided for @wishEngraved.
  ///
  /// In en, this message translates to:
  /// **'Your wish has been engraved into the universe'**
  String get wishEngraved;

  /// No description provided for @returnHome.
  ///
  /// In en, this message translates to:
  /// **'RETURN'**
  String get returnHome;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'Wish journey'**
  String get history;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @noWishesYet.
  ///
  /// In en, this message translates to:
  /// **'No wishes yet'**
  String get noWishesYet;

  /// No description provided for @beginYourJourney.
  ///
  /// In en, this message translates to:
  /// **'Begin your journey...'**
  String get beginYourJourney;

  /// No description provided for @yourWish.
  ///
  /// In en, this message translates to:
  /// **'Your wish:'**
  String get yourWish;

  /// No description provided for @deleteAllConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete all?'**
  String get deleteAllConfirm;

  /// No description provided for @deleteAllMessage.
  ///
  /// In en, this message translates to:
  /// **'Your wish journey will be permanently deleted.'**
  String get deleteAllMessage;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @soundEffects.
  ///
  /// In en, this message translates to:
  /// **'Sound'**
  String get soundEffects;

  /// No description provided for @soundEffectsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Ambient music and effects'**
  String get soundEffectsSubtitle;

  /// No description provided for @haptics.
  ///
  /// In en, this message translates to:
  /// **'Haptic feedback'**
  String get haptics;

  /// No description provided for @hapticsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Subtle vibration on interaction'**
  String get hapticsSubtitle;

  /// No description provided for @effects.
  ///
  /// In en, this message translates to:
  /// **'Effects'**
  String get effects;

  /// No description provided for @starDensity.
  ///
  /// In en, this message translates to:
  /// **'Star density'**
  String get starDensity;

  /// No description provided for @animationSpeed.
  ///
  /// In en, this message translates to:
  /// **'Animation speed'**
  String get animationSpeed;

  /// No description provided for @reminder.
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get reminder;

  /// No description provided for @dailyReminder.
  ///
  /// In en, this message translates to:
  /// **'Daily reminder'**
  String get dailyReminder;

  /// No description provided for @dailyReminderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Notify daily to remind you of your wish'**
  String get dailyReminderSubtitle;

  /// No description provided for @reminderTime.
  ///
  /// In en, this message translates to:
  /// **'Reminder time'**
  String get reminderTime;

  /// No description provided for @info.
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get info;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @aiModel.
  ///
  /// In en, this message translates to:
  /// **'AI Model'**
  String get aiModel;

  /// No description provided for @purpose.
  ///
  /// In en, this message translates to:
  /// **'Purpose'**
  String get purpose;

  /// No description provided for @purposeValue.
  ///
  /// In en, this message translates to:
  /// **'Spiritual experience'**
  String get purposeValue;

  /// No description provided for @footer.
  ///
  /// In en, this message translates to:
  /// **'Cosmic Wish · send wishes to the universe'**
  String get footer;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get languageSystem;

  /// No description provided for @languageSystemSub.
  ///
  /// In en, this message translates to:
  /// **'Follow device'**
  String get languageSystemSub;

  /// No description provided for @languageVietnamese.
  ///
  /// In en, this message translates to:
  /// **'Tiếng Việt'**
  String get languageVietnamese;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @importFile.
  ///
  /// In en, this message translates to:
  /// **'Import from file'**
  String get importFile;

  /// No description provided for @exportFile.
  ///
  /// In en, this message translates to:
  /// **'Export to file'**
  String get exportFile;

  /// No description provided for @deleteAll.
  ///
  /// In en, this message translates to:
  /// **'Delete all'**
  String get deleteAll;

  /// No description provided for @sendWish.
  ///
  /// In en, this message translates to:
  /// **'Send your wish'**
  String get sendWish;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @wishDetail.
  ///
  /// In en, this message translates to:
  /// **'Wish detail'**
  String get wishDetail;

  /// No description provided for @imported.
  ///
  /// In en, this message translates to:
  /// **'Imported {count} wishes'**
  String imported(int count);

  /// No description provided for @noNewData.
  ///
  /// In en, this message translates to:
  /// **'No new data'**
  String get noNewData;

  /// No description provided for @ready.
  ///
  /// In en, this message translates to:
  /// **'READY'**
  String get ready;

  /// No description provided for @readySemantic.
  ///
  /// In en, this message translates to:
  /// **'I\'m ready, continue'**
  String get readySemantic;

  /// No description provided for @wishWillRespond.
  ///
  /// In en, this message translates to:
  /// **'The universe will respond in {time}'**
  String wishWillRespond(String time);

  /// No description provided for @wishResponded.
  ///
  /// In en, this message translates to:
  /// **'The universe has responded'**
  String get wishResponded;

  /// No description provided for @wishHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get wishHistory;

  /// No description provided for @historyTooltip.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historyTooltip;

  /// No description provided for @settingsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTooltip;

  /// No description provided for @selectCategoryHeader.
  ///
  /// In en, this message translates to:
  /// **'Choose a domain'**
  String get selectCategoryHeader;

  /// No description provided for @selectCategorySub.
  ///
  /// In en, this message translates to:
  /// **'What is your wish about?'**
  String get selectCategorySub;

  /// No description provided for @centerYourselfHeader.
  ///
  /// In en, this message translates to:
  /// **'Center yourself'**
  String get centerYourselfHeader;

  /// No description provided for @universeListensSub.
  ///
  /// In en, this message translates to:
  /// **'The universe is listening'**
  String get universeListensSub;

  /// No description provided for @enterWishEmpty.
  ///
  /// In en, this message translates to:
  /// **'Please enter your wish.'**
  String get enterWishEmpty;

  /// No description provided for @tapToWriteWish.
  ///
  /// In en, this message translates to:
  /// **'Tap to write your wish...'**
  String get tapToWriteWish;

  /// No description provided for @sendWishButton.
  ///
  /// In en, this message translates to:
  /// **'SEND YOUR WISH'**
  String get sendWishButton;

  /// No description provided for @cameraPermissionNeeded.
  ///
  /// In en, this message translates to:
  /// **'Camera access is off. You can still type and send your wish.'**
  String get cameraPermissionNeeded;

  /// No description provided for @noCameraFound.
  ///
  /// In en, this message translates to:
  /// **'This device has no camera.'**
  String get noCameraFound;

  /// No description provided for @cameraOpenError.
  ///
  /// In en, this message translates to:
  /// **'Could not open the camera.'**
  String get cameraOpenError;

  /// No description provided for @permissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Permission required'**
  String get permissionRequired;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'OPEN SETTINGS'**
  String get openSettings;

  /// No description provided for @openSettingsSemantic.
  ///
  /// In en, this message translates to:
  /// **'Open system settings'**
  String get openSettingsSemantic;

  /// No description provided for @errorPrefix.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String errorPrefix(String message);

  /// No description provided for @wishNotRecorded.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t said anything. Try again and speak your wish.'**
  String get wishNotRecorded;

  /// No description provided for @readySemantic2.
  ///
  /// In en, this message translates to:
  /// **'I\'m ready, continue'**
  String get readySemantic2;

  /// No description provided for @thinkingPrompt.
  ///
  /// In en, this message translates to:
  /// **'What are you thinking?'**
  String get thinkingPrompt;

  /// No description provided for @weavingProphecy.
  ///
  /// In en, this message translates to:
  /// **'Weaving the prophecy…'**
  String get weavingProphecy;

  /// No description provided for @starsAligning.
  ///
  /// In en, this message translates to:
  /// **'The stars are aligning'**
  String get starsAligning;

  /// No description provided for @almostThere.
  ///
  /// In en, this message translates to:
  /// **'Almost there…'**
  String get almostThere;

  /// No description provided for @wishEngravedHeader.
  ///
  /// In en, this message translates to:
  /// **'Your wish has been engraved into the universe'**
  String get wishEngravedHeader;

  /// No description provided for @notifResponseTitle.
  ///
  /// In en, this message translates to:
  /// **'The universe has answered'**
  String get notifResponseTitle;

  /// No description provided for @notifResponseBody.
  ///
  /// In en, this message translates to:
  /// **'Your wish is waiting to be heard... Open Cosmic Wish to see.'**
  String get notifResponseBody;

  /// No description provided for @notifFarewellTitle.
  ///
  /// In en, this message translates to:
  /// **'The universe has released your wish'**
  String get notifFarewellTitle;

  /// No description provided for @notifFarewellBody.
  ///
  /// In en, this message translates to:
  /// **'30 days have passed. The wish has dissolved into the cosmos. Send a new wish if you\'d like.'**
  String get notifFarewellBody;

  /// No description provided for @wishLabel.
  ///
  /// In en, this message translates to:
  /// **'Your wish:'**
  String get wishLabel;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} minutes ago'**
  String minutesAgo(int count);

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} hours ago'**
  String hoursAgo(int count);

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} days ago'**
  String daysAgo(int count);

  /// No description provided for @prophecy.
  ///
  /// In en, this message translates to:
  /// **'Prophecy'**
  String get prophecy;

  /// No description provided for @prophecySignsLabel.
  ///
  /// In en, this message translates to:
  /// **'Signs to watch'**
  String get prophecySignsLabel;

  /// No description provided for @prophecyActionLabel.
  ///
  /// In en, this message translates to:
  /// **'One small thing today'**
  String get prophecyActionLabel;

  /// No description provided for @prophecyAffirmationLabel.
  ///
  /// In en, this message translates to:
  /// **'Affirmation'**
  String get prophecyAffirmationLabel;

  /// No description provided for @reflectNow.
  ///
  /// In en, this message translates to:
  /// **'Reflect'**
  String get reflectNow;

  /// No description provided for @reflectTitle.
  ///
  /// In en, this message translates to:
  /// **'A few days have passed…'**
  String get reflectTitle;

  /// No description provided for @reflectNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Write what you noticed…'**
  String get reflectNoteHint;

  /// No description provided for @reflectMoodLabel.
  ///
  /// In en, this message translates to:
  /// **'How do you feel?'**
  String get reflectMoodLabel;

  /// No description provided for @reflectOutcomeLabel.
  ///
  /// In en, this message translates to:
  /// **'Is the wish coming true?'**
  String get reflectOutcomeLabel;

  /// No description provided for @reflectSave.
  ///
  /// In en, this message translates to:
  /// **'SAVE'**
  String get reflectSave;

  /// No description provided for @reflectSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get reflectSkip;

  /// No description provided for @reflectSaved.
  ///
  /// In en, this message translates to:
  /// **'Reflection saved'**
  String get reflectSaved;

  /// No description provided for @moodHopeful.
  ///
  /// In en, this message translates to:
  /// **'Hopeful'**
  String get moodHopeful;

  /// No description provided for @moodPeaceful.
  ///
  /// In en, this message translates to:
  /// **'Peaceful'**
  String get moodPeaceful;

  /// No description provided for @moodRestless.
  ///
  /// In en, this message translates to:
  /// **'Restless'**
  String get moodRestless;

  /// No description provided for @moodSad.
  ///
  /// In en, this message translates to:
  /// **'Sad'**
  String get moodSad;

  /// No description provided for @moodGrateful.
  ///
  /// In en, this message translates to:
  /// **'Grateful'**
  String get moodGrateful;

  /// No description provided for @outcomeFulfilled.
  ///
  /// In en, this message translates to:
  /// **'Yes, in its own way'**
  String get outcomeFulfilled;

  /// No description provided for @outcomePartial.
  ///
  /// In en, this message translates to:
  /// **'Partially'**
  String get outcomePartial;

  /// No description provided for @outcomeUnfulfilled.
  ///
  /// In en, this message translates to:
  /// **'Not yet'**
  String get outcomeUnfulfilled;

  /// No description provided for @journeyReflected.
  ///
  /// In en, this message translates to:
  /// **'Reflected'**
  String get journeyReflected;

  /// No description provided for @journeyPending.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get journeyPending;

  /// No description provided for @reflectedNudge.
  ///
  /// In en, this message translates to:
  /// **'{count} of your wishes are waiting for a quiet moment'**
  String reflectedNudge(int count);

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'OPEN'**
  String get open;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @categoryLove.
  ///
  /// In en, this message translates to:
  /// **'Love'**
  String get categoryLove;

  /// No description provided for @categoryCareer.
  ///
  /// In en, this message translates to:
  /// **'Career'**
  String get categoryCareer;

  /// No description provided for @categoryHealth.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get categoryHealth;

  /// No description provided for @categoryFamily.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get categoryFamily;

  /// No description provided for @categoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get categoryOther;

  /// No description provided for @categoryLoveDesc.
  ///
  /// In en, this message translates to:
  /// **'Love and relationships'**
  String get categoryLoveDesc;

  /// No description provided for @categoryCareerDesc.
  ///
  /// In en, this message translates to:
  /// **'Work and success'**
  String get categoryCareerDesc;

  /// No description provided for @categoryHealthDesc.
  ///
  /// In en, this message translates to:
  /// **'Physical and mental health'**
  String get categoryHealthDesc;

  /// No description provided for @categoryFamilyDesc.
  ///
  /// In en, this message translates to:
  /// **'Family and loved ones'**
  String get categoryFamilyDesc;

  /// No description provided for @categoryOtherDesc.
  ///
  /// In en, this message translates to:
  /// **'Other wishes in the universe'**
  String get categoryOtherDesc;

  /// No description provided for @aiReflectionEyebrow.
  ///
  /// In en, this message translates to:
  /// **'BEFORE THE UNIVERSE ANSWERS'**
  String get aiReflectionEyebrow;

  /// No description provided for @aiReflectionHint.
  ///
  /// In en, this message translates to:
  /// **'Write what first came to mind…'**
  String get aiReflectionHint;

  /// No description provided for @aiReflectionRequired.
  ///
  /// In en, this message translates to:
  /// **'Share one thought before continuing.'**
  String get aiReflectionRequired;

  /// No description provided for @aiReflectionCta.
  ///
  /// In en, this message translates to:
  /// **'HEAR THE PROPHECY'**
  String get aiReflectionCta;

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'PRIVACY'**
  String get privacy;

  /// No description provided for @shareAnonymousWishes.
  ///
  /// In en, this message translates to:
  /// **'Share wishes with the community'**
  String get shareAnonymousWishes;

  /// No description provided for @shareAnonymousWishesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'When enabled, new wishes are posted publicly without your identity'**
  String get shareAnonymousWishesSubtitle;

  /// No description provided for @adminLoginTitle.
  ///
  /// In en, this message translates to:
  /// **'Admin Gate'**
  String get adminLoginTitle;

  /// No description provided for @adminPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Admin password'**
  String get adminPasswordHint;

  /// No description provided for @adminLoginButton.
  ///
  /// In en, this message translates to:
  /// **'OPEN GATE'**
  String get adminLoginButton;

  /// No description provided for @adminLoginFailed.
  ///
  /// In en, this message translates to:
  /// **'Wrong password.'**
  String get adminLoginFailed;

  /// No description provided for @adminRateLimited.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Try again in 5 minutes.'**
  String get adminRateLimited;

  /// No description provided for @adminNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'No admin password set on the server.'**
  String get adminNotConfigured;

  /// No description provided for @adminTitle.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get adminTitle;

  /// No description provided for @adminMode.
  ///
  /// In en, this message translates to:
  /// **'Config source'**
  String get adminMode;

  /// No description provided for @adminModeDatabase.
  ///
  /// In en, this message translates to:
  /// **'Database · updated {time}'**
  String adminModeDatabase(Object time);

  /// No description provided for @adminModeFallback.
  ///
  /// In en, this message translates to:
  /// **'Server defaults (env)'**
  String get adminModeFallback;

  /// No description provided for @adminPreset.
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get adminPreset;

  /// No description provided for @adminPresetCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get adminPresetCustom;

  /// No description provided for @adminBaseUrl.
  ///
  /// In en, this message translates to:
  /// **'Base URL'**
  String get adminBaseUrl;

  /// No description provided for @adminModel.
  ///
  /// In en, this message translates to:
  /// **'Model name'**
  String get adminModel;

  /// No description provided for @adminApiKey.
  ///
  /// In en, this message translates to:
  /// **'API key'**
  String get adminApiKey;

  /// No description provided for @adminApiKeyKeep.
  ///
  /// In en, this message translates to:
  /// **'Leave blank to keep the current key ({masked})'**
  String adminApiKeyKeep(Object masked);

  /// No description provided for @adminApiKeyNone.
  ///
  /// In en, this message translates to:
  /// **'No key configured yet'**
  String get adminApiKeyNone;

  /// No description provided for @adminTestConnection.
  ///
  /// In en, this message translates to:
  /// **'TEST CONNECTION'**
  String get adminTestConnection;

  /// No description provided for @adminTesting.
  ///
  /// In en, this message translates to:
  /// **'Testing…'**
  String get adminTesting;

  /// No description provided for @adminTestOk.
  ///
  /// In en, this message translates to:
  /// **'Connected · {latency} ms'**
  String adminTestOk(Object latency);

  /// No description provided for @adminTestFailed.
  ///
  /// In en, this message translates to:
  /// **'Connection failed'**
  String get adminTestFailed;

  /// No description provided for @adminSave.
  ///
  /// In en, this message translates to:
  /// **'SAVE CONFIG'**
  String get adminSave;

  /// No description provided for @adminSaved.
  ///
  /// In en, this message translates to:
  /// **'Configuration saved'**
  String get adminSaved;

  /// No description provided for @adminReset.
  ///
  /// In en, this message translates to:
  /// **'Back to server defaults'**
  String get adminReset;

  /// No description provided for @adminResetConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete configuration?'**
  String get adminResetConfirmTitle;

  /// No description provided for @adminResetConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Return to the server default configuration (env secret).'**
  String get adminResetConfirmMessage;

  /// No description provided for @adminNetworkError.
  ///
  /// In en, this message translates to:
  /// **'Network error. Check your connection and try again.'**
  String get adminNetworkError;

  /// No description provided for @adminSessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Session expired. Log in again.'**
  String get adminSessionExpired;

  /// No description provided for @updateAvailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Version {version} is available'**
  String updateAvailableTitle(String version);

  /// No description provided for @updateWhatsNew.
  ///
  /// In en, this message translates to:
  /// **'What\'s new'**
  String get updateWhatsNew;

  /// No description provided for @updateNow.
  ///
  /// In en, this message translates to:
  /// **'UPDATE NOW'**
  String get updateNow;

  /// No description provided for @updateLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get updateLater;

  /// No description provided for @updateSkipVersion.
  ///
  /// In en, this message translates to:
  /// **'Skip this version'**
  String get updateSkipVersion;

  /// No description provided for @updateDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading… {percent}%'**
  String updateDownloading(int percent);

  /// No description provided for @updateInstallConsent.
  ///
  /// In en, this message translates to:
  /// **'Android will ask to let Cosmic Wish install updates. Allow it once — the update then installs by itself.'**
  String get updateInstallConsent;

  /// No description provided for @updateFailed.
  ///
  /// In en, this message translates to:
  /// **'Download failed. Check your connection and try again.'**
  String get updateFailed;

  /// No description provided for @updateRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get updateRetry;

  /// No description provided for @updateUpToDate.
  ///
  /// In en, this message translates to:
  /// **'You\'re on the latest version.'**
  String get updateUpToDate;

  /// No description provided for @updateCheckButton.
  ///
  /// In en, this message translates to:
  /// **'Check for updates'**
  String get updateCheckButton;
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
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
