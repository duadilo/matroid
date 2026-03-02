import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

Future<void> saveTextFile(String content, String defaultName) async {
  final bytes = Uint8List.fromList(utf8.encode(content));
  await saveBytesFile(bytes, defaultName);
}

Future<void> saveBytesFile(Uint8List bytes, String defaultName) async {
  final blob = web.Blob([bytes.toJS].toJS);
  final url = web.URL.createObjectURL(blob);
  web.HTMLAnchorElement()
    ..href = url
    ..setAttribute('download', defaultName)
    ..click();
  web.URL.revokeObjectURL(url);
}
