import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:matroid/app_settings.dart';
import 'package:matroid/l10n/app_localizations.dart';
import 'package:matroid/screens/media_content.dart';

Widget _buildApp() => MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: MediaContent()),
    );

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppSettings.instance.themeMode.value = ThemeMode.system;
    AppSettings.instance.locale.value = const Locale('en');
  });

  testWidgets('Toolbar chip shows "Media"', (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pump();

    expect(find.widgetWithText(Chip, 'Media'), findsOneWidget);
  });

  testWidgets('Empty state message shown initially', (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pump();

    expect(
      find.text(
        'No media selected. Use the toolbar buttons to pick or capture media.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('Pick Image button is visible', (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pump();

    expect(find.byIcon(Icons.photo_library_outlined), findsOneWidget);
  });

  testWidgets('Pick Video button is visible', (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pump();

    expect(find.byIcon(Icons.video_library_outlined), findsOneWidget);
  });

  testWidgets('Camera buttons hidden on macOS (isCameraAvailable == false)',
      (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pump();

    // On macOS (test runner), isCameraAvailable is false, so camera buttons
    // should not appear.
    expect(find.byIcon(Icons.camera_alt_outlined), findsNothing);
    expect(find.byIcon(Icons.videocam_outlined), findsNothing);
  });
}
