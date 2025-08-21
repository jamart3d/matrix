// lib/components/animated_playing_fab.dart

import 'package:flutter/material.dart';

class AnimatedPlayingFab extends StatefulWidget {
  final bool isLoading;
  final bool isPlaying;
  final bool hasTrack;
  final Color themeColor;
  final double size;
  final VoidCallback onPressed;
  final String heroTag;

  const AnimatedPlayingFab({
    super.key,
    required this.isLoading,
    required this.isPlaying,
    required this.hasTrack,
    required this.themeColor,
    required this.size,
    required this.onPressed,
    required this.heroTag,
  });

  @override
  State<AnimatedPlayingFab> createState() => _AnimatedPlayingFabState();
}

class _AnimatedPlayingFabState extends State<AnimatedPlayingFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    // If music is already playing when the widget is built, start the animation.
    if (widget.isPlaying) {
      _animationController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedPlayingFab oldWidget) {
    super.didUpdateWidget(oldWidget);

    // This is the key: react to changes in the isPlaying state.
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _animationController.repeat(reverse: true); // Start pulsing
      } else {
        _animationController.stop(); // Stop pulsing
        _animationController.animateTo(0.0, duration: const Duration(milliseconds: 100), curve: Curves.easeOut); // Reset to base size
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1. If no track is loaded, show nothing.
    if (!widget.hasTrack) {
      return const SizedBox.shrink(); // Use SizedBox.shrink() instead of null
    }

    // 2. If it's loading, show the progress indicator.
    if (widget.isLoading) {
      return FloatingActionButton(
        heroTag: widget.heroTag,
        onPressed: widget.onPressed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: CircularProgressIndicator(
            strokeWidth: 3.0,
            valueColor: AlwaysStoppedAnimation<Color>(widget.themeColor),
          ),
        ),
      );
    }

    // 3. Otherwise, show the animated play button.
    return ScaleTransition(
      scale: _scaleAnimation,
      child: FloatingActionButton(
        heroTag: widget.heroTag,
        onPressed: widget.onPressed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Icon(
          Icons.play_circle_fill,
          color: widget.themeColor,
          shadows: [
            Shadow(color: widget.themeColor.withOpacity(0.7), blurRadius: 4)
          ],
          size: widget.size,
        ),
      ),
    );
  }
}