import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppFont { system, openDyslexic, lexend }

/// Global user-editable settings, persisted via [SharedPreferences].
///
/// Access the singleton via [AppSettings.instance].
/// Call [load] once in [main] after [WidgetsFlutterBinding.ensureInitialized].
class AppSettings {
  AppSettings._();

  static final instance = AppSettings._();

  // ---------------------------------------------------------------------------
  // Observable values
  // ---------------------------------------------------------------------------

  final themeMode = ValueNotifier<ThemeMode>(ThemeMode.system);
  final locale = ValueNotifier<Locale>(const Locale('en'));
  final fontFamily = ValueNotifier<AppFont>(AppFont.system);
  final openaiApiKey = ValueNotifier<String>('');
  final anthropicApiKey = ValueNotifier<String>('');
  final googleApiKey = ValueNotifier<String>('');

  /// Whether the floating server-console panel is visible. Not persisted.
  final consoleVisible = ValueNotifier<bool>(false);

  // ---------------------------------------------------------------------------
  // Persistence keys
  // ---------------------------------------------------------------------------

  static const _kThemeMode = 'settings.themeMode';
  static const _kLocale = 'settings.locale';
  static const _kFontFamily = 'settings.fontFamily';
  static const _kOpenaiApiKey = 'settings.openaiApiKey';
  static const _kAnthropicApiKey = 'settings.anthropicApiKey';
  static const _kGoogleApiKey = 'settings.googleApiKey';

  // ---------------------------------------------------------------------------
  // Load / save
  // ---------------------------------------------------------------------------

  /// Reads all settings from disk. Call once before [runApp].
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    themeMode.value = _parseThemeMode(prefs.getString(_kThemeMode));
    locale.value = _parseLocale(prefs.getString(_kLocale));
    fontFamily.value = _parseFont(prefs.getString(_kFontFamily));
    openaiApiKey.value = prefs.getString(_kOpenaiApiKey) ?? '';
    anthropicApiKey.value = prefs.getString(_kAnthropicApiKey) ?? '';
    googleApiKey.value = prefs.getString(_kGoogleApiKey) ?? '';
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode.value = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kThemeMode, mode.name);
  }

  Future<void> setLocale(Locale value) async {
    locale.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLocale, value.languageCode);
  }

  Future<void> setFontFamily(AppFont font) async {
    fontFamily.value = font;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kFontFamily, font.name);
  }

  Future<void> setApiKey(String provider, String value) async {
    final prefs = await SharedPreferences.getInstance();
    switch (provider) {
      case 'openai':
        openaiApiKey.value = value;
        await prefs.setString(_kOpenaiApiKey, value);
      case 'anthropic':
        anthropicApiKey.value = value;
        await prefs.setString(_kAnthropicApiKey, value);
      case 'google':
        googleApiKey.value = value;
        await prefs.setString(_kGoogleApiKey, value);
    }
  }

  /// Monospace font family to use in editors and console output.
  /// Returns `'OpenDyslexicMono'` when [AppFont.openDyslexic] is active so
  /// that code areas match the user's dyslexia-friendly font choice.
  String? get monoFontFamily =>
      fontFamily.value == AppFont.openDyslexic ? 'OpenDyslexicMono' : null;

  /// Returns a map of non-empty API keys keyed by provider name.
  Map<String, String> get apiKeys {
    final keys = <String, String>{};
    if (openaiApiKey.value.isNotEmpty) keys['openai'] = openaiApiKey.value;
    if (anthropicApiKey.value.isNotEmpty) {
      keys['anthropic'] = anthropicApiKey.value;
    }
    if (googleApiKey.value.isNotEmpty) keys['gemini'] = googleApiKey.value;
    return keys;
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  static ThemeMode _parseThemeMode(String? raw) => switch (raw) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  static Locale _parseLocale(String? raw) => switch (raw) {
        'es' => const Locale('es'),
        _ => const Locale('en'),
      };

  static AppFont _parseFont(String? raw) => switch (raw) {
        'openDyslexic' => AppFont.openDyslexic,
        'lexend' => AppFont.lexend,
        _ => AppFont.system,
      };
}
