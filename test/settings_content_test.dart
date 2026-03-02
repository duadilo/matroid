import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:matroid/app_settings.dart';
import 'package:matroid/l10n/app_localizations.dart';
import 'package:matroid/screens/settings_content.dart';

// ---------------------------------------------------------------------------
// Helper
// ---------------------------------------------------------------------------

Widget _buildApp() => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: SettingsContent()),
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
    settings.fontFamily.value = AppFont.system;
  });

  testWidgets('Font label text is present', (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pump();
    expect(find.text('Font'), findsOneWidget);
  });

  testWidgets('SegmentedButton shows Default, OpenDyslexic, Lexend segments',
      (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pump();
    expect(find.text('Default'), findsOneWidget);
    expect(find.text('OpenDyslexic'), findsOneWidget);
    expect(find.text('Lexend'), findsOneWidget);
  });

  testWidgets('Default segment is initially selected', (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pump();
    final button = tester.widget<SegmentedButton<AppFont>>(
      find.byType(SegmentedButton<AppFont>),
    );
    expect(button.selected, {AppFont.system});
  });

  testWidgets('Tapping Lexend updates fontFamily to AppFont.lexend',
      (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pump();
    await tester.tap(find.text('Lexend'));
    await tester.pump();
    expect(settings.fontFamily.value, AppFont.lexend);
  });

  testWidgets('Tapping OpenDyslexic updates fontFamily to AppFont.openDyslexic',
      (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pump();
    await tester.tap(find.text('OpenDyslexic'));
    await tester.pump();
    expect(settings.fontFamily.value, AppFont.openDyslexic);
  });

  testWidgets('Theme row is still present (regression)', (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pump();
    expect(find.text('Theme'), findsOneWidget);
  });

  testWidgets('Language row is still present (regression)', (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pump();
    expect(find.text('Language'), findsAtLeastNWidgets(1));
  });
}
