// lib/pages/shows_music_player_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gap/gap.dart';
import 'package:matrix/components/player/themed_progress_bar.dart'; // Using generic themed bar
import 'package:matrix/providers/album_settings_provider.dart';
import 'package:matrix/providers/track_player_provider.dart';
import 'package:matrix/utils/duration_formatter.dart';
import 'package:matrix/components/player/buffer_info_panel.dart';
import 'package:marquee/marquee.dart';
// import 'package:matrix/providers/enums.dart';
// import 'package:matrix/utils/seamless_rect_tween.dart';

// --- DEFINING YELLOW THEME CONSTANTS ---
const Color kThemeColor = Colors.yellow;
const Color kDarkThemeColor = Color.fromARGB(255, 34, 34, 0); // Darker yellow/gold
const Color kThemeAccentColor = Colors.redAccent; // Used for shadows/accents in Matrix theme

class ShowsMusicPlayerPage extends StatefulWidget {
  const ShowsMusicPlayerPage({super.key});

  @override
  State<ShowsMusicPlayerPage> createState() => _ShowsMusicPlayerPageState();
}

class _ShowsMusicPlayerPageState extends State<ShowsMusicPlayerPage> with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late final TrackPlayerProvider _playerProvider;

  // Animation controllers needed for the Matrix/Styled controls
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _trackChangeController; // Needed for play/pause animation combo

  @override
  void initState() {
    super.initState();
    _playerProvider = context.read<TrackPlayerProvider>();
    _playerProvider.addListener(_onProviderChange); // Listener needed for track change scroll

    _trackChangeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (_playerProvider.isPlaying) {
      _pulseController.repeat(reverse: true);
    }

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
    _pulseController.dispose();
    _trackChangeController.dispose();
    super.dispose();
  }

  void _onProviderChange() {
    if (!mounted) return;
    final currentIndex = _playerProvider.currentIndex;

    if (_playerProvider.isPlaying && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!_playerProvider.isPlaying && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.animateTo(0.0, duration: const Duration(milliseconds: 100));
    }

    _scrollToCurrent(currentIndex);
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
      // --- MATRIX/YELLOW THEMED BODY STRUCTURE ---
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Matrix Background (using standard matrix asset and hardcoded yellow colors)
          RepaintBoundary(
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/t_steal.webp'),
                  fit: BoxFit.cover,
                  opacity: 0.3,
                ),
                gradient: LinearGradient(
                  colors: [kDarkThemeColor, Colors.black],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          // 2. Track List and Controls Layout
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  Expanded(
                    child: _buildTrackList(context, trackPlayerProvider, kThemeColor),
                  ),
                  _buildPlayerControls(trackPlayerProvider, kThemeColor),
                  const Gap(24),
                  // Using ThemedProgressBar and passing constants
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: ThemedProgressBar(
                      provider: trackPlayerProvider,
                      activeColor: kThemeColor,
                      shadowColor: kThemeAccentColor,
                      bufferColor: kThemeColor.withOpacity(0.3),
                      overlayColor: kThemeAccentColor.withOpacity(0.2),
                    ),
                  ),
                  const Gap(16),
                  if (settingsProvider.showBufferInfo)
                    BufferInfoPanel(provider: trackPlayerProvider),
                  const Gap(20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackList(BuildContext context, TrackPlayerProvider provider, Color themeColor) {
    final playlist = provider.playlist;
    final currentIndex = provider.currentIndex;

    if (playlist.isEmpty) {
      return const Center(
        child: Text('Playlist is empty', style: TextStyle(color: Colors.white)),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.zero,
      itemCount: playlist.length,
      itemBuilder: (context, index) {
        final track = playlist[index];
        final isCurrentlyPlaying = index == currentIndex;
        return ListTile(
          title: Text(
            track.trackName,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isCurrentlyPlaying ? themeColor : Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          leading: Text(
            track.trackNumber,
            style: TextStyle(
              color: isCurrentlyPlaying ? themeColor.withOpacity(0.8) : Colors.white70,
            ),
          ),
          trailing: Text(
            formatDurationSeconds(track.trackDuration),
            style: TextStyle(
              color: isCurrentlyPlaying ? themeColor.withOpacity(0.8) : Colors.white70,
            ),
          ),
          onTap: () {
            if (!isCurrentlyPlaying) {
              provider.seekToIndex(index);
            }
          },
          selected: isCurrentlyPlaying,
          selectedTileColor: themeColor.withOpacity(0.1),
        );
      },
    );
  }

  // Copied directly from MatrixMusicPlayerPage
  Widget _buildPlayerControls(TrackPlayerProvider provider, Color themeColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          icon: const Icon(Icons.skip_previous, size: 48.0, color: Colors.white),
          onPressed: () {
            provider.previous();
          },
        ),
        _buildPlayPauseButton(provider, themeColor),
        IconButton(
          icon: const Icon(Icons.skip_next, size: 48.0, color: Colors.white),
          onPressed: () {
            provider.next();
          },
        ),
      ],
    );
  }

  // Copied directly from MatrixMusicPlayerPage, simplified animation for this context
  Widget _buildPlayPauseButton(TrackPlayerProvider provider, Color themeColor) {
    const heroTag = 'play_pause_button_hero_shows_matrix_yellow';

    Widget buttonContent;
    if (provider.isLoading) {
      buttonContent = CircularProgressIndicator(
        strokeWidth: 3.0,
        valueColor: AlwaysStoppedAnimation<Color>(themeColor),
      );
    } else {
      buttonContent = AnimatedBuilder(
        animation: _pulseController, // Only using pulse for simplicity
        builder: (context, child) {
          final scale = _pulseAnimation.value;
          return Transform.scale(
            scale: scale,
            child: Icon(
              provider.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
              key: ValueKey(provider.isPlaying),
              size: 64.0,
              color: themeColor,
            ),
          );
        },
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