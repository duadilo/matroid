import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'server_base.dart';

/// Manages the lifecycle of the bundled PyInstaller Python server process.
///
/// [binaryPath] — explicit path to the binary (e.g. extracted from Flutter
/// assets at startup). Falls back to the `PYTHON_SERVER_BIN` env var, then
/// to a path relative to the Flutter executable.
class PythonServer implements ServerBase {
  PythonServer({String? binaryPath}) : _explicitBinaryPath = binaryPath;

  final String? _explicitBinaryPath;
  Process? _process;
  int? _port;
  final List<String> _stderrLog = [];

  @override int? get port => _port;
  @override bool get isRunning => _process != null && _port != null;

  /// Stderr lines captured from the subprocess (for diagnostics).
  @override List<String> get stderrLog => List.unmodifiable(_stderrLog);

  /// Live log feed combining stdout and stderr lines.
  @override
  final ValueNotifier<List<LogLine>> logLines = ValueNotifier([]);

  /// Spawns the server binary and waits up to 10 s for it to print `PORT:<n>`
  /// on stdout. Throws if the binary can't be started, exits early, or times out.
  @override
  Future<void> start() async {
    if (isRunning) return;

    _stderrLog.clear();
    logLines.value = [];

    final binary = _resolvedBinaryPath();
    // ignore: avoid_print
    print('[PythonServer] starting binary: $binary');
    // ignore: avoid_print
    print('[PythonServer] binary exists: ${await File(binary).exists()}');
    _process = await Process.start(binary, []);

    // Capture stderr asynchronously for diagnostics.
    _process!.stderr
        .transform(const Utf8Decoder(allowMalformed: true))
        .transform(const LineSplitter())
        .listen((line) {
          _stderrLog.add(line);
          _appendLogLine(line, isError: true);
        });

    final portCompleter = Completer<int>();

    _process!.stdout
        .transform(const Utf8Decoder(allowMalformed: true))
        .transform(const LineSplitter())
        .listen(
          (line) {
            // ignore: avoid_print
            print('[PythonServer] stdout: $line');
            _appendLogLine(line, isError: false);
            if (!portCompleter.isCompleted && line.startsWith('PORT:')) {
              final n = int.tryParse(line.substring(5).trim());
              if (n != null) portCompleter.complete(n);
            }
          },
          onError: (Object e) {
            if (!portCompleter.isCompleted) portCompleter.completeError(e);
          },
          onDone: () async {
            if (!portCompleter.isCompleted) {
              // Give stderr stream a moment to drain before reading the log.
              await Future.delayed(const Duration(milliseconds: 200));
              final stderr = _stderrLog.join('\n');
              // ignore: avoid_print
              print('[PythonServer] process exited. stderr:\n$stderr');
              portCompleter.completeError(
                Exception(
                  'Python process exited before announcing PORT'
                  '${stderr.isNotEmpty ? '\nstderr:\n$stderr' : ''}',
                ),
              );
            }
          },
        );

    try {
      _port = await portCompleter.future.timeout(
        const Duration(seconds: 60),
        onTimeout: () => throw TimeoutException(
          'Timed out waiting for Python server to announce PORT',
        ),
      );
    } catch (_) {
      await stop();
      rethrow;
    }
  }

  /// Kills the subprocess and resets internal state.
  @override
  Future<void> stop() async {
    _process?.kill();
    _process = null;
    _port = null;
  }

  void _appendLogLine(String text, {required bool isError}) {
    const maxLines = 10000;
    final current = logLines.value;
    final updated = [...current, (text: text, isError: isError)];
    if (updated.length > maxLines) updated.removeRange(0, updated.length - maxLines);
    logLines.value = updated;
  }

  /// Resolves the path to the PyInstaller binary.
  ///
  /// Search order:
  ///   1. [_explicitBinaryPath] (passed at construction — from asset extraction)
  ///   2. `PYTHON_SERVER_BIN` environment variable (dev override)
  ///   3. Same directory as the Flutter executable (production layout)
  String _resolvedBinaryPath() {
    final explicit = _explicitBinaryPath;
    if (explicit != null && explicit.isNotEmpty) {
      return explicit;
    }

    final override = Platform.environment['PYTHON_SERVER_BIN'];
    if (override != null && override.isNotEmpty) return override;

    final exeDir = File(Platform.resolvedExecutable).parent.path;
    final name = Platform.isWindows ? 'python_server.exe' : 'python_server';
    return '$exeDir${Platform.pathSeparator}$name';
  }
}
