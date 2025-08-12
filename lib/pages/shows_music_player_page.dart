// lib/pages/shows_music_player_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:matrix/providers/album_settings_provider.dart';
import 'package:matrix/providers/track_player_provider.dart';
import 'package:matrix/utils/duration_formatter.dart';
import 'package:matrix/components/player/progress_bar.dart';
import 'package:marquee/marquee.dart';
import 'package:just_audio/just_audio.dart'; // Required for ProcessingState enum

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

  void _scrollToCurrent(int index) {
    if (_scrollController.hasClients && index >= 0) {
      final itemHeight = 56.0;
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
    final settingsProvider = context.watch<AlbumSettingsProvider>();

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        centerTitle: true,
        forceMaterialTransparency: true,
        foregroundColor: Colors.white,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: settingsProvider.marqueePlayerTitle
            ? SizedBox(
          height: 30,
          child: Marquee(
            text: trackPlayerProvider.currentAlbumTitle,
            style: const TextStyle(fontWeight: FontWeight.bold),
            velocity: 40.0,
            blankSpace: 30.0,
          ),
        )
            : Text(trackPlayerProvider.currentAlbumTitle),
        actions: [
          // Buffer status indicator
          _buildBufferStatusIndicator(trackPlayerProvider),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Clear Playlist',
            onPressed: () => _showClearPlaylistDialog(context, trackPlayerProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          // Buffer info panel (optional, can be toggled)
          if (settingsProvider.showBufferInfo)
            _buildBufferInfoPanel(trackPlayerProvider),
          Expanded(
            child: _buildTrackList(context, trackPlayerProvider),
          ),
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.black,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // The ProgressBar widget now handles buffer indication internally
                ProgressBar(provider: trackPlayerProvider),
                const SizedBox(height: 16.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.skip_previous, size: 48.0, color: Colors.white),
                      onPressed: trackPlayerProvider.previous,
                    ),
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
                    IconButton(
                      icon: const Icon(Icons.skip_next, size: 48.0, color: Colors.white),
                      onPressed: trackPlayerProvider.next,
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

  // Buffer status indicator in app bar
  Widget _buildBufferStatusIndicator(TrackPlayerProvider provider) {
    return StreamBuilder<ProcessingState>(
      stream: provider.processingStateStream,
      builder: (context, snapshot) {
        final processingState = snapshot.data ?? ProcessingState.idle;
        return Container(
          margin: const EdgeInsets.only(right: 8),
          child: _getProcessingStateIcon(processingState),
        );
      },
    );
  }

  // Buffer info panel showing detailed information
  Widget _buildBufferInfoPanel(TrackPlayerProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey[900]?.withOpacity(0.5),
      child: SafeArea(
        top: true,
        bottom: false,
        child: StreamBuilder<ProcessingState>(
          stream: provider.processingStateStream,
          builder: (context, stateSnapshot) {
            final processingState = stateSnapshot.data ?? ProcessingState.idle;
            final bufferHealth = provider.getCurrentBufferHealth();

            return Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Status: ${_getProcessingStateText(processingState)}',
                        style: TextStyle(
                          color: _getProcessingStateColor(processingState),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      StreamBuilder<Duration>(
                        stream: provider.bufferedPositionStream,
                        builder: (context, bufferedSnapshot) {
                          return Text(
                            'Buffered: ${formatDuration(bufferedSnapshot.data ?? Duration.zero)}',
                            style: const TextStyle(color: Colors.grey, fontSize: 10),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Buffer Health: ${bufferHealth.toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: _getBufferHealthColor(bufferHealth),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      LinearProgressIndicator(
                        value: bufferHealth / 100,
                        backgroundColor: Colors.grey[700],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getBufferHealthColor(bufferHealth),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
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
      top: false, // SafeArea is handled by the info panel when visible
      bottom: false,
      child: ListView.builder(
        controller: _scrollController,
        itemCount: playlist.length,
        itemBuilder: (context, index) {
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

  // Helper methods for processing state visualization
  Widget _getProcessingStateIcon(ProcessingState state, {double size = 24}) {
    switch (state) {
      case ProcessingState.idle:
        return Icon(Icons.stop_circle_outlined, size: size, color: Colors.grey);
      case ProcessingState.loading:
      case ProcessingState.buffering:
        return SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
          ),
        );
      case ProcessingState.ready:
        return Icon(Icons.check_circle, size: size, color: Colors.green);
      case ProcessingState.completed:
        return Icon(Icons.done_all, size: size, color: Colors.blue);
    }
  }

  Color _getProcessingStateColor(ProcessingState state) {
    switch (state) {
      case ProcessingState.idle:
        return Colors.grey;
      case ProcessingState.loading:
      case ProcessingState.buffering:
        return Colors.orange;
      case ProcessingState.ready:
        return Colors.green;
      case ProcessingState.completed:
        return Colors.blue;
    }
  }

  String _getProcessingStateText(ProcessingState state) {
    switch (state) {
      case ProcessingState.idle:
        return 'Stopped';
      case ProcessingState.loading:
        return 'Loading...';
      case ProcessingState.buffering:
        return 'Buffering...';
      case ProcessingState.ready:
        return 'Ready';
      case ProcessingState.completed:
        return 'Completed';
    }
  }

  Color _getBufferHealthColor(double health) {
    if (health >= 80) return Colors.green;
    if (health >= 50) return Colors.yellow;
    if (health >= 20) return Colors.orange;
    return Colors.red;
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