// lib/components/player/themed_progress_bar.dart

import 'package:flutter/material.dart';
import 'package:matrix/providers/track_player_provider.dart';

class ThemedProgressBar extends StatelessWidget {
  final TrackPlayerProvider provider;
  // --- PARAMETERS FOR THEME COLORS ---
  final Color activeColor;
  final Color shadowColor;
  final Color bufferColor;
  final Color overlayColor;

  const ThemedProgressBar({
    super.key,
    required this.provider,
    required this.activeColor,
    required this.shadowColor,
    required this.bufferColor,
    required this.overlayColor,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration?>(
      stream: provider.positionStream,
      builder: (context, positionSnapshot) {
        final position = positionSnapshot.data ?? Duration.zero;

        return StreamBuilder<Duration?>(
          stream: provider.durationStream,
          builder: (context, durationSnapshot) {
            final duration = durationSnapshot.data ?? Duration.zero;

            return Row(
              children: [
                // Current position on the left
                Text(
                  provider.formattedCurrentDuration,
                  style: TextStyle(
                    color: activeColor, // <-- USE PARAMETER
                    shadows: [
                      Shadow(color: shadowColor, blurRadius: 3), // <-- USE PARAMETER
                      Shadow(color: shadowColor, blurRadius: 6), // <-- USE PARAMETER
                    ],
                  ),
                ),

                // Enhanced Slider with Buffer Visualization
                Expanded(
                  child: _buildEnhancedSlider(context, position, duration),
                ),

                // Total duration on the right
                Text(
                  provider.formattedTotalDuration,
                  style: TextStyle(
                    color: activeColor, // <-- USE PARAMETER
                    shadows: [
                      Shadow(color: shadowColor, blurRadius: 3), // <-- USE PARAMETER
                      Shadow(color: shadowColor, blurRadius: 6), // <-- USE PARAMETER
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Enhanced slider with buffer visualization
  Widget _buildEnhancedSlider(BuildContext context, Duration position, Duration duration) {
    return StreamBuilder<Duration>(
      stream: provider.bufferedPositionStream,
      builder: (context, bufferedSnapshot) {
        final bufferedPosition = bufferedSnapshot.data ?? Duration.zero;

        return Stack(
          alignment: Alignment.centerLeft,
          children: [
            // Buffer track (behind the main slider)
            if (duration.inSeconds > 0)
              Container(
                height: 4,
                margin: const EdgeInsets.symmetric(horizontal: 24),
                child: LinearProgressIndicator(
                  value: (bufferedPosition.inSeconds / duration.inSeconds).clamp(0.0, 1.0),
                  backgroundColor: Colors.grey[800],
                  valueColor: AlwaysStoppedAnimation<Color>(bufferColor), // <-- USE PARAMETER
                ),
              ),

            // Main slider (on top)
            Semantics(
              label: 'Seek slider',
              value: '${provider.formattedCurrentDuration} of ${provider.formattedTotalDuration}',
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: activeColor, // <-- USE PARAMETER
                  inactiveTrackColor: Colors.transparent,
                  thumbColor: activeColor, // <-- USE PARAMETER
                  overlayColor: overlayColor, // <-- USE PARAMETER
                  trackHeight: 4.0,
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 10.0),
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
                ),
                child: Slider(
                  value: position.inSeconds.toDouble().clamp(0.0, duration.inSeconds.toDouble()),
                  min: 0.0,
                  max: duration.inSeconds.toDouble(),
                  onChanged: (value) {
                    provider.seekTo(Duration(seconds: value.toInt()));
                  },
                  label: provider.formattedCurrentDuration,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}