import 'dart:ui' show AppExitResponse;

import 'package:accessibility_tools/accessibility_tools.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'adaptive_nav.dart';
import 'app_settings.dart';
import 'app_state.dart';
import 'screens/charts_content.dart';
import 'screens/chat_content.dart';
import 'screens/media_content.dart';
import 'screens/editor_content.dart';
import 'screens/latex_content.dart';
import 'screens/markdown_content.dart';
import 'server/chat_service.dart';
import 'server/excel_service.dart';
import 'screens/home_content.dart';
import 'l10n/app_localizations.dart';
import 'server/platform/server_platform.dart';
import 'server/server_mode.dart';
import 'screens/settings_content.dart';

// ---------------------------------------------------------------------------
// Globals
// ---------------------------------------------------------------------------

final _navigatorKey = GlobalKey<NavigatorState>();

// ---------------------------------------------------------------------------
// Entry point — runs immediately; server startup happens inside HomeContent
// ---------------------------------------------------------------------------

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load all persisted user settings (theme, locale, etc.).
  await AppSettings.instance.load();

  // Start binary extraction immediately — runs concurrently with runApp so the
  // I/O is often done by the time the loading screen first renders.
  // isDesktop + extractServerBinary come from platform/server_platform.dart.
  if (isDesktop) binaryPathFuture = extractServerBinary();

  excelService = ExcelService(
    mode: isDesktop ? ServerMode.local : ServerMode.remote,
    server: null,
    onFallbackNeeded: _askUserToFallback,
  );

  chatService = ChatService(
    mode: isDesktop ? ServerMode.local : ServerMode.remote,
    server: null,
  );

  runApp(const MainApp());
}

// ---------------------------------------------------------------------------
// Fallback dialog
// ---------------------------------------------------------------------------

Future<bool> _askUserToFallback() async {
  final context = _navigatorKey.currentContext;
  if (context == null) return false;

  return await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          final l10n = AppLocalizations.of(ctx)!;
          return AlertDialog(
            title: Text(l10n.fallbackDialogTitle),
            content: Text(l10n.fallbackDialogBody),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.buttonNo),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l10n.buttonUseRemote),
              ),
            ],
          );
        },
      ) ??
      false;
}

// ---------------------------------------------------------------------------
// Root widget
// ---------------------------------------------------------------------------

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  late final AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();
    AppSettings.instance.themeMode.addListener(_rebuild);
    AppSettings.instance.locale.addListener(_rebuild);
    AppSettings.instance.fontFamily.addListener(_rebuild);
    _lifecycleListener = AppLifecycleListener(
      onExitRequested: () async {
        await pythonServer?.stop();
        return AppExitResponse.exit;
      },
    );
  }

  @override
  void dispose() {
    AppSettings.instance.themeMode.removeListener(_rebuild);
    AppSettings.instance.locale.removeListener(_rebuild);
    AppSettings.instance.fontFamily.removeListener(_rebuild);
    _lifecycleListener.dispose();
    super.dispose();
  }

  void _rebuild() => setState(() {});

  /// Build a ThemeData with the custom font applied to its own textTheme.
  ///
  /// We build the theme first, then apply fontFamily to the theme's own
  /// textTheme so colors/sizes match the brightness. Passing a foreign
  /// textTheme (e.g. from `ThemeData()`) breaks dark-mode text colors
  /// and causes fl_chart axis labels to disappear.
  static ThemeData _buildTheme(Brightness brightness, String? fontFamilyName) {
    var theme = ThemeData(
      colorSchemeSeed: Colors.indigo,
      brightness: brightness,
      useMaterial3: true,
      fontFamily: fontFamilyName,
    );
    if (fontFamilyName != null) {
      theme = theme.copyWith(
        textTheme: theme.textTheme.apply(fontFamily: fontFamilyName),
      );
    }
    return theme;
  }

  @override
  Widget build(BuildContext context) {
    final fontFamilyName = switch (AppSettings.instance.fontFamily.value) {
      AppFont.openDyslexic => 'OpenDyslexic',
      AppFont.lexend => 'Lexend',
      AppFont.system => null,
    };
    return MaterialApp(
      onGenerateTitle: (ctx) => AppLocalizations.of(ctx)!.appTitle,
      navigatorKey: _navigatorKey,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: AppSettings.instance.locale.value,
      themeMode: AppSettings.instance.themeMode.value,
      theme: _buildTheme(Brightness.light, fontFamilyName),
      darkTheme: _buildTheme(Brightness.dark, fontFamilyName),
      builder: kDebugMode
          ? (context, child) => AccessibilityTools(child: child)
          : null,
      home: const AdaptiveNav(pages: [
        HomeContent(),
        SettingsContent(),
        EditorContent(),
        MarkdownContent(),
        LatexContent(),
        ChartsContent(),
        MediaContent(),
        ChatContent(),
      ]),
    );
  }
}
