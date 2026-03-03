/// Desktop (dart:io) implementation.
/// Imported only when dart.library.io is available (desktop + mobile).
library;

import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

export '../python_server.dart';
export '../server_base.dart';

/// True on Windows, Linux, macOS — the platforms that can spawn a subprocess.
bool get isDesktop =>
    Platform.isWindows || Platform.isLinux || Platform.isMacOS;

/// Extracts the bundled Python server binary from Flutter assets into the
/// app support directory, using a SHA-256 sidecar to skip re-extraction when
/// the binary hasn't changed.
///
/// Returns the path to the executable, or null if the asset is missing.
Future<String?> extractServerBinary() async {
  final binName =
      Platform.isWindows ? 'python_server.exe' : 'python_server';
  final assetName = 'assets/bin/$binName';

  try {
    final data = await rootBundle.load(assetName);
    final assetBytes = data.buffer.asUint8List();

    final supportDir = await getApplicationSupportDirectory();
    final cacheDir = Directory('${supportDir.path}/server');
    await cacheDir.create(recursive: true);

    final cached = File('${cacheDir.path}/$binName');
    final hashFile = File('${cacheDir.path}/$binName.sha256');
    final assetHash = sha256.convert(assetBytes).toString();

    final upToDate = await cached.exists() &&
        await hashFile.exists() &&
        await hashFile.readAsString() == assetHash;

    if (upToDate) return cached.path;

    await cached.writeAsBytes(assetBytes, flush: true);
    await hashFile.writeAsString(assetHash);
    if (!Platform.isWindows) {
      await Process.run('chmod', ['+x', cached.path]);
    }
    if (Platform.isMacOS) {
      // Clear quarantine attributes and ad-hoc sign so macOS Gatekeeper
      // doesn't SIGKILL the unsigned PyInstaller binary.
      // These are best-effort — failure (e.g. no Xcode CLI tools) is
      // non-fatal; the binary may still run in some environments.
      try {
        await Process.run('xattr', ['-cr', cached.path]);
        await Process.run('codesign', ['--force', '--sign', '-', cached.path]);
      } catch (_) {}
    }

    return cached.path;
  } catch (_) {
    return null;
  }
}
