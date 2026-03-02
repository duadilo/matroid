// Conditional platform export.
// On native (desktop + mobile): real dart:io implementation.
// On web: no-op stubs — app runs in remote-only mode.
export 'server_web.dart' if (dart.library.io) 'server_native.dart';
