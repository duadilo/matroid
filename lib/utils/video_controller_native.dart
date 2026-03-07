import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

VideoPlayerController createVideoController(XFile file) =>
    VideoPlayerController.file(File(file.path));

bool get isCameraAvailable => Platform.isAndroid || Platform.isIOS;

// media_kit covers Linux/Windows; video_player covers Android/iOS/macOS.
bool get isVideoSupported => true;

bool get isVideoPickSupported => true;

bool get useMediaKit => Platform.isLinux || Platform.isWindows;

Future<XFile?> pickVideoFile() async {
  if (Platform.isLinux || Platform.isWindows) {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty || result.files.first.path == null) {
      return null;
    }
    return XFile(result.files.first.path!);
  }
  return ImagePicker().pickVideo(source: ImageSource.gallery);
}
