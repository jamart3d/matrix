// lib/components/player/playback_controls.dart

import 'package:flutter/material.dart';
import 'package:matrix/providers/album_settings_provider.dart';
import 'package:matrix/providers/track_player_provider.dart';
import 'package:matrix/providers/enums.dart';
import 'package:matrix/utils/seamless_rect_tween.dart';
import 'package:provider/provider.dart';

class PlaybackControls extends StatefulWidget {
  const PlaybackControls({super.key});

  @override
  State<PlaybackControls> createState() => _PlaybackControlsState();
}

class _PlaybackControlsState extends State<PlaybackControls>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _glowAnimation;
  final Curve _animationCurve = Curves.easeInOut;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _scaleAnimation = Tween<double>(begin: 0.98, end: 1.02).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: _animationCurve,
      ),
    );

    _glowAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    final provider = context.read<TrackPlayerProvider>();
    if (provider.isPlaying) {
      _animationController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trackPlayerProvider = context.watch<TrackPlayerProvider>();
    final heroTag = ModalRoute.of(context)?.settings.arguments as String? ?? 'album_player_hero_fallback';
    final settingsProvider = context.watch<AlbumSettingsProvider>();
    final isLarge = settingsProvider.fabSize == FabSize.large;
    final double fabSize = isLarge ? 75.0 : 65.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(35),
        color: Colors.black.withOpacity(0.3),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildControlButton(
            icon: Icons.skip_previous,
            onPressed: trackPlayerProvider.previous,
            size: 48.0,
          ),
          Hero(
            tag: heroTag,
            createRectTween: (begin, end) {
              return SeamlessRectTween(curve: _animationCurve, begin: begin!, end: end!);
            },
            child: Consumer<TrackPlayerProvider>(
              builder: (context, provider, child) {
                if (provider.isPlaying && !_animationController.isAnimating) {
                  _animationController.repeat(reverse: true);
                } else if (!provider.isPlaying && _animationController.isAnimating) {
                  _animationController.stop();
                  _animationController.reset();
                }

                return AnimatedBuilder(
                  animation: _glowAnimation,
                  builder: (context, child) {
                    return Container(
                      width: fabSize,
                      height: fabSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: provider.isPlaying ? [
                          BoxShadow(
                            color: Colors.yellow.withOpacity(_glowAnimation.value * 0.5),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ] : null,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(fabSize / 2),
                          onTap: () {
                            if (provider.isLoading) return;
                            if (provider.isPlaying) {
                              provider.pause();
                            } else {
                              provider.play();
                            }
                          },
                          onLongPress: () {
                            provider.clearPlaylist();
                          },
                          child: Container(
                            width: fabSize,
                            height: fabSize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  Colors.yellow.withOpacity(0.9),
                                  Colors.yellow.withOpacity(0.7),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Center(
                              child: provider.isLoading
                                  ? SizedBox(
                                width: 30,
                                height: 30,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3.0,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.black.withOpacity(0.8),
                                  ),
                                ),
                              )
                                  : ScaleTransition(
                                scale: _scaleAnimation,
                                child: Icon(
                                  provider.isPlaying
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  size: fabSize * 0.6,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          _buildControlButton(
            icon: Icons.skip_next,
            onPressed: trackPlayerProvider.next,
            size: 48.0,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required double size,
  }) {
    return IconButton(
      icon: Icon(
        icon,
        size: size,
        color: Colors.white,
      ),
      onPressed: onPressed,
    );
  }
}
