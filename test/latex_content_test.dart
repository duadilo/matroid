import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:matroid/screens/latex_content.dart';
import 'package:matroid/app_settings.dart';
import 'package:matroid/l10n/app_localizations.dart';

Widget _buildApp() => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: LatexContent()),
    );

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppSettings.instance.themeMode.value = ThemeMode.system;
    AppSettings.instance.locale.value = const Locale('en');
  });

  testWidgets('Toolbar shows Export PDF button', (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pump();

    expect(find.text('Export PDF'), findsOneWidget);
  });

  testWidgets('Toolbar shows Export HTML button', (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pump();

    expect(find.text('Export HTML'), findsOneWidget);
  });

  testWidgets('CodeField is present in widget tree', (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pump();

    expect(find.byType(CodeField), findsOneWidget);
  });

  testWidgets('Math chip label is shown', (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pump();

    expect(find.text('Math'), findsAtLeastNWidgets(1));
  });
}
