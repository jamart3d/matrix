
import 'package:flutter/material.dart';
import 'package:matrix/providers/track_player_provider.dart';
import 'package:provider/provider.dart';
import 'package:matrix/components/player/shows_player/shows_player_track_tile.dart';

class ShowsPlayerTrackList extends StatelessWidget {
  final Animation<double> slideAnimation;
  final Animation<double> fadeAnimation;
  final bool hasAnimatedOnce;
  final Color themeColor;
  final List<Shadow> glowShadows;

  const ShowsPlayerTrackList({
    super.key,
    required this.slideAnimation,
    required this.fadeAnimation,
    required this.hasAnimatedOnce,
    required this.themeColor,
    required this.glowShadows,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TrackPlayerProvider>();
    final playlist = provider.playlist;
    final currentIndex = provider.currentIndex;

    if (playlist.isEmpty) {
      return const SliverFillRemaining(
        child: Center(
          child:
          Text('Playlist is empty', style: TextStyle(color: Colors.white)),
        ),
      );
    }

    return SliverList.separated(
      itemCount: playlist.length,
      itemBuilder: (context, index) {
        final track = playlist[index];
        final isCurrentlyPlaying = index == currentIndex;
        return RepaintBoundary(
          child: AnimatedBuilder(
            animation: slideAnimation,
            builder: (context, child) {
              final offset = isCurrentlyPlaying && hasAnimatedOnce
                  ? Offset(20.0 * (1.0 - slideAnimation.value), 0.0)
                  : Offset.zero;

              final opacity = isCurrentlyPlaying && hasAnimatedOnce
                  ? fadeAnimation
                  : const AlwaysStoppedAnimation<double>(1.0);

              return FadeTransition(
                opacity: opacity,
                child: Transform.translate(
                  offset: offset,
                  child: ShowsPlayerTrackTile(
                    track: track,
                    index: index,
                    isCurrentlyPlaying: isCurrentlyPlaying,
                    themeColor: themeColor,
                    glowShadows: glowShadows,
                  ),
                ),
              );
            },
          ),
        );
      },
      separatorBuilder: (context, index) => const Divider(
        height: 0.5,
        color: Colors.white10,
        indent: 16,
        endIndent: 16,
      ),
    );
  }
}