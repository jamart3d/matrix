// lib/components/player/themed_shows_progress_bar.dart

import 'package:flutter/material.dart';
import 'package:matrix/providers/track_player_provider.dart';

// This is a new widget, copied from ProgressBar and re-themed for the Shows page.
class ThemedShowsProgressBar extends StatelessWidget {
  final TrackPlayerProvider provider;

  const ThemedShowsProgressBar({
    super.key,
    required this.provider,
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
                // Current position on the left (already themed correctly)
                Text(
                  provider.formattedCurrentDuration,
                  style: const TextStyle(
                    color: Colors.yellow,
                    shadows: [
                      Shadow(color: Colors.redAccent, blurRadius: 3),
                      Shadow(color: Colors.redAccent, blurRadius: 6),
                    ],
                  ),
                ),

                // Enhanced Slider with Buffer Visualization
                Expanded(
                  child: _buildEnhancedSlider(context, position, duration),
                ),

                // Total duration on the right (already themed correctly)
                Text(
                  provider.formattedTotalDuration,
                  style: const TextStyle(
                    color: Colors.yellow,
                    shadows: [
                      Shadow(color: Colors.redAccent, blurRadius: 3),
                      Shadow(color: Colors.redAccent, blurRadius: 6),
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
                margin: const EdgeInsets.symmetric(horizontal: 24), // Approx match to slider's own padding
                child: LinearProgressIndicator(
                  value: (bufferedPosition.inSeconds / duration.inSeconds).clamp(0.0, 1.0),
                  backgroundColor: Colors.grey[800],
                  // --- THEME CHANGE HERE ---
                  // Changed the buffer color to a dim yellow to match the theme.
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.yellow.withOpacity(0.3)),
                ),
              ),

            // Main slider (on top)
            Semantics(
              label: 'Seek slider',
              value: '${provider.formattedCurrentDuration} of ${provider.formattedTotalDuration}',
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  // --- THEME CHANGE HERE ---
                  // Ensured all slider colors match the yellow/red theme.
                  activeTrackColor: Colors.yellow,
                  inactiveTrackColor: Colors.transparent, // Keep this transparent to show the buffer bar
                  thumbColor: Colors.yellow,
                  overlayColor: Colors.redAccent.withOpacity(0.2), // The glow when you press the thumb
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