import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:matroid/app_settings.dart';
import 'package:matroid/l10n/app_localizations.dart';
import 'package:matroid/screens/charts_content.dart';

// ---------------------------------------------------------------------------
// Test sizes
// ---------------------------------------------------------------------------

const _narrow = Size(500, 800);
const _wide = Size(900, 800);

// ---------------------------------------------------------------------------
// Helper
// ---------------------------------------------------------------------------

Widget _buildApp() => MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: ChartsContent()),
    );

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppSettings.instance.themeMode.value = ThemeMode.system;
    AppSettings.instance.locale.value = const Locale('en');
  });

  testWidgets('Toolbar chip shows "Charts"', (tester) async {
    tester.view.physicalSize = _wide;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_buildApp());
    await tester.pump();

    expect(find.widgetWithText(Chip, 'Charts'), findsOneWidget);
  });

  testWidgets('All 6 chart cards render', (tester) async {
    tester.view.physicalSize = _wide;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_buildApp());
    await tester.pump();

    // Some cards may be offstage in scrollable grid — use skipOffstage: false.
    expect(find.byType(Card, skipOffstage: false), findsNWidgets(6));
    expect(find.text('Monthly Revenue', skipOffstage: false), findsOneWidget);
    expect(find.text('Quarterly Sales by Region', skipOffstage: false), findsOneWidget);
    expect(find.text('Market Share', skipOffstage: false), findsOneWidget);
    expect(find.text('Height vs Weight', skipOffstage: false), findsOneWidget);
    expect(find.text('Skill Assessment', skipOffstage: false), findsOneWidget);
    expect(find.text('Product Breakdown', skipOffstage: false), findsOneWidget);
  });

  testWidgets('Wide layout uses 2-column grid', (tester) async {
    tester.view.physicalSize = _wide;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_buildApp());
    await tester.pump();

    final grid = tester.widget<GridView>(find.byType(GridView));
    final delegate = grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    expect(delegate.crossAxisCount, 2);
  });

  testWidgets('Narrow layout uses 1-column grid', (tester) async {
    tester.view.physicalSize = _narrow;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_buildApp());
    await tester.pump();

    final grid = tester.widget<GridView>(find.byType(GridView));
    final delegate = grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    expect(delegate.crossAxisCount, 1);
  });
}
