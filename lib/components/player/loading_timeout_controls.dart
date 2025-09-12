// lib/components/player/loading_timeout_controls.dart

import 'package:flutter/material.dart';
import 'package:matrix/providers/track_player_provider.dart';

class LoadingTimeoutControls extends StatelessWidget {
  final TrackPlayerProvider provider;
  final Color themeColor;

  const LoadingTimeoutControls({
    super.key,
    required this.provider,
    required this.themeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (provider.loadingError != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              provider.loadingError!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.orange, fontSize: 12),
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            TextButton.icon(
              icon: Icon(Icons.refresh, color: themeColor),
              label: Text('Try Again', style: TextStyle(color: themeColor)),
              onPressed: provider.retryCurrentTrack,
            ),
            TextButton.icon(
              icon: const Icon(Icons.skip_next, color: Colors.white),
              label: const Text('Skip', style: TextStyle(color: Colors.white)),
              onPressed: provider.next,
            ),
          ],
        ),
      ],
    );
  }
}