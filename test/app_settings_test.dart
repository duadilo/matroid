import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:matroid/app_settings.dart';

void main() {
  final settings = AppSettings.instance;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // Reset to defaults between tests.
    settings.themeMode.value = ThemeMode.system;
    settings.locale.value = const Locale('en');
    settings.fontFamily.value = AppFont.system;
  });

  // ---------------------------------------------------------------------------
  // Theme
  // ---------------------------------------------------------------------------

  group('AppSettings.load themeMode', () {
    test('defaults to system when no preference is saved', () async {
      await settings.load();
      expect(settings.themeMode.value, ThemeMode.system);
    });

    test('restores light theme', () async {
      SharedPreferences.setMockInitialValues({'settings.themeMode': 'light'});
      await settings.load();
      expect(settings.themeMode.value, ThemeMode.light);
    });

    test('restores dark theme', () async {
      SharedPreferences.setMockInitialValues({'settings.themeMode': 'dark'});
      await settings.load();
      expect(settings.themeMode.value, ThemeMode.dark);
    });

    test('falls back to system for an unknown value', () async {
      SharedPreferences.setMockInitialValues({'settings.themeMode': 'bogus'});
      await settings.load();
      expect(settings.themeMode.value, ThemeMode.system);
    });
  });

  group('AppSettings.setThemeMode', () {
    test('updates the ValueNotifier immediately', () async {
      await settings.setThemeMode(ThemeMode.dark);
      expect(settings.themeMode.value, ThemeMode.dark);
    });

    test('persists so a subsequent load returns the same value', () async {
      await settings.setThemeMode(ThemeMode.light);
      // Simulate fresh startup by resetting the notifier then reloading.
      settings.themeMode.value = ThemeMode.system;
      await settings.load();
      expect(settings.themeMode.value, ThemeMode.light);
    });

    test('notifier fires listeners on change', () async {
      int callCount = 0;
      settings.themeMode.addListener(() => callCount++);
      await settings.setThemeMode(ThemeMode.dark);
      await settings.setThemeMode(ThemeMode.light);
      expect(callCount, 2);
      settings.themeMode.removeListener(() {});
    });
  });

  // ---------------------------------------------------------------------------
  // Locale
  // ---------------------------------------------------------------------------

  group('AppSettings.load locale', () {
    test('defaults to English when no preference is saved', () async {
      await settings.load();
      expect(settings.locale.value, const Locale('en'));
    });

    test('restores Spanish locale', () async {
      SharedPreferences.setMockInitialValues({'settings.locale': 'es'});
      await settings.load();
      expect(settings.locale.value, const Locale('es'));
    });

    test('falls back to English for an unknown value', () async {
      SharedPreferences.setMockInitialValues({'settings.locale': 'bogus'});
      await settings.load();
      expect(settings.locale.value, const Locale('en'));
    });
  });

  group('AppSettings.setLocale', () {
    test('updates the ValueNotifier immediately', () async {
      await settings.setLocale(const Locale('es'));
      expect(settings.locale.value, const Locale('es'));
    });

    test('persists so a subsequent load returns the same value', () async {
      await settings.setLocale(const Locale('es'));
      settings.locale.value = const Locale('en');
      await settings.load();
      expect(settings.locale.value, const Locale('es'));
    });

    test('notifier fires listeners on change', () async {
      int callCount = 0;
      settings.locale.addListener(() => callCount++);
      await settings.setLocale(const Locale('es'));
      await settings.setLocale(const Locale('en'));
      expect(callCount, 2);
      settings.locale.removeListener(() {});
    });
  });

  // ---------------------------------------------------------------------------
  // Font family
  // ---------------------------------------------------------------------------

  group('AppSettings.load fontFamily', () {
    test('defaults to system when no preference is saved', () async {
      await settings.load();
      expect(settings.fontFamily.value, AppFont.system);
    });

    test('restores openDyslexic font', () async {
      SharedPreferences.setMockInitialValues(
          {'settings.fontFamily': 'openDyslexic'});
      await settings.load();
      expect(settings.fontFamily.value, AppFont.openDyslexic);
    });

    test('restores lexend font', () async {
      SharedPreferences.setMockInitialValues({'settings.fontFamily': 'lexend'});
      await settings.load();
      expect(settings.fontFamily.value, AppFont.lexend);
    });

    test('falls back to system for an unknown value', () async {
      SharedPreferences.setMockInitialValues(
          {'settings.fontFamily': 'bogus'});
      await settings.load();
      expect(settings.fontFamily.value, AppFont.system);
    });
  });

  group('AppSettings.setFontFamily', () {
    test('updates the ValueNotifier immediately', () async {
      await settings.setFontFamily(AppFont.lexend);
      expect(settings.fontFamily.value, AppFont.lexend);
    });

    test('persists so a subsequent load returns the same value', () async {
      await settings.setFontFamily(AppFont.openDyslexic);
      settings.fontFamily.value = AppFont.system;
      await settings.load();
      expect(settings.fontFamily.value, AppFont.openDyslexic);
    });

    test('notifier fires listeners on change', () async {
      int callCount = 0;
      settings.fontFamily.addListener(() => callCount++);
      await settings.setFontFamily(AppFont.lexend);
      await settings.setFontFamily(AppFont.system);
      expect(callCount, 2);
      settings.fontFamily.removeListener(() {});
    });
  });
}
