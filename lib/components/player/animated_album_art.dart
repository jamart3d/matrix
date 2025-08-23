// lib/components/player/animated_album_art.dart

import 'package:flutter/material.dart';

class AnimatedAlbumArt extends StatefulWidget {
  final String albumArtPath;
  final bool isPlaying;
  final double size;

  const AnimatedAlbumArt({
    super.key,
    required this.albumArtPath,
    required this.isPlaying,
    required this.size,
  });

  @override
  State<AnimatedAlbumArt> createState() => _AnimatedAlbumArtState();
}

class _AnimatedAlbumArtState extends State<AnimatedAlbumArt>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10), // A full rotation takes 10 seconds
    );

    if (widget.isPlaying) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedAlbumArt oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Start or stop the animation when the playing state changes.
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 20,
              spreadRadius: 5,
            ),
            BoxShadow(
              color: Colors.green.withOpacity(0.4), // This color can be themed if needed
              blurRadius: 30,
              spreadRadius: -10,
            ),
          ],
        ),
        child: ClipOval(
          child: Image.asset(
            widget.albumArtPath,
            fit: BoxFit.cover,
            // Add a key to force the widget to rebuild when the image path changes
            key: ValueKey<String>(widget.albumArtPath),
          ),
        ),
      ),
    );
  }
}