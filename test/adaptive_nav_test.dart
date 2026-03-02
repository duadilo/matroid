import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:matroid/adaptive_nav.dart';
import 'package:matroid/app_settings.dart';
import 'package:matroid/l10n/app_localizations.dart';

// ---------------------------------------------------------------------------
// Test sizes
// ---------------------------------------------------------------------------

const _narrow = Size(400, 800);  // mobile   — drawer
const _medium = Size(750, 600);  // tablet   — collapsed rail
const _wide   = Size(1280, 800); // desktop  — extended rail

// ---------------------------------------------------------------------------
// Stub pages
// ---------------------------------------------------------------------------

class _StubHome extends StatelessWidget {
  const _StubHome();
  @override
  Widget build(BuildContext context) => const Text('stub-home');
}

class _StubSettings extends StatelessWidget {
  const _StubSettings();
  @override
  Widget build(BuildContext context) => const Text('stub-settings');
}

class _StubEditor extends StatelessWidget {
  const _StubEditor();
  @override
  Widget build(BuildContext context) => const Text('stub-editor');
}

class _StubMarkdown extends StatelessWidget {
  const _StubMarkdown();
  @override
  Widget build(BuildContext context) => const Text('stub-markdown');
}

class _StubLatex extends StatelessWidget {
  const _StubLatex();
  @override
  Widget build(BuildContext context) => const Text('stub-latex');
}

class _StubCharts extends StatelessWidget {
  const _StubCharts();
  @override
  Widget build(BuildContext context) => const Text('stub-charts');
}

class _StubMedia extends StatelessWidget {
  const _StubMedia();
  @override
  Widget build(BuildContext context) => const Text('stub-media');
}

class _StubChat extends StatelessWidget {
  const _StubChat();
  @override
  Widget build(BuildContext context) => const Text('stub-chat');
}

// ---------------------------------------------------------------------------
// Helper
// ---------------------------------------------------------------------------

Widget _buildApp(Size size, {Locale locale = const Locale('en')}) =>
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (_, child) => MediaQuery(
        data: MediaQueryData(size: size),
        child: child!,
      ),
      home: const AdaptiveNav(pages: [
        _StubHome(),
        _StubSettings(),
        _StubEditor(),
        _StubMarkdown(),
        _StubLatex(),
        _StubCharts(),
        _StubMedia(),
        _StubChat(),
      ]),
    );

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

void main() {
  final settings = AppSettings.instance;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    settings.themeMode.value = ThemeMode.system;
    settings.locale.value = const Locale('en');
  });

  // =========================================================================
  // Group 1 — Mobile layout
  // =========================================================================

  group('Mobile layout (<600 px)', () {
    testWidgets('DrawerButton present in AppBar', (tester) async {
      await tester.pumpWidget(_buildApp(_narrow));
      await tester.pump();

      expect(find.byType(DrawerButton), findsOneWidget);
    });

    testWidgets('NavigationRail absent', (tester) async {
      await tester.pumpWidget(_buildApp(_narrow));
      await tester.pump();

      expect(find.byType(NavigationRail), findsNothing);
    });

    testWidgets('stub-home shown initially, stub-settings absent', (tester) async {
      await tester.pumpWidget(_buildApp(_narrow));
      await tester.pump();

      expect(find.text('stub-home'), findsOneWidget);
      expect(find.text('stub-settings'), findsNothing);
    });

    testWidgets('Scaffold.drawer is not null', (tester) async {
      await tester.pumpWidget(_buildApp(_narrow));
      await tester.pump();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
      expect(scaffold.drawer, isNotNull);
    });

    testWidgets('Drawer contains 6 NavigationDrawerDestination entries',
        (tester) async {
      await tester.pumpWidget(_buildApp(_narrow));
      await tester.pump();

      final scaffoldState =
          tester.state<ScaffoldState>(find.byType(Scaffold).first);
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      expect(find.byType(NavigationDrawerDestination), findsNWidgets(8));
    });

    testWidgets('Tap Settings destination → shows stub-settings, hides stub-home',
        (tester) async {
      await tester.pumpWidget(_buildApp(_narrow));
      await tester.pump();

      final scaffoldState =
          tester.state<ScaffoldState>(find.byType(Scaffold).first);
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      await tester.tap(find.byType(NavigationDrawerDestination).at(1));
      await tester.pumpAndSettle();

      expect(find.text('stub-settings'), findsOneWidget);
      expect(find.text('stub-home'), findsNothing);
    });

    testWidgets('Tap Editor destination → shows stub-editor, hides stub-home',
        (tester) async {
      await tester.pumpWidget(_buildApp(_narrow));
      await tester.pump();

      final scaffoldState =
          tester.state<ScaffoldState>(find.byType(Scaffold).first);
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      // 3rd destination (index 2) is Editor
      await tester.tap(find.byType(NavigationDrawerDestination).at(2));
      await tester.pumpAndSettle();

      expect(find.text('stub-editor'), findsOneWidget);
      expect(find.text('stub-home'), findsNothing);
    });

    testWidgets('Drawer closes after destination tapped', (tester) async {
      await tester.pumpWidget(_buildApp(_narrow));
      await tester.pump();

      final scaffoldState =
          tester.state<ScaffoldState>(find.byType(Scaffold).first);
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      await tester.tap(find.byType(NavigationDrawerDestination).at(1));
      await tester.pumpAndSettle();

      // When drawer closes, the overlay is removed and its widgets are
      // disposed — NavigationDrawer is no longer in the tree.
      expect(find.byType(NavigationDrawer), findsNothing);
    });
  });

  // =========================================================================
  // Group 2 — Wide layout (≥600 px)
  // =========================================================================

  group('Wide layout (≥600 px)', () {
    testWidgets('NavigationRail present on medium width', (tester) async {
      await tester.pumpWidget(_buildApp(_medium));
      await tester.pump();

      expect(find.byType(NavigationRail), findsOneWidget);
    });

    testWidgets('DrawerButton absent; Scaffold.drawer == null', (tester) async {
      await tester.pumpWidget(_buildApp(_medium));
      await tester.pump();

      expect(find.byType(DrawerButton), findsNothing);
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
      expect(scaffold.drawer, isNull);
    });

    testWidgets('stub-home shown initially', (tester) async {
      await tester.pumpWidget(_buildApp(_medium));
      await tester.pump();

      expect(find.text('stub-home'), findsOneWidget);
      expect(find.text('stub-settings'), findsNothing);
    });

    testWidgets(
        'Tap settings_outlined icon → stub-settings shown, stub-home gone',
        (tester) async {
      await tester.pumpWidget(_buildApp(_medium));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();

      expect(find.text('stub-settings'), findsOneWidget);
      expect(find.text('stub-home'), findsNothing);
    });

    testWidgets('Tap home_outlined icon → back to stub-home', (tester) async {
      await tester.pumpWidget(_buildApp(_medium));
      await tester.pump();

      // Navigate to settings first.
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();

      // Navigate back to home.
      await tester.tap(find.byIcon(Icons.home_outlined));
      await tester.pumpAndSettle();

      expect(find.text('stub-home'), findsOneWidget);
      expect(find.text('stub-settings'), findsNothing);
    });

    testWidgets('Medium (750 px): rail.extended == false', (tester) async {
      await tester.pumpWidget(_buildApp(_medium));
      await tester.pump();

      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(rail.extended, isFalse);
    });

    testWidgets('Wide (1280 px): rail.extended == true', (tester) async {
      await tester.pumpWidget(_buildApp(_wide));
      await tester.pump();

      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(rail.extended, isTrue);
    });

    testWidgets('Tap menu_open → rail.extended becomes false', (tester) async {
      await tester.pumpWidget(_buildApp(_wide));
      await tester.pump();

      // rail starts extended → menu_open button is shown
      await tester.tap(find.byIcon(Icons.menu_open));
      await tester.pumpAndSettle();

      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(rail.extended, isFalse);
    });

    testWidgets('Tap menu → rail.extended becomes true', (tester) async {
      await tester.pumpWidget(_buildApp(_medium));
      await tester.pump();

      // rail starts collapsed → menu button is shown
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(rail.extended, isTrue);
    });

    testWidgets('Tap perm_media_outlined icon → stub-media shown', (tester) async {
      await tester.pumpWidget(_buildApp(_medium));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.perm_media_outlined));
      await tester.pumpAndSettle();

      expect(find.text('stub-media'), findsOneWidget);
      expect(find.text('stub-home'), findsNothing);
    });

    testWidgets('Tap code_outlined icon → stub-editor shown', (tester) async {
      await tester.pumpWidget(_buildApp(_medium));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.code_outlined));
      await tester.pumpAndSettle();

      expect(find.text('stub-editor'), findsOneWidget);
      expect(find.text('stub-home'), findsNothing);
    });

    testWidgets('Tap chat_outlined icon → stub-chat shown', (tester) async {
      await tester.pumpWidget(_buildApp(_medium));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.chat_outlined));
      await tester.pumpAndSettle();

      expect(find.text('stub-chat'), findsOneWidget);
      expect(find.text('stub-home'), findsNothing);
    });
  });

  // =========================================================================
  // Group 3 — AppBar title
  // =========================================================================

  group('AppBar title', () {
    testWidgets('Mobile, Home selected → app title shown', (tester) async {
      await tester.pumpWidget(_buildApp(_narrow));
      await tester.pump();

      expect(find.text('Matroid'), findsOneWidget);
    });

    testWidgets('Mobile, Settings selected → settings title shown, app title gone',
        (tester) async {
      await tester.pumpWidget(_buildApp(_narrow));
      await tester.pump();

      final scaffoldState =
          tester.state<ScaffoldState>(find.byType(Scaffold).first);
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      await tester.tap(find.byType(NavigationDrawerDestination).at(1));
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Matroid'), findsNothing);
    });

    testWidgets('Wide, Home selected → app title shown', (tester) async {
      await tester.pumpWidget(_buildApp(_wide));
      await tester.pump();

      expect(find.text('Matroid'), findsOneWidget);
    });

    testWidgets('Wide, Settings selected → settings title shown, app title gone',
        (tester) async {
      await tester.pumpWidget(_buildApp(_wide));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsAtLeastNWidgets(1));
      expect(find.text('Matroid'), findsNothing);
    });

    testWidgets('Wide, Media selected → "Media" shown, "Matroid" absent',
        (tester) async {
      await tester.pumpWidget(_buildApp(_wide));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.perm_media_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Media'), findsAtLeastNWidgets(1));
      expect(find.text('Matroid'), findsNothing);
    });

    testWidgets('Wide, Editor selected → "Editor" shown, "Matroid" absent',
        (tester) async {
      await tester.pumpWidget(_buildApp(_wide));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.code_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Editor'), findsAtLeastNWidgets(1));
      expect(find.text('Matroid'), findsNothing);
    });

    testWidgets('Wide, Chat selected → "Chat" shown, "Matroid" absent',
        (tester) async {
      await tester.pumpWidget(_buildApp(_wide));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.chat_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Chat'), findsAtLeastNWidgets(1));
      expect(find.text('Matroid'), findsNothing);
    });
  });

  // =========================================================================
  // Group 4 — Localization
  // =========================================================================

  group('Localization', () {
    testWidgets('Spanish + narrow: drawer shows "Inicio"', (tester) async {
      await tester.pumpWidget(
          _buildApp(_narrow, locale: const Locale('es')));
      await tester.pump();

      final scaffoldState =
          tester.state<ScaffoldState>(find.byType(Scaffold).first);
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      expect(find.text('Inicio'), findsOneWidget);
    });

    testWidgets('Spanish + narrow: drawer shows "Configuración"', (tester) async {
      await tester.pumpWidget(
          _buildApp(_narrow, locale: const Locale('es')));
      await tester.pump();

      final scaffoldState =
          tester.state<ScaffoldState>(find.byType(Scaffold).first);
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      expect(find.text('Configuración'), findsOneWidget);
    });

    testWidgets('Spanish + wide (extended): rail shows "Inicio" label',
        (tester) async {
      await tester.pumpWidget(_buildApp(_wide, locale: const Locale('es')));
      await tester.pump();

      // Rail is extended at 1280 px, so labels are visible.
      expect(find.text('Inicio'), findsOneWidget);
    });
  });
}
