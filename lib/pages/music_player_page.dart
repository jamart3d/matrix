// lib/pages/music_player_page.dart

import 'dart:ui';
// import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:logger/logger.dart';
import 'package:matrix/pages/track_playlist_page.dart';
import 'package:matrix/providers/album_settings_provider.dart';
import 'package:matrix/providers/track_player_provider.dart';
import 'package:provider/provider.dart';
import 'package:matrix/components/player/progress_bar.dart';
import 'package:matrix/providers/enums.dart';
import 'package:matrix/utils/seamless_rect_tween.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../components/player/buffer_info_panel.dart';

class MusicPlayerPage extends StatefulWidget {
  const MusicPlayerPage({super.key});

  @override
  State<MusicPlayerPage> createState() => _MusicPlayerPageState();
}

class _MusicPlayerPageState extends State<MusicPlayerPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _opacityAnimation;
  final Logger _logger = Logger();

  @override
  void initState() {
    super.initState();
    _logger.d('_MusicPlayerPageState initState called');

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic)
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _logger.d('_MusicPlayerPageState build called');
    final trackPlayerProvider = context.watch<TrackPlayerProvider>();

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(context),
      body: AnimatedBuilder(
        animation: _opacityAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _opacityAnimation.value,
            child: _buildMusicPlayerContent(context, trackPlayerProvider),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      centerTitle: true,
      forceMaterialTransparency: true,
      foregroundColor: Colors.white,
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: const Text(
        'Now Playing',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 24,
          color: Colors.yellow,
          shadows: [
            Shadow(color: Colors.redAccent, blurRadius: 3),
            Shadow(color: Colors.redAccent, blurRadius: 6),
          ],
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        },
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.queue_music),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const TrackPlaylistPage(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMusicPlayerContent(
      BuildContext context, TrackPlayerProvider trackPlayerProvider) {
    final albumArt = trackPlayerProvider.currentAlbumArt;
    final settingsProvider = context.watch<AlbumSettingsProvider>();

    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(albumArt),
          fit: BoxFit.cover,
        ),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.7),
                Colors.black.withOpacity(0.4),
                Colors.black.withOpacity(0.8),
              ],
            ),
          ),
          child: trackPlayerProvider.currentTrack == null
              ? const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.music_off_rounded, size: 80, color: Colors.white54),
                Gap(16),
                Text(
                  'No Tracks Available',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 24,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ],
            ),
          )
              : SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  const Spacer(flex: 1),
                  _buildAlbumArt(albumArt),
                  const Spacer(flex: 1),
                  _buildSongWheel(trackPlayerProvider),
                  const Spacer(flex: 1),
                  const _PlaybackControls(),
                  const Gap(24),
                  _ProgressBar(trackPlayerProvider: trackPlayerProvider),
                  const Gap(16),
                  if (settingsProvider.showBufferInfo)
                    BufferInfoPanel(provider: trackPlayerProvider),
                  const Gap(20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlbumArt(String albumArt) {
    return Hero(
      tag: 'album_art_$albumArt',
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.yellow.withOpacity(0.3),
              blurRadius: 30,
              spreadRadius: 5,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: AspectRatio(
          aspectRatio: 1,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Image.asset(
              albumArt,
              gaplessPlayback: true,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.grey.shade800, Colors.grey.shade900],
                    ),
                  ),
                  child: const Center(
                    child: Icon(Icons.music_note_rounded, color: Colors.white54, size: 60),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrackInfo(TrackPlayerProvider trackPlayerProvider) {
    return Text(
      trackPlayerProvider.currentTrack!.trackName,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 28,
        color: Colors.white,
        letterSpacing: -0.5,
      ),
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildSongWheel(TrackPlayerProvider trackPlayerProvider) {
    return SizedBox(
      height: 120,
      child: _SongScrollWheel(trackPlayerProvider: trackPlayerProvider),
    );
  }
}

class _SongScrollWheel extends StatefulWidget {
  final TrackPlayerProvider trackPlayerProvider;

  const _SongScrollWheel({required this.trackPlayerProvider});

  @override
  State<_SongScrollWheel> createState() => _SongScrollWheelState();
}

class _SongScrollWheelState extends State<_SongScrollWheel> {
  late ItemScrollController _itemScrollController;
  late ItemPositionsListener _itemPositionsListener;
  int _currentVisibleIndex = 0;
  String? _lastKnownTrackName;

  @override
  void initState() {
    super.initState();
    _itemScrollController = ItemScrollController();
    _itemPositionsListener = ItemPositionsListener.create();
    _lastKnownTrackName = widget.trackPlayerProvider.currentTrack?.trackName;

    _itemPositionsListener.itemPositions.addListener(() {
      final positions = _itemPositionsListener.itemPositions.value;
      if (positions.isNotEmpty) {
        // Find the item closest to the center
        final centerPosition = positions.reduce((a, b) {
          final aDistance = (a.itemTrailingEdge + a.itemLeadingEdge) / 2 - 0.5;
          final bDistance = (b.itemTrailingEdge + b.itemLeadingEdge) / 2 - 0.5;
          return aDistance.abs() < bDistance.abs() ? a : b;
        });

        if (_currentVisibleIndex != centerPosition.index) {
          setState(() {
            _currentVisibleIndex = centerPosition.index;
          });
        }
      }
    });

    // Position at current track on init - no animation needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _scrollToCurrentTrack();
        }
      });
    });
  }

  void _scheduleScrollToCurrentTrack() {
    // Just position at current track without animation
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _scrollToCurrentTrack();
    });
  }

  void _scrollToCurrentTrack() {
    final playlist = widget.trackPlayerProvider.playlist;
    final currentTrack = widget.trackPlayerProvider.currentTrack;

    if (currentTrack == null || playlist.isEmpty) return;

    // Find the exact index in the original playlist
    int index = -1;
    for (int i = 0; i < playlist.length; i++) {
      if (playlist[i].trackName == currentTrack.trackName) {
        index = i;
        break;
      }
    }

    if (index != -1 && _itemScrollController.isAttached) {
      try {
        // Always use jumpTo - no animations
        _itemScrollController.jumpTo(index: index);

        // Update the visible index to match
        setState(() {
          _currentVisibleIndex = index;
        });
      } catch (e) {
        // Silent fallback
      }
    }
  }

  @override
  void didUpdateWidget(_SongScrollWheel oldWidget) {
    super.didUpdateWidget(oldWidget);

    final currentTrackName = widget.trackPlayerProvider.currentTrack?.trackName;

    // Check if track has actually changed
    if (currentTrackName != _lastKnownTrackName) {
      _lastKnownTrackName = currentTrackName;

      if (currentTrackName != null) {
        // Just position at the new track without animation
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) _scrollToCurrentTrack();
        });
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allSongs = _getAllSongs();

    if (allSongs.isEmpty) {
      return const SizedBox(
        height: 120,
        child: Center(
          child: Text(
            'No tracks available',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 120,
      child: ScrollablePositionedList.builder(
        itemScrollController: _itemScrollController,
        itemPositionsListener: _itemPositionsListener,
        scrollDirection: Axis.vertical,
        itemCount: allSongs.length,
        itemBuilder: (context, index) {
          final currentTrackName = widget.trackPlayerProvider.currentTrack?.trackName;
          final isCurrentTrack = currentTrackName != null &&
              allSongs[index].contains(currentTrackName.length > 25 ? currentTrackName.substring(0, 25) : currentTrackName);
          final isCenterItem = index == _currentVisibleIndex;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: EdgeInsets.symmetric(
              vertical: 4,
              horizontal: isCenterItem ? 8 : 20,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: isCurrentTrack
                  ? Colors.yellow.withOpacity(0.3)
                  : isCenterItem
                  ? Colors.white.withOpacity(0.1)
                  : Colors.transparent,
            ),
            child: Center(
              child: Text(
                allSongs[index],
                style: TextStyle(
                  color: isCurrentTrack
                      ? Colors.yellow
                      : isCenterItem
                      ? Colors.white
                      : Colors.white.withOpacity(0.5),
                  fontSize: isCurrentTrack
                      ? 18
                      : isCenterItem
                      ? 16
                      : 14,
                  fontWeight: isCurrentTrack
                      ? FontWeight.bold
                      : isCenterItem
                      ? FontWeight.w500
                      : FontWeight.w400,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          );
        },
      ),
    );
  }

  List<String> _getAllSongs() {
    final playlist = widget.trackPlayerProvider.playlist;

    if (playlist.isEmpty) return [];

    List<String> songs = [];
    for (int i = 0; i < playlist.length; i++) {
      String songName = playlist[i].trackName;
      if (songName.length > 25) {
        songName = '${songName.substring(0, 25)}...';
      }
      songs.add(songName);
    }
    return songs;
  }
}

class _PlaybackControls extends StatefulWidget {
  const _PlaybackControls();

  @override
  State<_PlaybackControls> createState() => _PlaybackControlsState();
}

class _PlaybackControlsState extends State<_PlaybackControls>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _glowAnimation;
  final Curve _animationCurve = Curves.easeInOut;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _scaleAnimation = Tween<double>(begin: 0.98, end: 1.02).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: _animationCurve,
      ),
    );

    _glowAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    final provider = context.read<TrackPlayerProvider>();
    if (provider.isPlaying) {
      _animationController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trackPlayerProvider = context.read<TrackPlayerProvider>();
    final heroTag = ModalRoute.of(context)?.settings.arguments as String? ?? 'album_player_hero_fallback';
    final settingsProvider = context.watch<AlbumSettingsProvider>();
    final isLarge = settingsProvider.fabSize == FabSize.large;
    final double fabSize = isLarge ? 75.0 : 65.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(35),
        color: Colors.black.withOpacity(0.3),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // --- MODIFICATION START ---
          _buildControlButton(
            icon: Icons.skip_previous,
            onPressed: trackPlayerProvider.previous,
            size: 48.0,
          ),
          // --- MODIFICATION END ---
          Hero(
            tag: heroTag,
            createRectTween: (begin, end) {
              return SeamlessRectTween(curve: _animationCurve, begin: begin!, end: end!);
            },
            child: Consumer<TrackPlayerProvider>(
              builder: (context, provider, child) {
                if (provider.isPlaying && !_animationController.isAnimating) {
                  _animationController.repeat(reverse: true);
                } else if (!provider.isPlaying && _animationController.isAnimating) {
                  _animationController.stop();
                  _animationController.reset();
                }

                return AnimatedBuilder(
                  animation: _glowAnimation,
                  builder: (context, child) {
                    return Container(
                      width: fabSize,
                      height: fabSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: provider.isPlaying ? [
                          BoxShadow(
                            color: Colors.yellow.withOpacity(_glowAnimation.value * 0.5),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ] : null,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(fabSize / 2),
                          onTap: () {
                            if (provider.isLoading) return;
                            if (provider.isPlaying) {
                              provider.pause();
                            } else {
                              provider.play();
                            }
                          },
                          onLongPress: () {
                            if (provider.isLoading) {
                              provider.clearPlaylist();
                            }
                          },
                          child: Container(
                            width: fabSize,
                            height: fabSize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  Colors.yellow.withOpacity(0.9),
                                  Colors.yellow.withOpacity(0.7),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Center(
                              child: provider.isLoading
                                  ? SizedBox(
                                width: 30,
                                height: 30,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3.0,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.black.withOpacity(0.8),
                                  ),
                                ),
                              )
                                  : ScaleTransition(
                                scale: _scaleAnimation,
                                child: Icon(
                                  provider.isPlaying
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  size: fabSize * 0.6,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // --- MODIFICATION START ---
          _buildControlButton(
            icon: Icons.skip_next,
            onPressed: trackPlayerProvider.next,
            size: 48.0,
          ),
          // --- MODIFICATION END ---
        ],
      ),
    );
  }

  // --- MODIFICATION START ---
  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required double size,
  }) {
    // Removed the Container wrapper
    return IconButton(
      icon: Icon(
        icon,
        size: size,
        color: Colors.white,
      ),
      onPressed: onPressed,
    );
  }
// --- MODIFICATION END ---
}

class _ProgressBar extends StatelessWidget {
  final TrackPlayerProvider trackPlayerProvider;

  const _ProgressBar({required this.trackPlayerProvider});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ProgressBar(provider: trackPlayerProvider),
    );
  }
}