import 'package:flutter/material.dart';
import 'package:huntrix/providers/track_player_provider.dart';

class ProgressBar extends StatelessWidget {
  final TrackPlayerProvider provider;

  const ProgressBar({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      height: 30.0,
      child: StreamBuilder<Duration?>(
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
                    provider.formatDuration(position),
                  ),

                  // Slider
                  Expanded(
                    child: Semantics(
                      label: 'Seek slider',
                      value:
                          '${provider.formatDuration(position)} of ${provider.formatDuration(duration)}',
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          thumbShape:
                              const RoundSliderThumbShape(enabledThumbRadius: 4.0),
                          overlayShape:
                              const RoundSliderOverlayShape(overlayRadius: 10.0),
                          valueIndicatorShape:
                              const PaddleSliderValueIndicatorShape(),
                          valueIndicatorTextStyle: const TextStyle(
                            color: Colors.white,
                          ),
                          showValueIndicator: duration != Duration.zero
                              ? ShowValueIndicator.always
                              : ShowValueIndicator.never,
                        ),
                        child: Slider(
                          value: position.inSeconds.toDouble(),
                          min: 0.0,
                          max: duration.inSeconds.toDouble(),
                          onChanged: (value) {
                            provider.seekTo(Duration(seconds: value.toInt()));
                          },
                          label: provider.formatDuration(position),
                        ),
                      ),
                    ),
                  ),

                  // Total duration on the right
                  Text(
                    provider.formatDuration(duration),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
