import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:matrix/helpers/album_helper.dart'; // Import for playTrackFromAlbum
import 'package:matrix/providers/track_player_provider.dart';
import 'package:matrix/utils/duration_formatter.dart';
import 'package:provider/provider.dart';

class TrackPlaylistPage extends StatefulWidget {
  const TrackPlaylistPage({super.key});

  @override
  State<TrackPlaylistPage> createState() => _TrackPlaylistPageState();
}

class _TrackPlaylistPageState extends State<TrackPlaylistPage> {
  @override
  Widget build(BuildContext context) {
    // Use `watch` here to ensure the page rebuilds when the playlist changes.
    final trackPlayerProvider = context.watch<TrackPlayerProvider>();
    final currentTrack = trackPlayerProvider.currentTrack;

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
            icon: const Icon(Icons.delete_sweep), // A more descriptive icon
            tooltip: 'Clear Playlist',
            onPressed: () => _showClearPlaylistDialog(context, trackPlayerProvider),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Blurred Background
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(currentTrack?.albumArt ?? 'assets/images/t_steal.webp'),
                fit: BoxFit.cover,
              ),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
              child: Container(
                color: Colors.black.withOpacity(0.5),
              ),
            ),
          ),
          // Track List
          _buildTrackList(trackPlayerProvider),
        ],
      ),
    );
  }

  Widget _buildTrackList(TrackPlayerProvider trackPlayerProvider) {
    final Color shadowColor = Colors.redAccent;

    if (trackPlayerProvider.playlist.isEmpty) {
      return const Center(
        child: Text(
          'Playlist is empty',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      );
    }
    
    // Use SafeArea to avoid system UI (notches, navigation bars)
    return SafeArea(
      child: ListView.builder(
        itemCount: trackPlayerProvider.playlist.length,
        itemBuilder: (context, index) {
          final track = trackPlayerProvider.playlist[index];
          final isCurrentlyPlayingTrack = index == trackPlayerProvider.currentIndex;

          return ListTile(
            title: Text(
              track.trackName,
              softWrap: false, // Prevent wrapping for a cleaner look
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isCurrentlyPlayingTrack ? Colors.yellow : Colors.white,
                fontWeight: FontWeight.bold,
                shadows: isCurrentlyPlayingTrack
                    ? [
                        Shadow(color: shadowColor, blurRadius: 4),
                      ]
                    : null,
              ),
            ),
            trailing: Text(
              formatDurationSeconds(track.trackDuration),
              style: TextStyle(
                color: isCurrentlyPlayingTrack ? Colors.yellow.withOpacity(0.8) : Colors.white70,
                fontWeight: isCurrentlyPlayingTrack ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            // Use on tap for playing, as it's more intuitive than long press.
            onTap: () {
              if (!isCurrentlyPlayingTrack) {
                // Use the robust helper function to handle playback.
                playTrackFromAlbum(trackPlayerProvider.playlist, track);
              }
            },
            selected: isCurrentlyPlayingTrack,
            selectedTileColor: Colors.white.withOpacity(0.1),
          );
        },
      ),
    );
  }
  
  /// Refactored: Shows a confirmation dialog to clear the playlist.
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
                  // Pop all pages until we get to the root of the navigation stack.
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