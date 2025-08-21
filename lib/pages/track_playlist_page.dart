// lib/pages/track_playlist_page.dart

import 'dart:ui';
import 'package:flutter/material.dart';

import 'package:matrix/helpers/album_helper.dart';
import 'package:matrix/providers/track_player_provider.dart';
import 'package:matrix/utils/duration_formatter.dart';
import 'package:provider/provider.dart';
import 'package:logger/logger.dart';

class TrackPlaylistPage extends StatefulWidget {
  const TrackPlaylistPage({super.key});

  @override
  State<TrackPlaylistPage> createState() => _TrackPlaylistPageState();
}

class _TrackPlaylistPageState extends State<TrackPlaylistPage> {
  final _logger = Logger();

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
        title: Text(trackPlayerProvider.currentAlbumTitle),
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

          return ListTile(
            leading: Text(
              track.trackNumber,
              style: TextStyle(
                color: isCurrentlyPlayingTrack ? Colors.yellow.withOpacity(0.9) : Colors.white70,
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
            title: Text(
              track.trackName,
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
                // ============================================================
                // === THIS CALL WILL NOW WORK BECAUSE OF THE IMPORT ABOVE    ===
                // ============================================================
                playTrackFromAlbum(trackPlayerProvider.playlist, track);
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