// lib/components/processing_state_indicator.dart

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:matrix/providers/track_player_provider.dart';
import 'package:provider/provider.dart';

class ProcessingStateIndicator extends StatelessWidget {
  const ProcessingStateIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final trackPlayerProvider = context.watch<TrackPlayerProvider>();

    return StreamBuilder<ProcessingState>(
      stream: trackPlayerProvider.processingStateStream,
      builder: (context, snapshot) {
        final processingState = snapshot.data;

        // When loading, show nothing. The FAB will handle it.
        if (processingState == ProcessingState.loading ||
            processingState == ProcessingState.buffering) {
          return const SizedBox.shrink();
        }

        // When playback is complete, show a yellow checkmark.
        if (processingState == ProcessingState.completed) {
          return const Icon(Icons.check_circle, color: Colors.yellow);
        }

        // --- THE FIX IS HERE ---
        // If the player is ready, show a green checkmark.
        if (processingState == ProcessingState.ready) {
          return const Icon(Icons.check_circle, color: Colors.green);
        }

        // If the player is idle (stopped and no track loaded), show nothing.
        // This covers the case after clearing the playlist.
        return const SizedBox.shrink();
      },
    );
  }
}