import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:matroid/server/excel_service.dart';
import 'package:matroid/server/server_base.dart';
import 'package:matroid/server/server_mode.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Stub that implements [ServerBase] without any dart:io dependency.
class _FakeServer implements ServerBase {
  @override int? get port => 9999;
  @override bool get isRunning => true;
  @override List<String> get stderrLog => const [];
  @override final logLines = ValueNotifier<List<LogLine>>(const []);
  @override Future<void> start() async {}
  @override Future<void> stop() async {}
}

/// Builds an ExcelService in local mode with a mock HTTP client.
ExcelService _localService(
  MockClient mockClient, {
  bool Function()? onFallback,
}) {
  return ExcelService(
    mode: ServerMode.local,
    server: _FakeServer(),
    onFallbackNeeded: () async => onFallback?.call() ?? false,
    httpClient: mockClient,
    remoteBaseUrl: 'http://remote-test',
  );
}

/// A mock client that always returns [statusCode] with [body].
MockClient _fixed(int statusCode, String body) =>
    MockClient((_) async => http.Response(body, statusCode));

/// A mock client that returns a successful JSON response.
MockClient _ok(Map<String, dynamic> json) =>
    _fixed(200, jsonEncode(json));

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('ExcelService.process', () {
    test('returns decoded JSON on success', () async {
      final svc = _localService(
        _ok({'status': 'processed', 'rows': 42}),
      );
      final result = await svc.process({'op': 'sum'});
      expect(result['status'], 'processed');
      expect(result['rows'], 42);
    });

    test('throws on non-2xx response', () async {
      final svc = _localService(_fixed(400, '{"detail":"No file loaded"}'));
      expect(() => svc.process({}), throwsException);
    });
  });

  group('ExcelService.export', () {
    test('returns body bytes on success', () async {
      final fakeBytes = utf8.encode('XLSX-DATA');
      final svc = _localService(
        MockClient((_) async => http.Response.bytes(fakeBytes, 200)),
      );
      final bytes = await svc.export();
      expect(bytes, fakeBytes);
    });
  });

  group('ExcelService fallback logic', () {
    test('switches to remote when user accepts fallback', () async {
      // First call (local) fails; fallback accepted; second call (remote) succeeds.
      var callCount = 0;
      final svc = _localService(
        MockClient((_) async {
          callCount++;
          if (callCount == 1) return http.Response('error', 500);
          return http.Response(jsonEncode({'status': 'processed'}), 200);
        }),
        onFallback: () => true, // user says yes
      );
      final result = await svc.process({});
      expect(result['status'], 'processed');
      expect(svc.mode, ServerMode.remote);
    });

    test('disables features when user declines fallback', () async {
      final svc = _localService(
        _fixed(500, 'error'),
        onFallback: () => false, // user says no
      );
      expect(svc.featuresEnabled.value, isTrue);
      await expectLater(svc.process({}), throwsException);
      expect(svc.featuresEnabled.value, isFalse);
    });

    test('concurrent failures share one fallback dialog', () async {
      var dialogCount = 0;
      final svc = ExcelService(
        mode: ServerMode.local,
        server: _FakeServer(),
        remoteBaseUrl: 'http://remote-test',
        onFallbackNeeded: () async {
          dialogCount++;
          await Future<void>.delayed(const Duration(milliseconds: 10));
          return false;
        },
        httpClient: _fixed(500, 'error'),
      );

      // Fire two concurrent requests.
      await Future.wait([
        svc.process({}).catchError((_) => <String, dynamic>{}),
        svc.process({}).catchError((_) => <String, dynamic>{}),
      ]);

      expect(dialogCount, 1);
    });
  });

  group('ExcelService.mode setter', () {
    test('re-enables features when mode is set', () async {
      final svc = _localService(
        _fixed(500, 'error'),
        onFallback: () => false,
      );
      await expectLater(svc.process({}), throwsException);
      expect(svc.featuresEnabled.value, isFalse);

      svc.mode = ServerMode.remote;
      expect(svc.featuresEnabled.value, isTrue);
    });
  });
}
