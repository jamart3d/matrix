// lib/pages/matrix_music_player_page.dart

import 'package:flutter/material.dart';
import 'package:matrix/components/player/themed_progress_bar.dart';
import 'package:matrix/providers/album_settings_provider.dart';
import 'package:matrix/providers/track_player_provider.dart';
import 'package:matrix/utils/duration_formatter.dart';
import 'package:marquee/marquee.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';

class MatrixMusicPlayerPage extends StatefulWidget {
  const MatrixMusicPlayerPage({super.key});

  @override
  State<MatrixMusicPlayerPage> createState() => _MatrixMusicPlayerPageState();
}

class _MatrixMusicPlayerPageState extends State<MatrixMusicPlayerPage> {
  final ScrollController _scrollController = ScrollController();
  int _lastScrolledIndex = -1;

  late final TrackPlayerProvider _playerProvider;
  // --- FIX Step 1: Add a boolean flag ---
  bool _isProviderInitialized = false;

  @override
  void initState() {
    super.initState();
    _playerProvider = context.read<TrackPlayerProvider>();
    _playerProvider.addListener(_onProviderChange);

    // --- FIX Step 2: Set the flag to true AFTER initialization ---
    _isProviderInitialized = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _scrollToCurrent(_playerProvider.currentIndex, initial: true);
      }
    });
  }

  @override
  void dispose() {
    // No need to check the flag here, as dispose() is called on a valid object.
    _playerProvider.removeListener(_onProviderChange);
    _scrollController.dispose();
    super.dispose();
  }

  void _onProviderChange() {
    // --- FIX Step 3: Guard the method with the flag ---
    // If the provider hasn't been fully assigned in initState yet, do nothing.
    if (!_isProviderInitialized) return;

    if (_playerProvider.currentIndex != _lastScrolledIndex) {
      _scrollToCurrent(_playerProvider.currentIndex);
    }
  }

  void _scrollToCurrent(int index, {bool initial = false}) {
    if (_scrollController.hasClients && index >= 0) {
      _lastScrolledIndex = index;
      const itemHeight = 56.0;
      final targetOffset = (index * itemHeight) - (MediaQuery.of(context).size.height / 4);
      final maxScroll = _scrollController.position.maxScrollExtent;

      if (initial) {
        _scrollController.jumpTo(targetOffset.clamp(0.0, maxScroll));
      } else {
        _scrollController.animateTo(
          targetOffset.clamp(0.0, maxScroll),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
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
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/t_steal.webp'),
                fit: BoxFit.cover,
                opacity: 0.3,
              ),
              gradient: LinearGradient(
                colors: [Color(0xFF001a00), Colors.black],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Column(
            children: [
              if (settingsProvider.showBufferInfo)
                _buildBufferInfoPanel(trackPlayerProvider),
              Expanded(
                child: _buildTrackList(context, trackPlayerProvider),
              ),
              Container(
                padding: const EdgeInsets.all(16.0).copyWith(bottom: 24.0),
                color: Colors.black.withOpacity(0.5),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ThemedProgressBar(
                      provider: trackPlayerProvider,
                      activeColor: Colors.green,
                      shadowColor: Colors.greenAccent,
                      bufferColor: Colors.green.withOpacity(0.3),
                      overlayColor: Colors.greenAccent.withOpacity(0.2),
                    ),
                    const SizedBox(height: 16.0),
                    _buildPlayerControls(trackPlayerProvider),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBufferInfoPanel(TrackPlayerProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.black.withOpacity(0.4),
      child: SafeArea(
        top: true, bottom: false,
        child: StreamBuilder<ProcessingState>(
          stream: provider.processingStateStream,
          builder: (context, stateSnapshot) {
            final bufferHealth = provider.getCurrentBufferHealth();
            return Row(
              children: [
                Expanded(child: Text('Status: ${stateSnapshot.data?.name ?? "idle"}', style: const TextStyle(color: Colors.green, fontSize: 12))),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Buffer Health: ${bufferHealth.toStringAsFixed(1)}%', style: TextStyle(color: _getBufferHealthColor(bufferHealth), fontSize: 12)),
                      LinearProgressIndicator(value: bufferHealth / 100, backgroundColor: Colors.grey[700], valueColor: AlwaysStoppedAnimation<Color>(_getBufferHealthColor(bufferHealth))),
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

  Color _getBufferHealthColor(double health) {
    if (health >= 80) return Colors.greenAccent;
    if (health >= 50) return Colors.yellow;
    if (health >= 20) return Colors.orange;
    return Colors.red;
  }

  Widget _buildTrackList(BuildContext context, TrackPlayerProvider provider) {
    final playlist = provider.playlist;
    final currentIndex = provider.currentIndex;
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
          final isCurrentlyPlaying = index == currentIndex;
          return ListTile(
            title: Text(track.trackName, softWrap: false, overflow: TextOverflow.ellipsis, style: TextStyle(color: isCurrentlyPlaying ? Colors.green : Colors.white, fontWeight: FontWeight.bold)),
            leading: Text(track.trackNumber, style: TextStyle(color: isCurrentlyPlaying ? Colors.green.withOpacity(0.8) : Colors.white70)),
            trailing: Text(formatDurationSeconds(track.trackDuration), style: TextStyle(color: isCurrentlyPlaying ? Colors.green.withOpacity(0.8) : Colors.white70)),
            onTap: () {
              if (!isCurrentlyPlaying) {
                provider.seekToIndex(index);
              }
            },
            selected: isCurrentlyPlaying,
            selectedTileColor: Colors.white.withOpacity(0.1),
          );
        },
      ),
    );
  }

  Widget _buildPlayerControls(TrackPlayerProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          icon: const Icon(Icons.skip_previous, size: 48.0, color: Colors.white),
          onPressed: provider.previous,
        ),
        _buildPlayPauseButton(provider),
        IconButton(
          icon: const Icon(Icons.skip_next, size: 48.0, color: Colors.white),
          onPressed: provider.next,
        ),
      ],
    );
  }

  Widget _buildPlayPauseButton(TrackPlayerProvider provider) {
    const heroTag = 'play_pause_button_hero_matrix';
    Widget buttonContent;
    if (provider.isLoading) {
      buttonContent = const SizedBox(
        width: 64.0, height: 64.0,
        child: Center(
          child: SizedBox(
            width: 48.0, height: 48.0,
            child: CircularProgressIndicator(strokeWidth: 3.0, valueColor: AlwaysStoppedAnimation<Color>(Colors.green)),
          ),
        ),
      );
    } else {
      buttonContent = IconButton(
        icon: Icon(
          provider.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
          size: 64.0,
          color: Colors.green,
        ),
        onPressed: provider.isPlaying ? provider.pause : provider.play,
      );
    }
    return Hero(
      tag: heroTag,
      child: Material(
        color: Colors.transparent,
        child: buttonContent,
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
                final navigator = Navigator.of(context);
                Navigator.of(dialogContext).pop();
                await provider.clearPlaylist();
                if (mounted) {
                  navigator.pop();
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