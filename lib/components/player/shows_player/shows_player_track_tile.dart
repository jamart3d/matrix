import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:marquee/marquee.dart';
import 'package:matrix/providers/album_settings_provider.dart';
import 'package:matrix/providers/track_player_provider.dart';
import 'package:matrix/utils/duration_formatter.dart';
import 'package:matrix/utils/string_formatter.dart';
import 'package:provider/provider.dart';

class ShowsPlayerTrackTile extends StatelessWidget {
  final dynamic track;
  final int index;
  final bool isCurrentlyPlaying;
  final Color themeColor;
  final List<Shadow> glowShadows;

  const ShowsPlayerTrackTile({
    super.key,
    required this.track,
    required this.index,
    required this.isCurrentlyPlaying,
    required this.themeColor,
    required this.glowShadows,
  });

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<AlbumSettingsProvider>();
    final playerProvider = context.watch<TrackPlayerProvider>();

    final formattedTitle = formatTrackTitle(
      track.trackName,
      hideNumber: settingsProvider.hideLeadingTrackNumberInTitle,
    );

    final bool isThisTrackInTimeout =
        isCurrentlyPlaying && playerProvider.isLoadingTimeout;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: isCurrentlyPlaying
            ? Colors.white.withValues(alpha:0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8.0),
        border: isCurrentlyPlaying
            ? Border.all(color: themeColor.withValues(alpha: 0.3), width: 1)
            : null,
      ),
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 0.5),
      child: InkWell(
        onTap: () {
          if (!isCurrentlyPlaying) {
            HapticFeedback.lightImpact();
            context.read<TrackPlayerProvider>().seekToIndex(index);
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 12.0),
          child: Row(
            children: [
              if (settingsProvider.showTrackNumbersInLists)
                _buildTrackNumber(context),
              _buildTrackTitle(context, formattedTitle),
              const SizedBox(width: 16),
              _buildTrailingWidget(isThisTrackInTimeout),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrackNumber(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 16.0),
      child: Text(
        track.trackNumber,
        style: TextStyle(
          color: isCurrentlyPlaying ? themeColor.withValues(alpha: 0.8) : Colors.white70,
          fontSize: 24.0,
          shadows: isCurrentlyPlaying ? glowShadows : null,
        ),
      ),
    );
  }

  Widget _buildTrackTitle(BuildContext context, String formattedTitle) {
    return Expanded(
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final style = TextStyle(
            color: isCurrentlyPlaying ? themeColor : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: isCurrentlyPlaying ? 28.0 : 26.0,
            shadows: isCurrentlyPlaying ? glowShadows : null,
          );

          final textPainter = TextPainter(
            text: TextSpan(text: formattedTitle, style: style),
            maxLines: 1,
            textDirection: TextDirection.ltr,
          )..layout(minWidth: 0, maxWidth: double.infinity);

          if (textPainter.width > constraints.maxWidth) {
            return SizedBox(
              height: 42,
              child: Marquee(
                text: formattedTitle,
                style: style,
                velocity: 70.0,
                blankSpace: 30.0,
                startAfter: const Duration(seconds: 1),
                pauseAfterRound: const Duration(seconds: 2),
                fadingEdgeStartFraction: 0.1,
                fadingEdgeEndFraction: 0.1,
              ),
            );
          } else {
            return Text(
              formattedTitle,
              style: style,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
            );
          }
        },
      ),
    );
  }

  Widget _buildTrailingWidget(bool isThisTrackInTimeout) {
    if (isThisTrackInTimeout) {
      return const Icon(
        Icons.wifi_tethering_error_rounded,
        color: Colors.orange,
        size: 28,
      );
    } else {
      return Text(
        formatDurationSeconds(track.trackDuration),
        style: TextStyle(
          color: isCurrentlyPlaying ? themeColor.withValues(alpha: 0.8) : Colors.white70,
          shadows: isCurrentlyPlaying ? glowShadows : null,
          fontSize: 24.0,
        ),
      );
    }
  }
}