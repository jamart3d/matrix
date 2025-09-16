// lib/components/shows/track_tile.dart

import 'package:flutter/material.dart';
import 'package:matrix/helpers/shows_helper.dart';
import 'package:matrix/models/track.dart';
import 'package:matrix/providers/album_settings_provider.dart';
import 'package:matrix/providers/track_player_provider.dart';
import 'package:matrix/providers/enums.dart';
import 'package:matrix/routes.dart';
import 'package:matrix/utils/duration_formatter.dart';
import 'package:matrix/utils/string_formatter.dart';
import 'package:provider/provider.dart';

class TrackTile extends StatelessWidget {
  final Track track;
  final List<Track> sourceTracks;

  const TrackTile({
    super.key,
    required this.track,
    required this.sourceTracks,
  });

  @override
  Widget build(BuildContext context) {
    final playerProvider = context.watch<TrackPlayerProvider>();
    final settingsProvider = context.watch<AlbumSettingsProvider>();
    final bool isCurrentlyPlaying = playerProvider.currentTrack == track;

    final formattedTitle = formatTrackTitle(
      track.trackName,
      hideNumber: settingsProvider.hideLeadingTrackNumberInTitle,
    );

    final bool isLargeFont = settingsProvider.showsPageFontSize == ShowsPageFontSize.large;
    final double? titleFontSize = isLargeFont ? 18.0 : null;
    final double? detailFontSize = isLargeFont ? 15.0 : null;

    return Container(
      color: isCurrentlyPlaying ? Colors.yellow.withValues(alpha:0.15) : Colors.transparent,
      child: ListTile(
        contentPadding: EdgeInsets.only(
            left: settingsProvider.showTrackNumbersInLists ? 48.0 : 16.0,
            right: 16.0),
        leading: settingsProvider.showTrackNumbersInLists
            ? Text(
          track.trackNumber,
          style: TextStyle(
            color: isCurrentlyPlaying ? Colors.yellow : Colors.grey.shade300,
            fontSize: detailFontSize,
          ),
        )
            : null,
        title: Text(
          formattedTitle,
          style: TextStyle(
            color: isCurrentlyPlaying ? Colors.yellow : Colors.white,
            fontSize: titleFontSize,
          ),
        ),
        trailing: Text(
          formatDurationSeconds(track.trackDuration),
          style: TextStyle(
            color: isCurrentlyPlaying ? Colors.yellow.withValues(alpha:0.8) : Colors.grey.shade400,
            fontSize: detailFontSize,
          ),
        ),
        onTap: () {
          playTracklistFrom(playerProvider, sourceTracks, track);
          Navigator.pushNamed(context, Routes.showsMusicPlayerPage);
        },
        dense: !isLargeFont,
      ),
    );
  }
}