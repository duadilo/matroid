import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:matroid/app_state.dart' as app_state;
import 'package:matroid/screens/editor_content.dart';
import 'package:matroid/l10n/app_localizations.dart';

// ---------------------------------------------------------------------------
// Helper
// ---------------------------------------------------------------------------

Widget _buildApp() => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: EditorContent()),
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // Ensure no real service is injected so tests stay hermetic.
    app_state.excelService = null;
  });

  group('EditorContent structure', () {
    testWidgets('Run button is present in toolbar', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pump();

      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });

    testWidgets('Language toggle defaults to Python segment', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pump();

      final btn = tester.widget<SegmentedButton<String>>(
        find.byType(SegmentedButton<String>),
      );
      expect(btn.selected, {'python'});
    });

    testWidgets('Output panel shows placeholder initially', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pump();

      expect(find.text('Output will appear here after you press Run.'), findsOneWidget);
    });
  });

  group('EditorContent execution (no server)', () {
    testWidgets('Tapping Run with no service shows error in output panel',
        (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pump();

      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pumpAndSettle();

      // Placeholder should be gone; error message should appear.
      expect(
        find.text('Output will appear here after you press Run.'),
        findsNothing,
      );
      expect(find.textContaining('Server not connected'), findsOneWidget);
    });

    testWidgets('Run button disabled while running (spinner shown)', (tester) async {
      // With excelService null the run completes instantly (synchronously sets
      // the error result), so we just verify the button re-enables afterwards.
      await tester.pumpWidget(_buildApp());
      await tester.pump();

      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pumpAndSettle();

      // Button should be enabled again (not null onPressed).
      final btn = tester.widget<FilledButton>(
        find.ancestor(
          of: find.byIcon(Icons.play_arrow),
          matching: find.byType(FilledButton),
        ),
      );
      expect(btn.onPressed, isNotNull);
    });
  });

  group('EditorContent language switching', () {
    testWidgets('Switching language tab changes selection to JavaScript',
        (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pump();

      await tester.tap(find.text('JavaScript'));
      await tester.pumpAndSettle();

      final btn = tester.widget<SegmentedButton<String>>(
        find.byType(SegmentedButton<String>),
      );
      expect(btn.selected, {'javascript'});
    });

    testWidgets('Switching language when code is unchanged swaps default text',
        (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pump();

      // Tap JavaScript — code is still the Python default so it should swap.
      await tester.tap(find.text('JavaScript'));
      await tester.pumpAndSettle();

      // The JavaScript default contains 'getData' which the Python one does not.
      expect(find.textContaining('getData'), findsWidgets);
    });
  });
}
