import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:matrix/components/player/buffer_info_panel.dart';
import 'package:matrix/components/player/loading_timeout_controls.dart';
import 'package:matrix/components/player/themed_shows_progress_bar.dart';
import 'package:matrix/providers/album_settings_provider.dart';
import 'package:matrix/providers/track_player_provider.dart';
import 'package:provider/provider.dart';

class ShowsPlayerControlsArea extends StatelessWidget {
  final Animation<double> trackChangeAnimation;
  final Animation<double> pulseAnimation;
  final Color themeColor;
  final List<Shadow> glowShadows;

  const ShowsPlayerControlsArea({
    super.key,
    required this.trackChangeAnimation,
    required this.pulseAnimation,
    required this.themeColor,
    required this.glowShadows,
  });

  @override
  Widget build(BuildContext context) {
    final trackPlayerProvider = context.watch<TrackPlayerProvider>();
    final settingsProvider = context.watch<AlbumSettingsProvider>();

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.0),
                Colors.black.withOpacity(0.7),
              ],
              stops: const [0.0, 0.4],
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (trackPlayerProvider.isLoadingTimeout)
                LoadingTimeoutControls(
                  provider: trackPlayerProvider,
                  themeColor: themeColor,
                )
              else
                _buildPlayerTransportControls(context),
              const Gap(8),
              ThemedShowsProgressBar(provider: trackPlayerProvider),
              const Gap(6),
              if (settingsProvider.showBufferInfo)
                BufferInfoPanel(provider: trackPlayerProvider),
              const Gap(8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerTransportControls(BuildContext context) {
    final provider = context.read<TrackPlayerProvider>();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          icon: const Icon(Icons.skip_previous, size: 48.0, color: Colors.white),
          onPressed: () {
            HapticFeedback.lightImpact();
            provider.previous();
          },
        ),
        _buildPlayPauseButton(context),
        IconButton(
          icon: const Icon(Icons.skip_next, size: 48.0, color: Colors.white),
          onPressed: () {
            HapticFeedback.lightImpact();
            provider.next();
          },
        ),
      ],
    );
  }

  Widget _buildPlayPauseButton(BuildContext context) {
    final provider = context.watch<TrackPlayerProvider>();
    const heroTag = 'play_pause_button_hero_shows';

    Widget buttonContent;
    if (provider.isLoading) {
      buttonContent = CircularProgressIndicator(
        strokeWidth: 3.0,
        valueColor: AlwaysStoppedAnimation<Color>(themeColor),
      );
    } else {
      buttonContent = AnimatedBuilder(
        animation: Listenable.merge([trackChangeAnimation, pulseAnimation]),
        builder: (context, child) {
          final scale = pulseAnimation.value *
              (1.0 + (0.1 * (1.0 - trackChangeAnimation.value)));
          return Transform.scale(
            scale: scale,
            child: Icon(
              provider.isPlaying
                  ? Icons.pause_circle_filled
                  : Icons.play_circle_fill,
              key: ValueKey(provider.isPlaying),
              size: 64.0,
              color: themeColor,
              shadows: glowShadows,
            ),
          );
        },
      );
    }

    return Hero(
      tag: heroTag,
      child: Material(
        color: Colors.transparent,
        child: GestureDetector(
          onTap: () {
            if (provider.isLoading) return;
            HapticFeedback.mediumImpact();
            provider.togglePlayPause();
          },
          child: SizedBox(
            width: 64.0,
            height: 64.0,
            child: Center(child: buttonContent),
          ),
        ),
      ),
    );
  }
}

extension _PlayerActions on TrackPlayerProvider {
  void togglePlayPause() {
    if (isPlaying) {
      pause();
    } else {
      play();
    }
  }
}