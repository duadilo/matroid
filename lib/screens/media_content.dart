import 'dart:typed_data';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:video_player/video_player.dart';

import '../l10n/app_localizations.dart';
import '../utils/video_controller.dart' as vc;

// ---------------------------------------------------------------------------
// Data model
// ---------------------------------------------------------------------------

enum MediaType { image, video }

class MediaItem {
  MediaItem({required this.file, required this.type, this.bytes});
  final XFile file;
  final MediaType type;
  final Uint8List? bytes;
}

// ---------------------------------------------------------------------------
// MediaContent — body-only widget (no Scaffold)
// ---------------------------------------------------------------------------

class MediaContent extends StatefulWidget {
  const MediaContent({super.key});

  @override
  State<MediaContent> createState() => _MediaContentState();
}

class _MediaContentState extends State<MediaContent> {
  final _picker = ImagePicker();
  final List<MediaItem> _items = [];

  // ---- Picking helpers ----------------------------------------------------

  Future<void> _pickImage() async {
    final xfile = await _picker.pickImage(source: ImageSource.gallery);
    if (xfile == null) return;
    final bytes = await xfile.readAsBytes();
    setState(() {
      _items.add(MediaItem(file: xfile, type: MediaType.image, bytes: bytes));
    });
  }

  Future<void> _pickVideo() async {
    final xfile = await vc.pickVideoFile();
    if (xfile == null) return;
    setState(() {
      _items.add(MediaItem(file: xfile, type: MediaType.video));
    });
  }

  Future<void> _takePhoto() async {
    final xfile = await _picker.pickImage(source: ImageSource.camera);
    if (xfile == null) return;
    final bytes = await xfile.readAsBytes();
    setState(() {
      _items.add(MediaItem(file: xfile, type: MediaType.image, bytes: bytes));
    });
  }

  Future<void> _recordVideo() async {
    final xfile = await _picker.pickVideo(source: ImageSource.camera);
    if (xfile == null) return;
    setState(() {
      _items.add(MediaItem(file: xfile, type: MediaType.video));
    });
  }

  void _removeItem(int index) {
    setState(() => _items.removeAt(index));
  }

  // ---- Build --------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cameraOk = vc.isCameraAvailable;

    return Column(
      children: [
        // Toolbar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Chip(label: Text(l10n.mediaTitle)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.photo_library_outlined),
                tooltip: l10n.buttonPickImage,
                onPressed: _pickImage,
              ),
              if (vc.isVideoPickSupported)
                IconButton(
                  icon: const Icon(Icons.video_library_outlined),
                  tooltip: l10n.buttonPickVideo,
                  onPressed: _pickVideo,
                ),
              if (cameraOk)
                IconButton(
                  icon: const Icon(Icons.camera_alt_outlined),
                  tooltip: l10n.buttonTakePhoto,
                  onPressed: _takePhoto,
                ),
              if (cameraOk && vc.isVideoSupported)
                IconButton(
                  icon: const Icon(Icons.videocam_outlined),
                  tooltip: l10n.buttonRecordVideo,
                  onPressed: _recordVideo,
                ),
            ],
          ),
        ),
        const Divider(height: 1),
        // Body
        Expanded(
          child: _items.isEmpty
              ? Center(child: Text(l10n.mediaEmptyState))
              : _buildGrid(context),
        ),
      ],
    );
  }

  Widget _buildGrid(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width >= 700 ? 3 : 2;

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index];
        return _buildTile(context, item, index);
      },
    );
  }

  Widget _buildTile(BuildContext context, MediaItem item, int index) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: item.type == MediaType.image
              ? _buildImageTile(context, item)
              : _buildVideoTile(context, item),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: IconButton.filled(
            icon: const Icon(Icons.close, size: 18),
            tooltip: AppLocalizations.of(context)!.mediaRemoveItem,
            style: IconButton.styleFrom(
              backgroundColor: Colors.black54,
              foregroundColor: Colors.white,
              minimumSize: const Size(28, 28),
              padding: EdgeInsets.zero,
            ),
            onPressed: () => _removeItem(index),
          ),
        ),
      ],
    );
  }

  Widget _buildImageTile(BuildContext context, MediaItem item) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      label: l10n.mediaViewImage,
      button: true,
      child: GestureDetector(
        onTap: () => _showImageDialog(context, item.bytes!),
        child: Image.memory(item.bytes!, fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildVideoTile(BuildContext context, MediaItem item) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      label: l10n.mediaPlayVideo,
      button: true,
      child: GestureDetector(
        onTap: vc.isVideoSupported
            ? () => _showVideoDialog(context, item.file)
            : () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Video playback is not supported on this platform.'),
                    duration: Duration(seconds: 3),
                  ),
                ),
        child: Container(
          color: Colors.black87,
          child: Center(
            child: Icon(
              vc.isVideoSupported ? Icons.play_circle_outline : Icons.videocam_off_outlined,
              size: 48,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  void _showImageDialog(BuildContext context, Uint8List bytes) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: InteractiveViewer(
          child: Image.memory(bytes),
        ),
      ),
    );
  }

  void _showVideoDialog(BuildContext context, XFile file) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (_) => Semantics(
        label: l10n.mediaVideoPlayer,
        child: Dialog(child: _VideoPlayerDialog(file: file)),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _VideoPlayerDialog
// ---------------------------------------------------------------------------

class _VideoPlayerDialog extends StatefulWidget {
  const _VideoPlayerDialog({required this.file});
  final XFile file;

  @override
  State<_VideoPlayerDialog> createState() => _VideoPlayerDialogState();
}

class _VideoPlayerDialogState extends State<_VideoPlayerDialog> {
  // video_player + chewie path (Android / iOS / macOS / web)
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;

  // media_kit path (Linux / Windows)
  Player? _mediaKitPlayer;
  VideoController? _mediaKitController;

  @override
  void initState() {
    super.initState();
    if (vc.useMediaKit) {
      _mediaKitPlayer = Player();
      _mediaKitController = VideoController(
        _mediaKitPlayer!,
        configuration: const VideoControllerConfiguration(
          enableHardwareAcceleration: false,
        ),
      );
      _mediaKitPlayer!.open(Media(widget.file.path));
    } else {
      _videoController = vc.createVideoController(widget.file);
      _videoController!.initialize().then((_) {
        if (!mounted) return;
        setState(() {
          _chewieController = ChewieController(
            videoPlayerController: _videoController!,
            autoPlay: true,
          );
        });
      });
    }
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController?.dispose();
    _mediaKitPlayer?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return SizedBox(
      height: screenHeight * 0.6,
      child: vc.useMediaKit
          ? (_mediaKitController != null
              ? Video(controller: _mediaKitController!)
              : const Center(child: CircularProgressIndicator()))
          : (_chewieController != null
              ? Chewie(controller: _chewieController!)
              : const Center(child: CircularProgressIndicator())),
    );
  }
}
