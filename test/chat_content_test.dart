import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:matroid/app_settings.dart';
import 'package:matroid/app_state.dart';
import 'package:matroid/l10n/app_localizations.dart';
import 'package:matroid/screens/chat_content.dart';
import 'package:matroid/server/chat_service.dart';
import 'package:matroid/server/server_mode.dart';

// ---------------------------------------------------------------------------
// Helper
// ---------------------------------------------------------------------------

Widget _buildApp({MockClient? client}) {
  final mockClient = client ??
      MockClient((req) async {
        if (req.url.path == '/chat/models') {
          return http.Response(jsonEncode({'providers': {}}), 200);
        }
        return http.Response('not found', 404);
      });

  chatService = ChatService(
    mode: ServerMode.remote,
    server: null,
    httpClient: mockClient,
    remoteBaseUrl: 'http://test',
  );

  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: const Scaffold(body: ChatContent()),
  );
}

Widget _buildAppWithModels() {
  final mockClient = MockClient((req) async {
    if (req.url.path == '/chat/models') {
      return http.Response(
        jsonEncode({
          'providers': {
            'openai': ['gpt-4o', 'gpt-4o-mini'],
            'anthropic': ['claude-sonnet-4-20250514'],
          }
        }),
        200,
      );
    }
    return http.Response('not found', 404);
  });

  chatService = ChatService(
    mode: ServerMode.remote,
    server: null,
    httpClient: mockClient,
    remoteBaseUrl: 'http://test',
  );

  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: const Scaffold(body: ChatContent()),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppSettings.instance.themeMode.value = ThemeMode.system;
    AppSettings.instance.locale.value = const Locale('en');
  });

  testWidgets('Toolbar chip shows "Chat"', (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();

    expect(find.widgetWithText(Chip, 'Chat'), findsOneWidget);
  });

  testWidgets('Empty state message shown initially', (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();

    expect(
      find.text(
          'Select a provider and model, then start a conversation.'),
      findsOneWidget,
    );
  });

  testWidgets('Input TextField is present', (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsAtLeastNWidgets(1));
  });

  testWidgets('Send button is present', (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.send), findsOneWidget);
  });

  testWidgets('Attach file button is present', (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.attach_file), findsOneWidget);
  });

  testWidgets('New conversation button is present', (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.add_comment_outlined), findsOneWidget);
  });

  testWidgets('Tools toggle button is present', (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.travel_explore_outlined), findsOneWidget);
  });

  testWidgets('Provider dropdown present after models load', (tester) async {
    await tester.pumpWidget(_buildAppWithModels());
    await tester.pumpAndSettle();

    // Should find at least one DropdownButton (provider selector)
    expect(find.byType(DropdownButton<String>), findsAtLeastNWidgets(1));
    expect(find.text('openai'), findsOneWidget);
  });
}
