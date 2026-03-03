import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:matroid/server/excel_service.dart';
import 'package:matroid/server/server_base.dart';
import 'package:matroid/server/server_mode.dart';

// ---------------------------------------------------------------------------
// Helpers (mirrors excel_service_test.dart)
// ---------------------------------------------------------------------------

class _FakeServer implements ServerBase {
  @override int? get port => 9999;
  @override bool get isRunning => true;
  @override List<String> get stderrLog => const [];
  @override final logLines = ValueNotifier<List<LogLine>>(const []);
  @override Future<void> start() async {}
  @override Future<void> stop() async {}
}

ExcelService _localService(MockClient mockClient) => ExcelService(
      mode: ServerMode.local,
      server: _FakeServer(),
      onFallbackNeeded: () async => false,
      httpClient: mockClient,
      remoteBaseUrl: 'http://remote-test',
    );

MockClient _ok(Map<String, dynamic> json) =>
    MockClient((_) async => http.Response(jsonEncode(json), 200));

// ---------------------------------------------------------------------------
// ExecuteResult.fromJson
// ---------------------------------------------------------------------------

void main() {
  group('ExecuteResult.fromJson', () {
    test('parses all fields', () {
      final result = ExecuteResult.fromJson({
        'stdout': 'hello\n',
        'stderr': '',
        'error': null,
        'execution_time_ms': 42,
      });
      expect(result.stdout, 'hello\n');
      expect(result.stderr, '');
      expect(result.error, isNull);
      expect(result.executionTimeMs, 42);
    });

    test('handles non-null error', () {
      final result = ExecuteResult.fromJson({
        'stdout': '',
        'stderr': '',
        'error': 'SyntaxError: invalid syntax',
        'execution_time_ms': 0,
      });
      expect(result.error, 'SyntaxError: invalid syntax');
    });

    test('defaults missing fields to empty strings and zero', () {
      final result = ExecuteResult.fromJson({});
      expect(result.stdout, '');
      expect(result.stderr, '');
      expect(result.error, isNull);
      expect(result.executionTimeMs, 0);
    });
  });

  // ---------------------------------------------------------------------------
  // ExcelService.execute — HTTP layer
  // ---------------------------------------------------------------------------

  group('ExcelService.execute', () {
    test('returns ExecuteResult on 200 success', () async {
      final svc = _localService(
        _ok({
          'stdout': 'hello\n',
          'stderr': '',
          'error': null,
          'execution_time_ms': 7,
        }),
      );
      final result = await svc.execute(language: 'python', code: 'print("hello")');
      expect(result.stdout, 'hello\n');
      expect(result.error, isNull);
      expect(result.executionTimeMs, 7);
    });

    test('throws on non-2xx response (goes through fallback → declined)', () async {
      final svc = _localService(
        MockClient((_) async => http.Response('{"detail":"error"}', 500)),
      );
      await expectLater(
        svc.execute(language: 'python', code: 'pass'),
        throwsException,
      );
    });

    test('sends correct JSON body', () async {
      http.Request? captured;
      final svc = ExcelService(
        mode: ServerMode.local,
        server: _FakeServer(),
        onFallbackNeeded: () async => false,
        remoteBaseUrl: 'http://remote-test',
        httpClient: MockClient((req) async {
          captured = req;
          return http.Response(
            jsonEncode({
              'stdout': '',
              'stderr': '',
              'error': null,
              'execution_time_ms': 1,
            }),
            200,
          );
        }),
      );

      await svc.execute(language: 'javascript', code: 'console.log(1)', timeout: 5);

      expect(captured, isNotNull);
      final body = jsonDecode(captured!.body) as Map<String, dynamic>;
      expect(body['language'], 'javascript');
      expect(body['code'], 'console.log(1)');
      expect(body['timeout'], 5);
    });
  });
}
