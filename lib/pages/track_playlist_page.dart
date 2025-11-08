// lib/pages/track_playlist_page.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:matrix/providers/album_settings_provider.dart';
import 'package:matrix/providers/track_player_provider.dart';
import 'package:matrix/utils/duration_formatter.dart';
import 'package:matrix/utils/string_formatter.dart';
import 'package:provider/provider.dart';
import 'package:logger/logger.dart';
import 'package:marquee/marquee.dart';
import 'package:matrix/utils/album_title_parser.dart';

class TrackPlaylistPage extends StatefulWidget {
  const TrackPlaylistPage({super.key});

  @override
  State<TrackPlaylistPage> createState() => _TrackPlaylistPageState();
}

class _TrackPlaylistPageState extends State<TrackPlaylistPage> {
  final _logger = Logger();

  /// Formats the album/show title based on its structure.
  String _getFormattedTitle(String rawTitle) {
    if (rawTitle.startsWith('Live at')) {
      // It's a "Show" title, use the existing parser.
      final venue = AlbumTitleParser.extractVenue(rawTitle);
      final date = AlbumTitleParser.extractDate(rawTitle);
      return '$venue - $date';
    } else {
      // It's likely an "Album" title from Seamons (e.g., "1982-04-10 - Capitol Theatre").
      final parts = rawTitle.split(' - ');
      if (parts.length == 2) {
        final dateStr = parts[0];
        final venueStr = parts[1];
        // The string_formatter has a utility for this exact date format.
        final formattedDate = formatDateHumanReadable(dateStr);
        return '$venueStr - $formattedDate';
      }
    }
    // Fallback for any other format.
    return rawTitle;
  }

  @override
  Widget build(BuildContext context) {
    final trackPlayerProvider = context.watch<TrackPlayerProvider>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        centerTitle: true,
        forceMaterialTransparency: true,
        foregroundColor: Colors.white,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: LayoutBuilder(
          builder: (context, constraints) {
            final displayTitle = _getFormattedTitle(trackPlayerProvider.currentAlbumTitle);
            const style = TextStyle(fontSize: 18);

            final textPainter = TextPainter(
              text: TextSpan(text: displayTitle, style: style),
              maxLines: 1,
              textDirection: TextDirection.ltr,
            )..layout(minWidth: 0, maxWidth: double.infinity);

            if (textPainter.width > constraints.maxWidth) {
              return SizedBox(
                height: 30,
                child: Marquee(
                  text: displayTitle,
                  style: style,
                  velocity: 30.0,
                  blankSpace: 20.0,
                ),
              );
            }
            return Text(displayTitle, style: style);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Clear Playlist',
            onPressed: () => _showClearPlaylistDialog(context, trackPlayerProvider),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(trackPlayerProvider.currentAlbumArt),
                fit: BoxFit.cover,
                onError: (exception, stackTrace) {
                  _logger.e(
                    "Failed to load background image: ${trackPlayerProvider.currentAlbumArt}",
                    error: exception,
                    stackTrace: stackTrace,
                  );
                },
              ),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
              child: Container(
                color: Colors.black.withOpacity(0.5),
              ),
            ),
          ),
          _buildTrackList(trackPlayerProvider),
        ],
      ),
    );
  }

  Widget _buildTrackList(TrackPlayerProvider trackPlayerProvider) {
    final settingsProvider = context.watch<AlbumSettingsProvider>();

    if (trackPlayerProvider.playlist.isEmpty) {
      return const Center(
        child: Text( 'Playlist is empty', style: TextStyle(color: Colors.white, fontSize: 18)),
      );
    }

    return SafeArea(
      child: ListView.builder(
        itemCount: trackPlayerProvider.playlist.length,
        itemBuilder: (context, index) {
          final track = trackPlayerProvider.playlist[index];
          final isCurrentlyPlayingTrack = index == trackPlayerProvider.currentIndex;

          final formattedTitle = formatTrackTitle(
            track.trackName,
            hideNumber: settingsProvider.hideLeadingTrackNumberInTitle,
          );

          return ListTile(
            leading: settingsProvider.showTrackNumbersInLists
                ? Text(
              track.trackNumber,
              style: TextStyle(
                color: isCurrentlyPlayingTrack ? Colors.yellow.withOpacity(0.9) : Colors.white70,
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            )
                : null,
            title: Text(
              formattedTitle,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isCurrentlyPlayingTrack ? Colors.yellow : Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            trailing: Text(
              formatDurationSeconds(track.trackDuration),
              style: TextStyle(
                color: isCurrentlyPlayingTrack ? Colors.yellow.withOpacity(0.8) : Colors.white70,
              ),
            ),
            onTap: () {
              if (!isCurrentlyPlayingTrack) {
                // Correctly seek to the index instead of reloading the playlist
                trackPlayerProvider.seekToIndex(index);
              }
            },
            selected: isCurrentlyPlayingTrack,
            selectedTileColor: Colors.yellow.withOpacity(0.1),
          );
        },
      ),
    );
  }

  void _showClearPlaylistDialog(BuildContext context, TrackPlayerProvider provider) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Clear Playlist'),
          content: const Text('Are you sure you want to clear the current playlist?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await provider.clearPlaylist();
                if (mounted) {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              },
              child: const Text('Clear', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
