import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config.dart';
import 'server_base.dart';
import 'server_mode.dart';

/// Called when a local-server failure triggers a fallback prompt.
/// Returns `true` if the user consents to use the remote server.
typedef FallbackDialogCallback = Future<bool> Function();

// ---------------------------------------------------------------------------
// Execute result
// ---------------------------------------------------------------------------

/// Returned by [ExcelService.execute] after a code-execution request.
class ExecuteResult {
  const ExecuteResult({
    required this.stdout,
    required this.stderr,
    this.error,
    required this.executionTimeMs,
  });

  final String stdout;
  final String stderr;

  /// Non-null when the server reports an execution error (timeout, import
  /// violation, syntax error, Node.js not installed, etc.).
  final String? error;

  final int executionTimeMs;

  factory ExecuteResult.fromJson(Map<String, dynamic> json) => ExecuteResult(
        stdout: (json['stdout'] as String?) ?? '',
        stderr: (json['stderr'] as String?) ?? '',
        error: json['error'] as String?,
        executionTimeMs: (json['execution_time_ms'] as int?) ?? 0,
      );
}

/// HTTP client for Excel operations.
///
/// Routes requests to the local Python server or the remote API based on
/// [mode]. When a local call fails, [_call] shows a one-shot fallback dialog
/// (via [_onFallbackNeeded]); concurrent failures wait on the same dialog
/// rather than spawning duplicates.
class ExcelService {
  ExcelService({
    required ServerMode mode,
    required this.server,
    required FallbackDialogCallback onFallbackNeeded,
    http.Client? httpClient,
    String? remoteBaseUrl,
  })  : _mode = mode,
        _onFallbackNeeded = onFallbackNeeded,
        _httpClient = httpClient ?? http.Client(),
        _remoteBaseOverride = remoteBaseUrl;

  ServerMode _mode;
  ServerBase? server;
  final FallbackDialogCallback _onFallbackNeeded;
  final http.Client _httpClient;
  final String? _remoteBaseOverride;

  static const _localTimeout = Duration(seconds: 15);
  static const _remoteTimeout = Duration(seconds: 60);

  /// Reactive flag — set to `false` when the user declines remote fallback.
  /// UI elements can listen to this to disable Excel-related controls.
  final featuresEnabled = ValueNotifier<bool>(true);

  ServerMode get mode => _mode;
  set mode(ServerMode value) {
    _mode = value;
    if (value == ServerMode.local || value == ServerMode.remote) {
      featuresEnabled.value = true;
    }
  }

  // Concurrency guard: at most one fallback dialog is shown at a time.
  Completer<bool>? _fallbackCompleter;

  String get _localBase => 'http://127.0.0.1:${server!.port}';
  String get _remoteBase => _remoteBaseOverride ?? AppConfig.baseUrl;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Uploads an Excel file to [/load]. Supply either [filePath] (desktop /
  /// mobile) or [bytes] (web). [fileName] is always required.
  Future<Map<String, dynamic>> loadFile({
    String? filePath,
    Uint8List? bytes,
    required String fileName,
  }) {
    return _call((base, timeout) async {
      final uri = Uri.parse('$base/load');
      final req = http.MultipartRequest('POST', uri);

      if (filePath != null) {
        req.files.add(
          await http.MultipartFile.fromPath('file', filePath,
              filename: fileName),
        );
      } else if (bytes != null) {
        req.files.add(
          http.MultipartFile.fromBytes('file', bytes, filename: fileName),
        );
      } else {
        throw ArgumentError('Either filePath or bytes must be provided');
      }

      final streamed = await _httpClient.send(req).timeout(timeout);
      final response = await http.Response.fromStream(streamed);
      _checkStatus(response);
      return _decodeJson(response);
    });
  }

  /// Sends processing parameters to [/process] and returns the result.
  Future<Map<String, dynamic>> process(Map<String, dynamic> params) {
    return _call((base, timeout) async {
      final response = await _httpClient
          .post(
            Uri.parse('$base/process'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(params),
          )
          .timeout(timeout);
      _checkStatus(response);
      return _decodeJson(response);
    });
  }

  /// Downloads the processed workbook bytes from [/export].
  Future<Uint8List> export() {
    return _call((base, timeout) async {
      final response =
          await _httpClient.get(Uri.parse('$base/export')).timeout(timeout);
      _checkStatus(response);
      return response.bodyBytes;
    });
  }

  /// Executes user-supplied [code] (Python or JavaScript) on the server and
  /// returns the captured output and any errors.
  ///
  /// [timeout] is the server-side execution timeout in seconds (default 10).
  /// The result always resolves — execution errors are reported in
  /// [ExecuteResult.error] rather than thrown.
  Future<ExecuteResult> execute({
    required String language,
    required String code,
    int timeout = 10,
  }) {
    return _call((base, httpTimeout) async {
      final response = await _httpClient
          .post(
            Uri.parse('$base/execute'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'language': language,
              'code': code,
              'timeout': timeout,
            }),
          )
          .timeout(httpTimeout);
      _checkStatus(response);
      return ExecuteResult.fromJson(_decodeJson(response));
    });
  }

  /// Fire-and-forget cleanup. Errors are logged silently; no fallback logic.
  void unload() {
    final base = _mode == ServerMode.local ? _localBase : _remoteBase;
    unawaited(
      _httpClient
          .post(Uri.parse('$base/unload'))
          .timeout(_localTimeout)
          .catchError((Object e) {
        debugPrint('[ExcelService] unload error (ignored): $e');
        return http.Response('', 204);
      }),
    );
  }

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  Future<T> _call<T>(
    Future<T> Function(String base, Duration timeout) fn,
  ) async {
    if (_mode == ServerMode.local) {
      try {
        return await fn(_localBase, _localTimeout);
      } catch (localError) {
        final useFallback = await _askFallback();
        if (useFallback) {
          if (_remoteBase.isEmpty) {
            throw StateError(
              'Remote server URL not configured. '
              'Build with --dart-define=BASE_URL=https://…',
            );
          }
          _mode = ServerMode.remote;
          return await fn(_remoteBase, _remoteTimeout);
        }
        // User declined fallback — disable features so the UI can react.
        featuresEnabled.value = false;
        rethrow;
      }
    } else {
      return fn(_remoteBase, _remoteTimeout);
    }
  }

  /// Shows the fallback dialog at most once concurrently.
  /// Concurrent callers await the same [Completer] instead of each opening
  /// their own dialog.
  Future<bool> _askFallback() async {
    if (_fallbackCompleter != null) {
      return _fallbackCompleter!.future;
    }

    _fallbackCompleter = Completer<bool>();
    try {
      final result = await _onFallbackNeeded();
      _fallbackCompleter!.complete(result);
      return result;
    } catch (e) {
      _fallbackCompleter!.completeError(e);
      rethrow;
    } finally {
      _fallbackCompleter = null;
    }
  }

  void _checkStatus(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }
  }

  Map<String, dynamic> _decodeJson(http.Response response) =>
      jsonDecode(response.body) as Map<String, dynamic>;
}
