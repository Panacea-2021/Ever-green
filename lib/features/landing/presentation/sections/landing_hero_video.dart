import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../landing_theme.dart';

/// Full-bleed muted looping video for the landing hero.
/// Falls back to [LandingAssets.heroBg] if the clip cannot play.
class LandingHeroVideo extends StatefulWidget {
  const LandingHeroVideo({super.key});

  @override
  State<LandingHeroVideo> createState() => _LandingHeroVideoState();
}

class _LandingHeroVideoState extends State<LandingHeroVideo>
    with WidgetsBindingObserver {
  VideoPlayerController? _controller;
  bool _ready = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    final reduceMotion = WidgetsBinding
        .instance.platformDispatcher.accessibilityFeatures.disableAnimations;
    if (reduceMotion) return;

    final controller = VideoPlayerController.asset(LandingAssets.heroVideo);
    _controller = controller;
    controller.addListener(_onUpdate);
    try {
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(0);
      await controller.play();
      if (mounted) setState(() => _ready = true);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  void _onUpdate() {
    final c = _controller;
    if (c == null || _failed) return;
    if (c.value.hasError) {
      c.removeListener(_onUpdate);
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
    _controller?.removeListener(_onUpdate);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (_ready && controller != null && controller.value.isInitialized) {
      return FittedBox(
        fit: BoxFit.cover,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: controller.value.size.width,
          height: controller.value.size.height,
          child: VideoPlayer(controller),
        ),
      );
    }

    return Image.asset(
      LandingAssets.heroBg,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, __, ___) => const ColoredBox(
        color: Color(0xFFD7EAD4),
      ),
    );
  }
}
