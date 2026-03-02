/// Web stub — no dart:io, no subprocess support.
/// Imported when dart.library.io is unavailable (web).
library;

import '../server_base.dart';

export '../server_base.dart';

/// Always false on web — no local Python server possible.
bool get isDesktop => false;

/// No-op on web; local server binary is not available.
Future<String?> extractServerBinary() async => null;

/// Stub [PythonServer] that satisfies the type system on web.
/// No methods do anything useful; the app always uses remote mode on web.
class PythonServer implements ServerBase {
  PythonServer({String? binaryPath});

  @override int? get port => null;
  @override bool get isRunning => false;
  @override List<String> get stderrLog => const [];

  @override
  Future<void> start() async =>
      throw UnsupportedError('PythonServer is not supported on web');

  @override
  Future<void> stop() async {}
}
