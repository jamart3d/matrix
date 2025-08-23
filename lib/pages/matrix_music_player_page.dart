// lib/pages/matrix_music_player_page.dart

import 'package:flutter/material.dart';
import 'package:matrix/components/player/buffer_info_panel.dart';
import 'package:matrix/components/player/themed_progress_bar.dart';
import 'package:matrix/providers/album_settings_provider.dart';
import 'package:matrix/providers/track_player_provider.dart';
import 'package:matrix/utils/duration_formatter.dart';
import 'package:matrix/utils/theme_helper.dart';
import 'package:marquee/marquee.dart';
import 'package:provider/provider.dart';

class MatrixMusicPlayerPage extends StatefulWidget {
  const MatrixMusicPlayerPage({super.key});

  @override
  State<MatrixMusicPlayerPage> createState() => _MatrixMusicPlayerPageState();
}

class _MatrixMusicPlayerPageState extends State<MatrixMusicPlayerPage> {
  final ScrollController _scrollController = ScrollController();
  int _lastScrolledIndex = -1;
  late final TrackPlayerProvider _playerProvider;
  bool _isProviderInitialized = false;

  @override
  void initState() {
    super.initState();
    _playerProvider = context.read<TrackPlayerProvider>();
    _playerProvider.addListener(_onProviderChange);
    _isProviderInitialized = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _scrollToCurrent(_playerProvider.currentIndex, initial: true);
      }
    });
  }

  @override
  void dispose() {
    _playerProvider.removeListener(_onProviderChange);
    _scrollController.dispose();
    super.dispose();
  }

  void _onProviderChange() {
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

    final theme = settingsProvider.matrixColorTheme;
    final themeColor = getThemeColor(theme);
    final darkThemeColor = getDarkThemeColor(theme);
    final themeAccentColor = getThemeAccentColor(theme);

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
            decoration: BoxDecoration(
              image: const DecorationImage(
                image: AssetImage('assets/images/t_steal.webp'),
                fit: BoxFit.cover,
                opacity: 0.3,
              ),
              gradient: LinearGradient(
                colors: [darkThemeColor, Colors.black],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Column(
            children: [
              if (settingsProvider.showBufferInfo)
                BufferInfoPanel(
                  provider: trackPlayerProvider,
                ),
              Expanded(
                child: _buildTrackList(context, trackPlayerProvider, themeColor),
              ),
              Container(
                padding: const EdgeInsets.all(16.0).copyWith(bottom: 24.0),
                color: Colors.black.withOpacity(0.5),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ThemedProgressBar(
                      provider: trackPlayerProvider,
                      activeColor: themeColor,
                      shadowColor: themeAccentColor,
                      bufferColor: themeColor.withOpacity(0.3),
                      overlayColor: themeAccentColor.withOpacity(0.2),
                    ),
                    const SizedBox(height: 16.0),
                    _buildPlayerControls(trackPlayerProvider, themeColor),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
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

  Widget _buildPlayerControls(TrackPlayerProvider provider, Color themeColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          icon: const Icon(Icons.skip_previous, size: 48.0, color: Colors.white),
          onPressed: provider.previous,
        ),
        _buildPlayPauseButton(provider, themeColor),
        IconButton(
          icon: const Icon(Icons.skip_next, size: 48.0, color: Colors.white),
          onPressed: provider.next,
        ),
      ],
    );
  }

  Widget _buildPlayPauseButton(TrackPlayerProvider provider, Color themeColor) {
    const heroTag = 'play_pause_button_hero_matrix';
    Widget buttonContent;
    if (provider.isLoading) {
      buttonContent = SizedBox(
        width: 64.0, height: 64.0,
        child: Center(
          child: SizedBox(
            width: 48.0, height: 48.0,
            child: CircularProgressIndicator(strokeWidth: 3.0, valueColor: AlwaysStoppedAnimation<Color>(themeColor)),
          ),
        ),
      );
    } else {
      buttonContent = IconButton(
        icon: Icon(
          provider.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
          size: 64.0,
          color: themeColor,
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