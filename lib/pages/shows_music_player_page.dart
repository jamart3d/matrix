import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:huntrix/providers/track_player_provider.dart';
import 'package:huntrix/utils/duration_formatter.dart';
import 'package:huntrix/components/player/progress_bar.dart';

// Convert to a StatefulWidget to manage the ScrollController
class ShowsMusicPlayerPage extends StatefulWidget {
  const ShowsMusicPlayerPage({super.key});

  @override
  State<ShowsMusicPlayerPage> createState() => _ShowsMusicPlayerPageState();
}

class _ShowsMusicPlayerPageState extends State<ShowsMusicPlayerPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // After the first frame, scroll to the currently playing track.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final provider = context.read<TrackPlayerProvider>();
        _scrollToCurrent(provider.currentIndex);
      }
    });
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Helper method to scroll the list to the current index.
  void _scrollToCurrent(int index) {
    if (_scrollController.hasClients && index >= 0) {
      final itemHeight = 56.0; // Approximate height of a ListTile
      final targetOffset = (index * itemHeight) - (MediaQuery.of(context).size.height / 4);
      _scrollController.animateTo(
        targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final trackPlayerProvider = context.watch<TrackPlayerProvider>();

    return Scaffold(
      backgroundColor: Colors.black,
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
      body: Column(
        children: [
          // Track list takes up most of the space
          Expanded(
            child: _buildTrackList(context, trackPlayerProvider),
          ),
          // Progress bar and controls at the bottom
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.black,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Use your existing ProgressBar widget
                ProgressBar(provider: trackPlayerProvider),
                const SizedBox(height: 16.0),
                // Control buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Previous button
                    IconButton(
                      icon: const Icon(Icons.skip_previous, size: 48.0, color: Colors.white),
                      onPressed: () {
                        trackPlayerProvider.previous();
                      },
                    ),
                    // Play/Pause button
                    IconButton(
                      icon: Icon(
                        trackPlayerProvider.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                        size: 64.0,
                        color: Colors.yellow,
                      ),
                      onPressed: () {
                        if (trackPlayerProvider.isPlaying) {
                          trackPlayerProvider.pause();
                        } else {
                          trackPlayerProvider.play();
                        }
                      },
                    ),
                    // Next button
                    IconButton(
                      icon: const Icon(Icons.skip_next, size: 48.0, color: Colors.white),
                      onPressed: () {
                        trackPlayerProvider.next();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackList(BuildContext context, TrackPlayerProvider trackPlayerProvider) {
    final Color shadowColor = Colors.redAccent;
    final playlist = trackPlayerProvider.playlist;
    final currentIndex = trackPlayerProvider.currentIndex;

    if (playlist.isEmpty) {
      return const Center(
        child: Text('Playlist is empty', style: TextStyle(color: Colors.white, fontSize: 18)),
      );
    }
    
    return SafeArea(
      child: ListView.builder(
        controller: _scrollController,
        itemCount: playlist.length,
        itemBuilder: (context, index) {
          // **SAFETY CHECK:** Prevents the out of bounds error.
          if (index >= playlist.length) return const SizedBox.shrink();

          final track = playlist[index];
          final isCurrentlyPlayingTrack = index == currentIndex;

          return ListTile(
            title: Text(
              track.trackName,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isCurrentlyPlayingTrack ? Colors.yellow : Colors.white,
                fontWeight: FontWeight.bold,
                shadows: isCurrentlyPlayingTrack ? [Shadow(color: shadowColor, blurRadius: 4)] : null,
              ),
            ),
            leading: Text(
              track.trackNumber,
              style: TextStyle(
                color: isCurrentlyPlayingTrack ? Colors.yellow.withOpacity(0.8) : Colors.white70,
                fontSize: 14,
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
                trackPlayerProvider.replacePlaylistAndPlay(playlist, initialIndex: index);
              }
            },
            selected: isCurrentlyPlayingTrack,
            selectedTileColor: Colors.white.withOpacity(0.1),
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
                if (context.mounted) {
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