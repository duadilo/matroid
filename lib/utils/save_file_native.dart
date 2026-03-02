import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';

Future<void> saveTextFile(String content, String defaultName) async {
  final path = await FilePicker.platform.saveFile(
    dialogTitle: 'Save file',
    fileName: defaultName,
  );
  if (path != null) await File(path).writeAsString(content);
}

Future<void> saveBytesFile(Uint8List bytes, String defaultName) async {
  final path = await FilePicker.platform.saveFile(
    dialogTitle: 'Save file',
    fileName: defaultName,
  );
  if (path != null) await File(path).writeAsBytes(bytes);
}
