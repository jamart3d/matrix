// lib/components/shows/show_tile.dart

import 'package:flutter/material.dart';
import 'package:matrix/components/shows/track_tile.dart';
import 'package:matrix/helpers/shows_helper.dart';
import 'package:matrix/models/show.dart';
import 'package:matrix/providers/album_settings_provider.dart';
import 'package:matrix/providers/track_player_provider.dart';
import 'package:matrix/providers/enums.dart';
import 'package:matrix/routes.dart';
import 'package:marquee/marquee.dart';
import 'package:provider/provider.dart';

class ShowTile extends StatelessWidget {
  final Show show;
  final String? currentlyExpandedId;
  final Function(bool, String) onExpansionChanged;

  const ShowTile({
    super.key,
    required this.show,
    required this.currentlyExpandedId,
    required this.onExpansionChanged,
  });

  String _formatDateHumanReadable(String date) {
    try {
      final dateTime = DateTime.parse(date);
      const List<String> monthNames = [
        'January', 'February', 'March', 'April', 'May', 'June', 'July',
        'August', 'September', 'October', 'November', 'December'
      ];
      final month = monthNames[dateTime.month - 1];
      final day = dateTime.day;
      final year = dateTime.year;
      return '$month $day, $year';
    } catch (e) {
      return date;
    }
  }

  @override
  Widget build(BuildContext context) {
    final playerProvider = context.watch<TrackPlayerProvider>();
    final settings = context.watch<AlbumSettingsProvider>();
    final isCurrentShow = playerProvider.currentTrack?.shnid != null &&
        show.sources.containsKey(playerProvider.currentTrack!.shnid);

    final bool isLargeFont = settings.showsPageFontSize == ShowsPageFontSize.large;
    final double? titleFontSize = isLargeFont ? 20.0 : null;
    final double? subtitleFontSize = isLargeFont ? 16.0 : null;
    final double marqueeHeight = isLargeFont ? 24.0 : 20.0;

    final titleStyle = TextStyle(
      color: isCurrentShow ? Colors.yellow : Colors.white,
      fontWeight: FontWeight.bold,
      fontSize: titleFontSize,
    );

    final formattedDate = _formatDateHumanReadable(show.date);
    final subtitleText = show.sourceCount > 1
        ? "$formattedDate (${show.sourceCount} sources)"
        : formattedDate;

    final bool isShowExpanded = currentlyExpandedId?.startsWith(show.uniqueId) ?? false;

    return GestureDetector(
      onLongPress: () {
        playTracklist(playerProvider, show.primaryTracks);
        Navigator.pushNamed(context, Routes.showsMusicPlayerPage);
      },
      child: Card(
        color: isCurrentShow ? Colors.yellow.withOpacity(0.2) : Colors.black.withOpacity(0.4),
        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: ExpansionTile(
          key: ValueKey('${show.uniqueId}_$isShowExpanded'),
          initiallyExpanded: isShowExpanded,
          controlAffinity: ListTileControlAffinity.leading,
          onExpansionChanged: (expanding) => onExpansionChanged(expanding, show.uniqueId),
          title: LayoutBuilder(
            builder: (context, constraints) {
              final textPainter = TextPainter(
                text: TextSpan(text: show.venue, style: titleStyle),
                maxLines: 1,
                textDirection: TextDirection.ltr,
              )..layout(minWidth: 0, maxWidth: double.infinity);

              if (textPainter.width > constraints.maxWidth) {
                return SizedBox(
                  height: marqueeHeight,
                  child: Marquee(
                    text: show.venue,
                    style: titleStyle,
                    velocity: 30.0,
                    blankSpace: 20.0,
                    startAfter: const Duration(seconds: 1),
                    pauseAfterRound: const Duration(seconds: 2),
                    fadingEdgeStartFraction: 0.1,
                    fadingEdgeEndFraction: 0.1,
                  ),
                );
              } else {
                return Text(show.venue, style: titleStyle);
              }
            },
          ),
          subtitle: Text(
            subtitleText,
            style: TextStyle(
              color: isCurrentShow ? Colors.yellow.withOpacity(0.8) : Colors.grey.shade300,
              fontSize: subtitleFontSize,
            ),
          ),
          children: _buildExpansionChildren(context, playerProvider),
        ),
      ),
    );
  }

  List<Widget> _buildExpansionChildren(BuildContext context, TrackPlayerProvider playerProvider) {
    if (show.sourceCount == 1) {
      return show.sources.values.first
          .map((track) => TrackTile(track: track, sourceTracks: show.sources.values.first))
          .toList();
    } else {
      return show.sources.entries.map((entry) {
        final shnid = entry.key;
        final sourceTracks = entry.value;
        final isCurrentSource = playerProvider.currentTrack?.shnid == shnid;
        final String shnidId = '${show.uniqueId}_$shnid';
        final bool isShnidExpanded = currentlyExpandedId == shnidId;

        return ExpansionTile(
          key: ValueKey('${shnidId}_$isShnidExpanded'),
          initiallyExpanded: isShnidExpanded,
          controlAffinity: ListTileControlAffinity.leading,
          onExpansionChanged: (expanding) => onExpansionChanged(expanding, shnidId),
          tilePadding: const EdgeInsets.only(left: 32.0, right: 16.0),
          title: Text("SHNID: $shnid",
              style: TextStyle(
                  color: isCurrentSource ? Colors.yellow : Colors.white70,
                  fontWeight: isCurrentSource ? FontWeight.bold : FontWeight.normal,
                  fontStyle: FontStyle.italic,
                  fontSize: 14)),
          children: sourceTracks
              .map((track) => TrackTile(track: track, sourceTracks: sourceTracks))
              .toList(),
        );
      }).toList();
    }
  }
}