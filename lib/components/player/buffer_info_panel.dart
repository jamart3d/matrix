// lib/components/player/buffer_info_panel.dart

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:matrix/providers/track_player_provider.dart';

class BufferInfoPanel extends StatelessWidget {
  final TrackPlayerProvider provider;

  const BufferInfoPanel({
    super.key,
    required this.provider,
  });

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
      color: Colors.black.withOpacity(0.4),
      child: SafeArea(
        top: true,
        bottom: false,
        child: Row(
          children: [
            // This part updates when the processing state changes
            Expanded(
              child: StreamBuilder<ProcessingState>(
                stream: provider.processingStateStream,
                builder: (context, stateSnapshot) {
                  return RichText(
                    text: TextSpan(
                      style: DefaultTextStyle.of(context).style.copyWith(fontSize: 12),
                      children: <TextSpan>[
                        const TextSpan(
                          text: 'Status: ',
                          style: TextStyle(color: Colors.white),
                        ),
                        TextSpan(
                          text: stateSnapshot.data?.name ?? 'idle',
                          style: const TextStyle(color: Colors.green),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // ================== MODIFICATION HERE ==================
            // This part now updates whenever the buffered position changes,
            // making it truly realtime.
            Expanded(
              child: StreamBuilder<Duration>(
                stream: provider.bufferedPositionStream,
                builder: (context, snapshot) {
                  // We recalculate the health on every stream event
                  final bufferHealth = provider.getCurrentBufferHealth();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Buffer Health: ${bufferHealth.toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: _getBufferHealthColor(bufferHealth),
                          fontSize: 12,
                        ),
                      ),
                      LinearProgressIndicator(
                        value: bufferHealth / 100,
                        backgroundColor: Colors.grey[700],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getBufferHealthColor(bufferHealth),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}