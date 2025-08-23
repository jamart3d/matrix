// lib/pages/matrix_music_player_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _MatrixMusicPlayerPageState extends State<MatrixMusicPlayerPage>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  int _lastScrolledIndex = -1;
  late final TrackPlayerProvider _playerProvider;
  bool _isProviderInitialized = false;

  late AnimationController _trackChangeController;
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  String _previousTrackName = '';
  int _previousTrackIndex = -1;
  bool _hasAnimatedOnce = false;

  @override
  void initState() {
    super.initState();
    _playerProvider = context.read<TrackPlayerProvider>();
    _playerProvider.addListener(_onProviderChange);
    _isProviderInitialized = true;

    _trackChangeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _trackChangeController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    if (_playerProvider.playlist.isNotEmpty && _playerProvider.currentIndex >= 0) {
      _previousTrackName = _playerProvider.playlist[_playerProvider.currentIndex].trackName;
      _previousTrackIndex = _playerProvider.currentIndex;
    }

    if (_playerProvider.isPlaying) {
      _pulseController.repeat(reverse: true);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 50), () {
        if (mounted) {
          _scrollToCurrent(_playerProvider.currentIndex, initial: true);
          _fadeController.forward();
        }
      });
    });
  }

  @override
  void dispose() {
    _playerProvider.removeListener(_onProviderChange);
    _scrollController.dispose();
    _trackChangeController.dispose();
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _onProviderChange() {
    if (!_isProviderInitialized || !mounted) return;

    final currentIndex = _playerProvider.currentIndex;
    final currentTrackName = currentIndex >= 0 && currentIndex < _playerProvider.playlist.length
        ? _playerProvider.playlist[currentIndex].trackName
        : '';

    if (currentIndex != _previousTrackIndex && currentTrackName != _previousTrackName) {
      _animateTrackChange();
      _previousTrackIndex = currentIndex;
      _previousTrackName = currentTrackName;
    }

    if (currentIndex != _lastScrolledIndex) {
      _scrollToCurrent(currentIndex);
    }

    if (_playerProvider.isPlaying && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!_playerProvider.isPlaying && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.animateTo(0.0, duration: const Duration(milliseconds: 100));
    }
  }

  void _animateTrackChange() {
    HapticFeedback.selectionClick();
    _hasAnimatedOnce = true;
    _trackChangeController.reset();
    _fadeController.reset();
    _trackChangeController.forward();
    _fadeController.forward();
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
            : FadeTransition(
          opacity: _fadeAnimation,
          child: Text(trackPlayerProvider.currentAlbumTitle),
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
          RepaintBoundary(
            child: Container(
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
          ),
          Column(
            children: [
              if (settingsProvider.showBufferInfo)
                RepaintBoundary(
                  child: BufferInfoPanel(
                    provider: trackPlayerProvider,
                  ),
                ),
              Expanded(
                child: _buildTrackList(context, trackPlayerProvider, themeColor),
              ),
              RepaintBoundary(
                child: Container(
                  padding: const EdgeInsets.all(16.0).copyWith(bottom: 24.0),
                  color: Colors.black.withOpacity(0.5),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 30,
                        child: ThemedProgressBar(
                          provider: trackPlayerProvider,
                          activeColor: themeColor,
                          shadowColor: themeAccentColor,
                          bufferColor: themeColor.withOpacity(0.3),
                          overlayColor: themeAccentColor.withOpacity(0.2),
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      _buildPlayerControls(trackPlayerProvider, themeColor),
                    ],
                  ),
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
      return const Center(
        child: Text('Playlist is empty', style: TextStyle(color: Colors.white)),
      );
    }

    return SafeArea(
      top: !settings.showBufferInfo,
      bottom: false,
      child: ListView.separated(
        controller: _scrollController,
        padding: EdgeInsets.only(top: settings.showBufferInfo ? 0 : 80),
        itemCount: playlist.length,
        separatorBuilder: (context, index) => const Divider(
          height: 1,
          color: Colors.white10,
          indent: 16,
          endIndent: 16,
        ),
        itemBuilder: (context, index) {
          final track = playlist[index];
          final isCurrentlyPlaying = index == currentIndex;
          return RepaintBoundary(
            child: AnimatedBuilder(
              animation: _slideAnimation,
              builder: (context, child) {
                final offset = isCurrentlyPlaying && _hasAnimatedOnce
                    ? Offset(20.0 * (1.0 - _slideAnimation.value), 0.0)
                    : Offset.zero;

                final opacity = isCurrentlyPlaying && _hasAnimatedOnce
                    ? _fadeAnimation
                    : const AlwaysStoppedAnimation<double>(1.0);

                return FadeTransition(
                  opacity: opacity,
                  child: Transform.translate(
                    offset: offset,
                    child: _buildTrackTile(track, index, isCurrentlyPlaying, themeColor, provider),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildTrackTile(dynamic track, int index, bool isCurrentlyPlaying, Color themeColor, TrackPlayerProvider provider) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: isCurrentlyPlaying
            ? Colors.white.withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8.0),
        border: isCurrentlyPlaying
            ? Border.all(color: themeColor.withOpacity(0.3), width: 1)
            : null,
      ),
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
        title: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 300),
          style: TextStyle(
            color: isCurrentlyPlaying ? themeColor : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: isCurrentlyPlaying ? 16.0 : 14.0,
          ),
          child: Text(
            track.trackName,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        leading: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: EdgeInsets.all(isCurrentlyPlaying ? 8.0 : 4.0),
          decoration: BoxDecoration(
            color: isCurrentlyPlaying
                ? themeColor.withOpacity(0.2)
                : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Text(
            track.trackNumber,
            style: TextStyle(
              color: isCurrentlyPlaying
                  ? themeColor.withOpacity(0.8)
                  : Colors.white70,
              fontWeight: isCurrentlyPlaying ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        trailing: Text(
          formatDurationSeconds(track.trackDuration),
          style: TextStyle(
            color: isCurrentlyPlaying
                ? themeColor.withOpacity(0.8)
                : Colors.white70,
          ),
        ),
        onTap: () {
          if (!isCurrentlyPlaying) {
            HapticFeedback.lightImpact();
            provider.seekToIndex(index);
          }
        },
      ),
    );
  }

  Widget _buildPlayerControls(TrackPlayerProvider provider, Color themeColor) {
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: const Icon(Icons.skip_previous, size: 48.0, color: Colors.white),
              onPressed: () {
                HapticFeedback.lightImpact();
                provider.previous();
              },
            ),
            _buildPlayPauseButton(provider, themeColor),
            IconButton(
              icon: const Icon(Icons.skip_next, size: 48.0, color: Colors.white),
              onPressed: () {
                HapticFeedback.lightImpact();
                provider.next();
              },
            ),
          ],
        );
      },
    );
  }

  // --- THIS IS THE CORRECTED METHOD ---
  Widget _buildPlayPauseButton(TrackPlayerProvider provider, Color themeColor) {
    const heroTag = 'play_pause_button_hero_matrix';

    Widget buttonContent;
    if (provider.isLoading) {
      buttonContent = CircularProgressIndicator(
        strokeWidth: 3.0,
        valueColor: AlwaysStoppedAnimation<Color>(themeColor),
      );
    } else {
      // The track change "pop" is combined with the pulsing animation
      buttonContent = AnimatedBuilder(
        animation: Listenable.merge([_trackChangeController, _pulseAnimation]),
        builder: (context, child) {
          // The pop animation is additive to the pulse animation
          final scale = _pulseAnimation.value * (1.0 + (0.1 * (1.0 - _trackChangeController.value)));
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
            HapticFeedback.mediumImpact();
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
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
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