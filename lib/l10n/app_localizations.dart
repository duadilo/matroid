import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
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
    Locale('es'),
  ];

  /// Application title shown in the app bar and OS task switcher
  ///
  /// In en, this message translates to:
  /// **'Matroid'**
  String get appTitle;

  /// Title of the settings page
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Tooltip for the settings icon button
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTooltip;

  /// Navigation label for the Home destination
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// Title of the code editor page and nav destination label
  ///
  /// In en, this message translates to:
  /// **'Editor'**
  String get editorTitle;

  /// Settings section header for appearance options
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get sectionAppearance;

  /// Label for the theme setting row
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeLabel;

  /// Subtitle under the theme label
  ///
  /// In en, this message translates to:
  /// **'Choose the app appearance'**
  String get themeDescription;

  /// Light theme option
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// System/auto theme option
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// Dark theme option
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// Settings section header for language options
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get sectionLanguage;

  /// Label for the language setting row
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageLabel;

  /// Subtitle under the language label
  ///
  /// In en, this message translates to:
  /// **'Choose the app language'**
  String get languageDescription;

  /// English language option
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// Spanish language option
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get languageSpanish;

  /// Title of the remote-fallback confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Local server unavailable'**
  String get fallbackDialogTitle;

  /// Body of the remote-fallback confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'The local Python server failed to handle this request. Would you like to fall back to the remote server instead?'**
  String get fallbackDialogBody;

  /// Generic No button label
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get buttonNo;

  /// Button that switches the app to the remote server
  ///
  /// In en, this message translates to:
  /// **'Use Remote'**
  String get buttonUseRemote;

  /// Generic Retry button label
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get buttonRetry;

  /// Button that retries the local server connection
  ///
  /// In en, this message translates to:
  /// **'Retry Local'**
  String get buttonRetryLocal;

  /// Shown while the local Python server is starting
  ///
  /// In en, this message translates to:
  /// **'Starting local server…'**
  String get statusStartingServer;

  /// Shown while retrying the server connection
  ///
  /// In en, this message translates to:
  /// **'Retrying… (attempt {attempt} of {max})'**
  String statusRetrying(int attempt, int max);

  /// Banner shown when all server connection attempts have failed
  ///
  /// In en, this message translates to:
  /// **'Local server failed after {max} attempts: {error}'**
  String statusServerFailed(int max, String error);

  /// Banner shown when Excel features are disabled
  ///
  /// In en, this message translates to:
  /// **'Excel features disabled — local server failed and remote fallback was declined.'**
  String get featuresDisabledMessage;

  /// Button to pick and load an Excel file
  ///
  /// In en, this message translates to:
  /// **'Load File'**
  String get buttonLoadFile;

  /// Button to process the loaded file
  ///
  /// In en, this message translates to:
  /// **'Process'**
  String get buttonProcess;

  /// Button to export the processed workbook
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get buttonExport;

  /// Button to unload the current file
  ///
  /// In en, this message translates to:
  /// **'Unload'**
  String get buttonUnload;

  /// Status shown while loading a file
  ///
  /// In en, this message translates to:
  /// **'Loading {fileName}…'**
  String statusLoadingFile(String fileName);

  /// Status shown after a file is successfully loaded
  ///
  /// In en, this message translates to:
  /// **'Loaded: {fileName}'**
  String statusLoaded(String fileName);

  /// Status shown when file loading fails
  ///
  /// In en, this message translates to:
  /// **'Load error: {error}'**
  String statusLoadError(String error);

  /// Status shown while the file is being processed
  ///
  /// In en, this message translates to:
  /// **'Processing…'**
  String get statusProcessing;

  /// Status shown with the process result
  ///
  /// In en, this message translates to:
  /// **'Process result: {result}'**
  String statusProcessResult(String result);

  /// Status shown when processing fails
  ///
  /// In en, this message translates to:
  /// **'Process error: {error}'**
  String statusProcessError(String error);

  /// Status shown while exporting the workbook
  ///
  /// In en, this message translates to:
  /// **'Exporting…'**
  String get statusExporting;

  /// Status shown after a successful export
  ///
  /// In en, this message translates to:
  /// **'Exported {bytes} bytes.'**
  String statusExported(int bytes);

  /// Status shown when export fails
  ///
  /// In en, this message translates to:
  /// **'Export error: {error}'**
  String statusExportError(String error);

  /// Status shown after the unload request is sent
  ///
  /// In en, this message translates to:
  /// **'Unload sent (fire-and-forget).'**
  String get statusUnloadSent;

  /// Small label showing the current server mode
  ///
  /// In en, this message translates to:
  /// **'Mode: {mode}'**
  String modeLabel(String mode);

  /// Title of the Markdown editor/preview page
  ///
  /// In en, this message translates to:
  /// **'Markdown'**
  String get markdownTitle;

  /// Title of the LaTeX/Math editor/preview page
  ///
  /// In en, this message translates to:
  /// **'Math'**
  String get latexTitle;

  /// Button to export the current content as a PDF
  ///
  /// In en, this message translates to:
  /// **'Export PDF'**
  String get buttonExportPdf;

  /// Button to export the current content as HTML
  ///
  /// In en, this message translates to:
  /// **'Export HTML'**
  String get buttonExportHtml;

  /// Title of the charts page
  ///
  /// In en, this message translates to:
  /// **'Charts'**
  String get chartsTitle;

  /// Label for the font setting row
  ///
  /// In en, this message translates to:
  /// **'Font'**
  String get fontLabel;

  /// Subtitle under the font label
  ///
  /// In en, this message translates to:
  /// **'Choose the app typeface'**
  String get fontDescription;

  /// System/default font option
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get fontDefault;

  /// OpenDyslexic font option
  ///
  /// In en, this message translates to:
  /// **'OpenDyslexic'**
  String get fontOpenDyslexic;

  /// Lexend font option
  ///
  /// In en, this message translates to:
  /// **'Lexend'**
  String get fontLexend;

  /// Title of the media page and nav destination label
  ///
  /// In en, this message translates to:
  /// **'Media'**
  String get mediaTitle;

  /// Tooltip for the pick image button
  ///
  /// In en, this message translates to:
  /// **'Pick Image'**
  String get buttonPickImage;

  /// Tooltip for the pick video button
  ///
  /// In en, this message translates to:
  /// **'Pick Video'**
  String get buttonPickVideo;

  /// Tooltip for the take photo button
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get buttonTakePhoto;

  /// Tooltip for the record video button
  ///
  /// In en, this message translates to:
  /// **'Record Video'**
  String get buttonRecordVideo;

  /// Message shown when camera is not supported
  ///
  /// In en, this message translates to:
  /// **'Camera not available on this platform'**
  String get mediaCameraUnavailable;

  /// Message shown when no media items are loaded
  ///
  /// In en, this message translates to:
  /// **'No media selected. Use the toolbar buttons to pick or capture media.'**
  String get mediaEmptyState;

  /// Title of the chat page and nav destination label
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chatTitle;

  /// Message shown when no chat messages exist
  ///
  /// In en, this message translates to:
  /// **'Select a provider and model, then start a conversation.'**
  String get chatEmptyState;

  /// Hint text for the chat input field
  ///
  /// In en, this message translates to:
  /// **'Message…'**
  String get chatInputHint;

  /// Tooltip for the new conversation button
  ///
  /// In en, this message translates to:
  /// **'New conversation'**
  String get chatNewConversation;

  /// Tooltip for the send button
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get chatSend;

  /// Tooltip for the attach file button
  ///
  /// In en, this message translates to:
  /// **'Attach file'**
  String get chatAttach;

  /// Tooltip for the markdown toggle button
  ///
  /// In en, this message translates to:
  /// **'Toggle markdown'**
  String get chatToggleMarkdown;

  /// Prefix for chat error messages
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String chatErrorPrefix(String error);

  /// Message shown when no chat providers are available
  ///
  /// In en, this message translates to:
  /// **'No providers configured. Set API keys in Settings or as server environment variables.'**
  String get chatNoProviders;

  /// Label for the system prompt field
  ///
  /// In en, this message translates to:
  /// **'System prompt'**
  String get chatSystemPrompt;

  /// Settings section header for API keys
  ///
  /// In en, this message translates to:
  /// **'API Keys'**
  String get sectionApiKeys;

  /// Label for the OpenAI API key field
  ///
  /// In en, this message translates to:
  /// **'OpenAI API Key'**
  String get apiKeyOpenai;

  /// Label for the Anthropic API key field
  ///
  /// In en, this message translates to:
  /// **'Anthropic API Key'**
  String get apiKeyAnthropic;

  /// Label for the Google AI API key field
  ///
  /// In en, this message translates to:
  /// **'Google AI API Key'**
  String get apiKeyGoogle;

  /// Snackbar message when an API key is saved
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get apiKeySaved;

  /// Hint text for API key input fields
  ///
  /// In en, this message translates to:
  /// **'Enter API key…'**
  String get apiKeyHint;
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
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
