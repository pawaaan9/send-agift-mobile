import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/widgets/app_network_image.dart';

/// Plays a reel's video, cropped to fill the screen the way the feed expects.
///
/// The controller is created only for the reel that is actually on screen and
/// disposed the moment it leaves, so scrolling the feed never leaves a stack
/// of decoders running. The poster stays visible until the first frame is
/// ready, so a slow network shows the still rather than a black rectangle.
class ReelVideo extends StatefulWidget {
  const ReelVideo({
    super.key,
    required this.url,
    required this.posterUrl,
    required this.playing,
    this.onProgress,
    this.onCompleted,
  });

  final String url;
  final String? posterUrl;

  /// True while this reel is the one being watched and not paused.
  final bool playing;

  /// Fired on each position update with 0..1 through the clip.
  final ValueChanged<double>? onProgress;

  /// Fired once when the clip reaches its end.
  final VoidCallback? onCompleted;

  @override
  State<ReelVideo> createState() => _ReelVideoState();
}

class _ReelVideoState extends State<ReelVideo> {
  VideoPlayerController? _controller;
  bool _ready = false;
  bool _failed = false;
  bool _reportedCompletion = false;

  @override
  void initState() {
    super.initState();
    _open();
  }

  @override
  void didUpdateWidget(covariant ReelVideo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.url != oldWidget.url) {
      _close();
      _open();
      return;
    }
    if (widget.playing != oldWidget.playing) _applyPlayState();
  }

  Future<void> _open() async {
    final controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _controller = controller;
    controller.addListener(_onTick);

    try {
      await controller.initialize();
      // Reels loop like every other short-video feed; the completion callback
      // is what advances the page, so looping only matters when it is the last
      // reel loaded.
      await controller.setLooping(false);
      if (!mounted) return;
      setState(() => _ready = true);
      _applyPlayState();
    } catch (_) {
      if (!mounted) return;
      // A dead URL falls back to the poster rather than an error box; the
      // reel still reads as a post.
      setState(() => _failed = true);
    }
  }

  void _applyPlayState() {
    final controller = _controller;
    if (controller == null || !_ready) return;
    if (widget.playing) {
      controller.play();
    } else {
      controller.pause();
    }
  }

  void _onTick() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    final duration = controller.value.duration;
    final position = controller.value.position;
    if (duration.inMilliseconds > 0) {
      widget.onProgress?.call(
        (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0),
      );
    }

    if (!_reportedCompletion &&
        duration.inMilliseconds > 0 &&
        position >= duration) {
      _reportedCompletion = true;
      widget.onCompleted?.call();
    }
  }

  void _close() {
    _controller?.removeListener(_onTick);
    _controller?.dispose();
    _controller = null;
    _ready = false;
    _failed = false;
    _reportedCompletion = false;
  }

  @override
  void dispose() {
    _close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final showVideo = _ready && !_failed && controller != null;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (widget.posterUrl != null)
          AppNetworkImage(url: widget.posterUrl!)
        else
          const ColoredBox(color: Colors.black),
        if (showVideo)
          FittedBox(
            fit: BoxFit.cover,
            clipBehavior: Clip.hardEdge,
            child: SizedBox(
              width: controller.value.size.width,
              height: controller.value.size.height,
              child: VideoPlayer(controller),
            ),
          ),
      ],
    );
  }
}
