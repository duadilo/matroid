import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

VideoPlayerController createVideoController(XFile file) =>
    VideoPlayerController.file(File(file.path));

bool get isCameraAvailable => !Platform.isMacOS;
