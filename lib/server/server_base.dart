import 'package:flutter/foundation.dart';

/// A single captured line from the server subprocess.
typedef LogLine = ({String text, bool isError});

/// Platform-independent interface for the Python server subprocess.
/// Implemented by [PythonServer] (native) and the web stub, and by fakes
/// used in unit tests.
abstract class ServerBase {
  int? get port;
  bool get isRunning;
  List<String> get stderrLog;

  /// Live log feed — each entry is a stdout or stderr line.
  ValueNotifier<List<LogLine>> get logLines;

  Future<void> start();
  Future<void> stop();
}
