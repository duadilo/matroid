// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Matroid';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsTooltip => 'Settings';

  @override
  String get navHome => 'Home';

  @override
  String get editorTitle => 'Editor';

  @override
  String get sectionAppearance => 'Appearance';

  @override
  String get themeLabel => 'Theme';

  @override
  String get themeDescription => 'Choose the app appearance';

  @override
  String get themeLight => 'Light';

  @override
  String get themeSystem => 'System';

  @override
  String get themeDark => 'Dark';

  @override
  String get sectionLanguage => 'Language';

  @override
  String get languageLabel => 'Language';

  @override
  String get languageDescription => 'Choose the app language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSpanish => 'Spanish';

  @override
  String get fallbackDialogTitle => 'Local server unavailable';

  @override
  String get fallbackDialogBody =>
      'The local Python server failed to handle this request. Would you like to fall back to the remote server instead?';

  @override
  String get buttonNo => 'No';

  @override
  String get buttonUseRemote => 'Use Remote';

  @override
  String get buttonRetry => 'Retry';

  @override
  String get buttonRetryLocal => 'Retry Local';

  @override
  String get statusStartingServer => 'Starting local server…';

  @override
  String statusRetrying(int attempt, int max) {
    return 'Retrying… (attempt $attempt of $max)';
  }

  @override
  String statusServerFailed(int max, String error) {
    return 'Local server failed after $max attempts: $error';
  }

  @override
  String get featuresDisabledMessage =>
      'Excel features disabled — local server failed and remote fallback was declined.';

  @override
  String get buttonLoadFile => 'Load File';

  @override
  String get buttonProcess => 'Process';

  @override
  String get buttonExport => 'Export';

  @override
  String get buttonUnload => 'Unload';

  @override
  String statusLoadingFile(String fileName) {
    return 'Loading $fileName…';
  }

  @override
  String statusLoaded(String fileName) {
    return 'Loaded: $fileName';
  }

  @override
  String statusLoadError(String error) {
    return 'Load error: $error';
  }

  @override
  String get statusProcessing => 'Processing…';

  @override
  String statusProcessResult(String result) {
    return 'Process result: $result';
  }

  @override
  String statusProcessError(String error) {
    return 'Process error: $error';
  }

  @override
  String get statusExporting => 'Exporting…';

  @override
  String statusExported(int bytes) {
    return 'Exported $bytes bytes.';
  }

  @override
  String statusExportError(String error) {
    return 'Export error: $error';
  }

  @override
  String get statusUnloadSent => 'Unload sent (fire-and-forget).';

  @override
  String modeLabel(String mode) {
    return 'Mode: $mode';
  }

  @override
  String get markdownTitle => 'Markdown';

  @override
  String get latexTitle => 'Math';

  @override
  String get buttonExportPdf => 'Export PDF';

  @override
  String get buttonExportHtml => 'Export HTML';

  @override
  String get chartsTitle => 'Charts';

  @override
  String get fontLabel => 'Font';

  @override
  String get fontDescription => 'Choose the app typeface';

  @override
  String get fontDefault => 'Default';

  @override
  String get fontOpenDyslexic => 'OpenDyslexic';

  @override
  String get fontLexend => 'Lexend';

  @override
  String get mediaTitle => 'Media';

  @override
  String get buttonPickImage => 'Pick Image';

  @override
  String get buttonPickVideo => 'Pick Video';

  @override
  String get buttonTakePhoto => 'Take Photo';

  @override
  String get buttonRecordVideo => 'Record Video';

  @override
  String get mediaCameraUnavailable => 'Camera not available on this platform';

  @override
  String get mediaEmptyState =>
      'No media selected. Use the toolbar buttons to pick or capture media.';

  @override
  String get chatTitle => 'Chat';

  @override
  String get chatEmptyState =>
      'Select a provider and model, then start a conversation.';

  @override
  String get chatInputHint => 'Message…';

  @override
  String get chatNewConversation => 'New conversation';

  @override
  String get chatSend => 'Send';

  @override
  String get chatAttach => 'Attach file';

  @override
  String get chatToggleMarkdown => 'Toggle markdown';

  @override
  String chatErrorPrefix(String error) {
    return 'Error: $error';
  }

  @override
  String get chatNoProviders =>
      'No providers configured. Set API keys in Settings or as server environment variables.';

  @override
  String get chatSystemPrompt => 'System prompt';

  @override
  String get sectionApiKeys => 'API Keys';

  @override
  String get apiKeyOpenai => 'OpenAI API Key';

  @override
  String get apiKeyAnthropic => 'Anthropic API Key';

  @override
  String get apiKeyGoogle => 'Google AI API Key';

  @override
  String get apiKeySaved => 'Saved';

  @override
  String get apiKeyHint => 'Enter API key…';

  @override
  String get chatToolsEnabled => 'Web search enabled';

  @override
  String get chatToolsDisabled => 'Web search disabled';

  @override
  String chatSearching(String query) {
    return 'Searching: $query';
  }

  @override
  String chatSearched(String query) {
    return 'Searched: $query';
  }
}
