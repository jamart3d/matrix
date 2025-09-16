// lib/components/player/integrated_buffer_bar.dart

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:matrix/providers/track_player_provider.dart';

class IntegratedBufferBar extends StatefulWidget {
  final TrackPlayerProvider provider;

  const IntegratedBufferBar({
    super.key,
    required this.provider,
  });

  @override
  State<IntegratedBufferBar> createState() => _IntegratedBufferBarState();
}

class _IntegratedBufferBarState extends State<IntegratedBufferBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Listen to the processing state to control the shimmer
    widget.provider.processingStateStream.listen((state) {
      if (!mounted) return;
      final isBuffering = state == ProcessingState.loading || state == ProcessingState.buffering;
      if (isBuffering && !_shimmerController.isAnimating) {
        _shimmerController.repeat();
      } else if (!isBuffering && _shimmerController.isAnimating) {
        _shimmerController.stop();
      }
    });
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  String _getStatusText(PlayerState playerState) {
    if (playerState.playing) return 'Playing';

    switch (playerState.processingState) {
      case ProcessingState.loading:
      case ProcessingState.buffering:
        return 'Buffering...';
      case ProcessingState.completed:
        return 'Finished';
      case ProcessingState.idle:
        return 'Idle';
      case ProcessingState.ready:
        return 'Ready';
    }
  }

  Color _getBufferHealthColor(double health) {
    if (health >= 80) return Colors.greenAccent;
    if (health >= 50) return Colors.yellow;
    if (health >= 20) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.black.withValues(alpha: 0.4),
      child: SafeArea(
        top: true,
        bottom: false,
        child: StreamBuilder<PlayerState>(
          stream: widget.provider.playerStateStream,
          builder: (context, stateSnapshot) {
            final playerState = stateSnapshot.data;
            if (playerState == null) return const SizedBox(height: 24);

            final bufferHealth = widget.provider.getCurrentBufferHealth();
            final healthColor = _getBufferHealthColor(bufferHealth);
            final statusText = _getStatusText(playerState);
            final isBuffering = playerState.processingState == ProcessingState.loading ||
                playerState.processingState == ProcessingState.buffering;

            return SizedBox(
              height: 24, // Give the bar a consistent height
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // The background of the bar
                  Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade800,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  // The colored buffer health indicator
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: (bufferHealth / 100).clamp(0.0, 1.0),
                      child: Container(
                        height: 10,
                        decoration: BoxDecoration(
                          color: healthColor,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),
                  ),
                  // The shimmer effect that plays during buffering
                  if (isBuffering)
                    AnimatedBuilder(
                      animation: _shimmerController,
                      builder: (context, child) {
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: 1.0,
                            child: Transform.translate(
                              offset: Offset(MediaQuery.of(context).size.width * (_shimmerController.value - 0.5) * 1.5, 0),
                              child: Container(
                                width: 50,
                                height: 10,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(5),
                                  gradient: LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: [
                                      Colors.white.withValues(alpha: 0.0),
                                      Colors.white.withValues(alpha: 0.3),
                                      Colors.white.withValues(alpha: 0.0),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  // The status text overlay
                  Text(
                    statusText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(color: Colors.black, blurRadius: 2)],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}