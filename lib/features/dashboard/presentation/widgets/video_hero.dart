import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// A full-bleed hero that auto-plays a looping, muted background video and
/// lays arbitrary [overlay] content (header controls, greeting) on top.
///
/// Designed to sit at the very top of a screen and extend behind the status
/// bar. It degrades gracefully:
///   video asset -> [fallbackImageAssets] (in order) -> gradient placeholder.
///
/// Honors reduced-motion: when the platform requests disabled animations the
/// video is not played — a still fallback image (poster) is shown instead.
///
/// The controller is paused when the app is backgrounded and resumed when it
/// returns, so it never decodes frames off-screen.
class VideoHero extends StatefulWidget {
  /// Height of the visible hero *below* the status bar. The widget adds the
  /// top safe-area inset on top of this internally.
  final double contentHeight;

  /// Asset path of the looping video, e.g. 'assets/videos/home_hero.mp4'.
  final String videoAsset;

  /// Ordered image fallbacks used when the video can't initialize.
  final List<String> fallbackImageAssets;

  /// Content drawn above the video (header row, greeting, etc.). It is given
  /// the full hero area and is responsible for its own top padding.
  final Widget overlay;

  const VideoHero({
    super.key,
    required this.videoAsset,
    required this.overlay,
    this.fallbackImageAssets = const [],
    this.contentHeight = 230,
  });

  @override
  State<VideoHero> createState() => _VideoHeroState();
}

class _VideoHeroState extends State<VideoHero> with WidgetsBindingObserver {
  VideoPlayerController? _controller;
  bool _ready = false;
  // Set when playback errors (e.g. a device whose hardware decoder can't
  // handle the clip). We then permanently fall back to the poster image.
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Defer init until we can read MediaQuery for the reduced-motion flag.
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeInit());
  }

  Future<void> _maybeInit() async {
    final reduceMotion =
        WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.disableAnimations;
    if (reduceMotion) {
      // Skip playback entirely; the poster image (fallback) stays shown.
      return;
    }
    final controller = VideoPlayerController.asset(widget.videoAsset);
    _controller = controller;
    // Some devices report the format as supported but then fail in the
    // hardware decoder during playback. Watch for that and fall back.
    controller.addListener(_onControllerUpdate);
    try {
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(0);
      await controller.play();
      if (mounted) setState(() => _ready = true);
    } catch (_) {
      // Init failed outright — keep the fallback image.
      if (mounted) setState(() => _failed = true);
    }
  }

  void _onControllerUpdate() {
    final c = _controller;
    if (c == null || _failed) return;
    if (c.value.hasError) {
      // Hardware decoder failed mid-playback: stop retrying, release the
      // controller, and show the poster image instead.
      c.removeListener(_onControllerUpdate);
      c.dispose();
      _controller = null;
      if (mounted) {
        setState(() {
          _failed = true;
          _ready = false;
        });
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final c = _controller;
    if (c == null || !_ready) return;
    if (state == AppLifecycleState.resumed) {
      c.play();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      c.pause();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.removeListener(_onControllerUpdate);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    final screenWidth = MediaQuery.of(context).size.width;
    final controller = _controller;

    // When the video is ready, size the hero to the video's aspect ratio so
    // the full frame is visible with no bottom/side cropping. The status-bar
    // inset is added on top (the gradient keeps overlay text legible there).
    // A minimum height guarantees room for the header + greeting even for
    // very short/wide clips, and a max keeps an extreme-tall clip in check.
    double totalHeight;
    if (_ready && controller != null && controller.value.isInitialized) {
      final videoHeight = screenWidth / controller.value.aspectRatio;
      final minH = widget.contentHeight * 0.85;
      final maxH = widget.contentHeight + 120;
      totalHeight = videoHeight.clamp(minH, maxH) + topInset;
    } else {
      totalHeight = widget.contentHeight + topInset;
    }

    return SizedBox(
      height: totalHeight,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // --- Base layer: video or image fallback (square bottom edge) ---
          _buildBackground(),

            // --- Readability gradient so overlay stays legible ---
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x33000000),
                    Color(0x00000000),
                    Color(0x73000000),
                  ],
                  stops: [0.0, 0.45, 1.0],
                ),
              ),
            ),

          // --- Overlay content (header, greeting) ---
          widget.overlay,
        ],
      ),
    );
  }

  Widget _buildBackground() {
    final controller = _controller;
    if (_ready && controller != null && controller.value.isInitialized) {
      // Fit by width so the entire frame is shown edge-to-edge without
      // cropping the top or bottom. The hero height is sized to this same
      // aspect ratio in build(), so the video exactly fills the area.
      return FittedBox(
        fit: BoxFit.fitWidth,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: controller.value.size.width,
          height: controller.value.size.height,
          child: VideoPlayer(controller),
        ),
      );
    }
    // Not ready yet, or failed: show the fallback image chain / placeholder.
    return _fallbackImage(0);
  }

  Widget _fallbackImage(int index) {
    if (index >= widget.fallbackImageAssets.length) {
      return const _GradientPlaceholder();
    }
    return Image.asset(
      widget.fallbackImageAssets[index],
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, __, ___) => _fallbackImage(index + 1),
    );
  }
}

class _GradientPlaceholder extends StatelessWidget {
  const _GradientPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF125420), Color(0xFF106220)],
        ),
      ),
      child: Center(
        child: Icon(Icons.play_circle_outline, size: 48, color: Colors.white54),
      ),
    );
  }
}
