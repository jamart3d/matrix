// lib/components/animated_playing_fab.dart

import 'package:flutter/material.dart';
import 'package:matrix/utils/seamless_rect_tween.dart';

class AnimatedPlayingFab extends StatefulWidget {
  final bool isLoading;
  final bool isPlaying;
  final bool hasTrack;
  final Color themeColor;
  final Color? shadowColor;
  final double size;
  final VoidCallback onPressed;
  final VoidCallback? onLongPress;
  final String heroTag;

  const AnimatedPlayingFab({
    super.key,
    required this.isLoading,
    required this.isPlaying,
    required this.hasTrack,
    required this.themeColor,
    this.shadowColor,
    required this.size,
    required this.onPressed,
    this.onLongPress,
    required this.heroTag,
  });

  @override
  State<AnimatedPlayingFab> createState() => _AnimatedPlayingFabState();
}

class _AnimatedPlayingFabState extends State<AnimatedPlayingFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _scaleAnimation;
  final Curve _animationCurve = Curves.easeInOut;

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
        curve: _animationCurve,
      ),
    );

    if (widget.isPlaying) {
      _animationController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedPlayingFab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _animationController.repeat(reverse: true);
      } else {
        _animationController.stop();
        _animationController.animateTo(0.0, duration: const Duration(milliseconds: 100), curve: Curves.easeOut);
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
    if (!widget.hasTrack) {
      return const SizedBox.shrink();
    }

    return Hero(
      tag: widget.heroTag,
      createRectTween: (begin, end) {
        return SeamlessRectTween(curve: _animationCurve, begin: begin!, end: end!);
      },
      child: Material(
        color: Colors.transparent,
        child: GestureDetector(
          onTap: widget.onPressed,
          onLongPress: widget.isLoading ? widget.onLongPress : null,
          child: _buildButtonContent(),
        ),
      ),
    );
  }

  Widget _buildButtonContent() {
    final List<Shadow> shadows = [
      Shadow(
        color: widget.shadowColor ?? widget.themeColor.withOpacity(0.7),
        blurRadius: 4,
      )
    ];

    if (widget.isLoading) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: CircularProgressIndicator(
          strokeWidth: 3.0,
          valueColor: AlwaysStoppedAnimation<Color>(widget.themeColor),
        ),
      );
    }

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Icon(
        Icons.play_circle_fill,
        color: widget.themeColor,
        shadows: shadows,
        size: widget.size,
      ),
    );
  }
}