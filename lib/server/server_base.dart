/// Platform-independent interface for the Python server subprocess.
/// Implemented by [PythonServer] (native) and the web stub, and by fakes
/// used in unit tests.
abstract class ServerBase {
  int? get port;
  bool get isRunning;
  List<String> get stderrLog;
  Future<void> start();
  Future<void> stop();
}
