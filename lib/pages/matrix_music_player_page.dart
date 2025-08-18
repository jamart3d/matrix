// lib/pages/matrix_music_player_page.dart

import 'package:flutter/material.dart';
import 'package:matrix/components/player/progress_bar.dart';
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

  @override
  void initState() {
    super.initState();
    final provider = context.read<TrackPlayerProvider>();
    provider.addListener(_onProviderChange);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _scrollToCurrent(provider.currentIndex, initial: true);
      }
    });
  }

  @override
  void dispose() {
    context.read<TrackPlayerProvider>().removeListener(_onProviderChange);
    _scrollController.dispose();
    super.dispose();
  }

  void _onProviderChange() {
    final provider = context.read<TrackPlayerProvider>();
    if (provider.currentIndex != _lastScrolledIndex) {
      _scrollToCurrent(provider.currentIndex);
    }
  }

  void _scrollToCurrent(int index, {bool initial = false}) {
    if (_scrollController.hasClients && index >= 0) {
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

  Color _getThemeColor(MatrixColorTheme theme) {
    switch (theme) {
      case MatrixColorTheme.cyanBlue:
        return Colors.cyan;
      case MatrixColorTheme.purpleMatrix:
        return Colors.purpleAccent;
      case MatrixColorTheme.redAlert:
        return Colors.redAccent;
      case MatrixColorTheme.goldLux:
        return Colors.amber;
      case MatrixColorTheme.classicGreen:
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final trackPlayerProvider = context.watch<TrackPlayerProvider>();
    final settingsProvider = context.watch<AlbumSettingsProvider>();
    final themeColor = _getThemeColor(settingsProvider.matrixColorTheme);

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
                _buildBufferInfoPanel(trackPlayerProvider, themeColor),
              Expanded(
                child: _buildTrackList(context, trackPlayerProvider, themeColor),
              ),
              Container(
                padding: const EdgeInsets.all(16.0).copyWith(bottom: 24.0),
                color: Colors.black.withOpacity(0.5),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ProgressBar(provider: trackPlayerProvider),
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

  Widget _buildBufferInfoPanel(TrackPlayerProvider provider, Color themeColor) {
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
                Expanded(child: Text('Status: ${stateSnapshot.data?.name ?? "idle"}', style: TextStyle(color: themeColor, fontSize: 12))),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Buffer Health: ${bufferHealth.toStringAsFixed(1)}%', style: TextStyle(color: _getBufferHealthColor(bufferHealth, themeColor), fontSize: 12)),
                      LinearProgressIndicator(value: bufferHealth / 100, backgroundColor: Colors.grey[700], valueColor: AlwaysStoppedAnimation<Color>(_getBufferHealthColor(bufferHealth, themeColor))),
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

  Color _getBufferHealthColor(double health, Color themeColor) {
    if (health >= 80) return themeColor; // Use theme color for "good"
    if (health >= 50) return Colors.yellow;
    if (health >= 20) return Colors.orange;
    return Colors.red;
  }

  Widget _buildTrackList(BuildContext context, TrackPlayerProvider provider, Color themeColor) {
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
            title: Text(track.trackName, softWrap: false, overflow: TextOverflow.ellipsis, style: TextStyle(color: isCurrentlyPlaying ? themeColor : Colors.white, fontWeight: FontWeight.bold)),
            leading: Text(track.trackNumber, style: TextStyle(color: isCurrentlyPlaying ? themeColor.withOpacity(0.8) : Colors.white70)),
            trailing: Text(formatDurationSeconds(track.trackDuration), style: TextStyle(color: isCurrentlyPlaying ? themeColor.withOpacity(0.8) : Colors.white70)),
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
    const heroTag = 'matrix_play_pause_hero';
    final settingsProvider = context.read<AlbumSettingsProvider>();
    final themeColor = _getThemeColor(settingsProvider.matrixColorTheme);

    if (provider.isLoading) {
      return Hero(
        tag: heroTag,
        child: Material(
          color: Colors.transparent,
          child: SizedBox(
            width: 64.0, height: 64.0,
            child: Center(
              child: SizedBox(
                width: 48.0, height: 48.0,
                child: CircularProgressIndicator(strokeWidth: 3.0, valueColor: AlwaysStoppedAnimation<Color>(themeColor)),
              ),
            ),
          ),
        ),
      );
    }

    return Hero(
      tag: heroTag,
      child: Material(
        color: Colors.transparent,
        child: IconButton(
          icon: Icon(
            provider.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
            size: 64.0,
            color: themeColor,
          ),
          onPressed: provider.isPlaying ? provider.pause : provider.play,
        ),
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
                Navigator.of(dialogContext).pop();
                await provider.clearPlaylist();
                if (mounted) {
                  Navigator.of(context).pop();
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