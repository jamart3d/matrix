// lib/pages/shows_music_player_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:matrix/providers/album_settings_provider.dart';
import 'package:matrix/providers/track_player_provider.dart';
import 'package:matrix/utils/duration_formatter.dart';
import 'package:matrix/components/player/themed_shows_progress_bar.dart';
import 'package:matrix/components/player/buffer_info_panel.dart';
import 'package:marquee/marquee.dart';

class ShowsMusicPlayerPage extends StatefulWidget {
  const ShowsMusicPlayerPage({super.key});

  @override
  State<ShowsMusicPlayerPage> createState() => _ShowsMusicPlayerPageState();
}

// --- 1. ADD TickerProviderStateMixin FOR ANIMATION ---
class _ShowsMusicPlayerPageState extends State<ShowsMusicPlayerPage> with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();

  // --- 2. ADD CONTROLLER AND ANIMATION FOR PULSING ---
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late final TrackPlayerProvider _playerProvider;

  @override
  void initState() {
    super.initState();
    _playerProvider = context.read<TrackPlayerProvider>();
    _playerProvider.addListener(_onPlayerChange);

    // --- 3. INITIALIZE THE PULSE ANIMATION ---
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Start pulsing if music is already playing when the page loads
    if (_playerProvider.isPlaying) {
      _pulseController.repeat(reverse: true);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _scrollToCurrent(_playerProvider.currentIndex);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _playerProvider.removeListener(_onPlayerChange);
    _pulseController.dispose(); // --- 4. DISPOSE THE NEW CONTROLLER ---
    super.dispose();
  }

  // --- 5. ADD A LISTENER TO CONTROL THE ANIMATION ---
  void _onPlayerChange() {
    if (!mounted) return;

    // Control the pulse animation based on player state
    if (_playerProvider.isPlaying && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!_playerProvider.isPlaying && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.animateTo(0.0, duration: const Duration(milliseconds: 100));
    }

    _scrollToCurrent(_playerProvider.currentIndex);
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
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Clear Playlist',
            onPressed: () => _showClearPlaylistDialog(context, trackPlayerProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          if (settingsProvider.showBufferInfo)
            BufferInfoPanel(
              provider: trackPlayerProvider,
            ),
          Expanded(
            child: _buildTrackList(context, trackPlayerProvider),
          ),
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.black,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 30,
                  child: ThemedShowsProgressBar(provider: trackPlayerProvider),
                ),
                const SizedBox(height: 16.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.skip_previous, size: 48.0, color: Colors.white),
                      onPressed: trackPlayerProvider.previous,
                    ),
                    _buildPlayPauseButton(trackPlayerProvider),
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

  Widget _buildPlayPauseButton(TrackPlayerProvider provider) {
    const heroTag = 'play_pause_button_hero_shows';

    Widget buttonContent;
    if (provider.isLoading) {
      buttonContent = const CircularProgressIndicator(
        strokeWidth: 3.0,
        valueColor: AlwaysStoppedAnimation<Color>(Colors.yellow),
      );
    } else {
      // --- 6. WRAP THE ICON IN THE ScaleTransition ---
      buttonContent = ScaleTransition(
        scale: _pulseAnimation,
        child: Icon(
          provider.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
          size: 64.0,
          color: Colors.yellow,
        ),
      );
    }

    return Hero(
      tag: heroTag,
      child: Material(
        color: Colors.transparent,
        child: GestureDetector(
          onTap: () {
            if (provider.isLoading) return;
            if (provider.isPlaying) {
              provider.pause();
            } else {
              provider.play();
            }
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

  Widget _buildTrackList(BuildContext context, TrackPlayerProvider trackPlayerProvider) {
    final playlist = trackPlayerProvider.playlist;
    final currentIndex = trackPlayerProvider.currentIndex;
    final settings = context.read<AlbumSettingsProvider>();

    if (playlist.isEmpty) {
      return const Center(child: Text('Playlist is empty', style: TextStyle(color: Colors.white)));
    }

    return SafeArea(
      top: !settings.showBufferInfo,
      bottom: false,
      child: ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.only(top: settings.showBufferInfo ? 0 : 80),
        itemCount: playlist.length,
        itemBuilder: (context, index) {
          final track = playlist[index];
          final isCurrentlyPlayingTrack = index == currentIndex;
          return ListTile(
            title: Text(track.trackName, softWrap: false, overflow: TextOverflow.ellipsis, style: TextStyle(color: isCurrentlyPlayingTrack ? Colors.yellow : Colors.white, fontWeight: FontWeight.bold)),
            leading: Text(track.trackNumber, style: TextStyle(color: isCurrentlyPlayingTrack ? Colors.yellow.withOpacity(0.8) : Colors.white70)),
            trailing: Text(formatDurationSeconds(track.trackDuration), style: TextStyle(color: isCurrentlyPlayingTrack ? Colors.yellow.withOpacity(0.8) : Colors.white70)),
            onTap: () {
              if (!isCurrentlyPlayingTrack) {
                trackPlayerProvider.seekToIndex(index);
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
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
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