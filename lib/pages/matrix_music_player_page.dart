// lib/pages/matrix_music_player_page.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:matrix/components/player/buffer_info_panel.dart';
import 'package:matrix/components/player/loading_timeout_controls.dart';
import 'package:matrix/components/player/themed_progress_bar.dart';
import 'package:matrix/providers/album_settings_provider.dart';
import 'package:matrix/providers/track_player_provider.dart';
import 'package:matrix/utils/album_title_parser.dart';
import 'package:matrix/utils/duration_formatter.dart';
import 'package:matrix/utils/string_formatter.dart';
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
  late final TrackPlayerProvider _playerProvider;

  // Animation controllers
  late final AnimationController _trackChangeController;
  late final AnimationController _fadeController;
  late final AnimationController _pulseController;

  // Animations
  late final Animation<double> _pulseAnimation;
  late final Animation<double> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  // State for tracking track changes to trigger animations
  String _previousTrackName = '';
  int _previousTrackIndex = -1;
  bool _hasAnimatedOnce = false;

  static const double _kControlsAreaBottomPadding = 220.0;
  static const Duration _kTrackChangeAnimationDuration =
  Duration(milliseconds: 600);
  static const Duration _kFadeAnimationDuration = Duration(milliseconds: 300);
  static const Duration _kPulseAnimationDuration =
  Duration(milliseconds: 1500);

  @override
  void initState() {
    super.initState();
    _playerProvider = context.read<TrackPlayerProvider>();
    _initializeState();
    _initializeAnimations();
    _playerProvider.addListener(_onPlayerStateChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Future.delayed(const Duration(milliseconds: 50), () {
        if (mounted) {
          _scrollToCurrent(_playerProvider.currentIndex, isInitial: true);
          _fadeController.forward();
        }
      });
    });
  }

  void _initializeState() {
    final currentTrack = _playerProvider.currentTrack;
    if (currentTrack != null) {
      _previousTrackName = currentTrack.trackName;
      _previousTrackIndex = _playerProvider.currentIndex;
    }
  }

  void _initializeAnimations() {
    _trackChangeController =
        AnimationController(duration: _kTrackChangeAnimationDuration, vsync: this);
    _fadeController =
        AnimationController(duration: _kFadeAnimationDuration, vsync: this);
    _pulseController =
        AnimationController(duration: _kPulseAnimationDuration, vsync: this);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
        CurvedAnimation(
          parent: _pulseController,
          curve: Curves.easeInOut,
        ));
    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _trackChangeController,
          curve: Curves.easeOutCubic,
        ));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut));

    if (_playerProvider.isPlaying) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _playerProvider.removeListener(_onPlayerStateChanged);
    _trackChangeController.dispose();
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _onPlayerStateChanged() {
    if (!mounted) return;
    final currentTrack = _playerProvider.currentTrack;
    final currentIndex = _playerProvider.currentIndex;
    final currentTrackName = currentTrack?.trackName ?? '';

    if (currentIndex != _previousTrackIndex &&
        currentTrackName != _previousTrackName) {
      _animateTrackChange();
      _previousTrackIndex = currentIndex;
      _previousTrackName = currentTrackName;
    }

    if (_playerProvider.isPlaying && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!_playerProvider.isPlaying && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.animateTo(0.0,
          duration: const Duration(milliseconds: 100));
    }
    _scrollToCurrent(_playerProvider.currentIndex);
  }

  void _animateTrackChange() {
    HapticFeedback.selectionClick();
    _hasAnimatedOnce = true;
    _trackChangeController.forward(from: 0.0);
    _fadeController.forward(from: 0.0);
  }

  void _scrollToCurrent(int index, {bool isInitial = false}) {
    if (_scrollController.hasClients && index >= 0) {
      const itemHeight = 80.0; // Approximate height of our new track tile
      final screenHeight = MediaQuery.sizeOf(context).height;
      final targetOffset = (index * itemHeight) - (screenHeight / 4);
      final maxScroll = _scrollController.position.maxScrollExtent;
      final clampedOffset = targetOffset.clamp(0.0, maxScroll);

      if (isInitial) {
        _scrollController.jumpTo(clampedOffset);
      } else {
        _scrollController.animateTo(clampedOffset,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<AlbumSettingsProvider>();
    final theme = settingsProvider.matrixColorTheme;
    final themeColor = getThemeColor(theme);
    final darkThemeColor = getDarkThemeColor(theme);
    const themeAccentColor = Colors.black;
    final glowShadows = [
      const Shadow(color: themeAccentColor, blurRadius: 1),
      // Shadow(color: themeAccentColor, blurRadius: 6),
    ];

    return Scaffold(
      backgroundColor: Colors.black,
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
          SafeArea(
            child: Stack(
              children: [
                CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    _buildSliverAppBar(context, themeColor, glowShadows),
                    _buildSliverTrackList(context, themeColor, glowShadows),
                    const SliverPadding(
                      padding:
                      EdgeInsets.only(bottom: _kControlsAreaBottomPadding),
                    ),
                  ],
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: _buildControlsArea(context, settingsProvider,
                      themeColor, themeAccentColor, glowShadows),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(
      BuildContext context, Color themeColor, List<Shadow> glowShadows) {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      pinned: true,
      floating: false,
      snap: false,
      expandedHeight: 120.0,
      actions: [
        IconButton(
          icon: const Icon(Icons.delete_sweep),
          tooltip: 'Clear Playlist',
          onPressed: () => _showClearPlaylistDialog(
              context, context.read<TrackPlayerProvider>()),
        ),
      ],
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
          child: FlexibleSpaceBar(
            background: Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding:
                const EdgeInsets.only(left: 56, bottom: 16, right: 16),
                child: _buildAlbumInfo(context, themeColor, glowShadows),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlbumInfo(
      BuildContext context, Color themeColor, List<Shadow> glowShadows) {
    final provider = context.watch<TrackPlayerProvider>();
    final rawTitle = provider.currentAlbumTitle;

    String venueText;
    String dateText;

    if (rawTitle.startsWith('Live at')) {
      venueText = AlbumTitleParser.extractVenue(rawTitle);
      dateText = AlbumTitleParser.extractDate(rawTitle);
    } else {
      final parts = rawTitle.split(' - ');
      if (parts.length == 2) {
        dateText = formatDateHumanReadable(parts[0]);
        venueText = parts[1];
      } else {
        venueText = rawTitle;
        dateText = '';
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 24,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final textStyle = TextStyle(
                color: themeColor,
                fontWeight: FontWeight.bold,
                fontSize: 22,
                shadows: glowShadows,
              );

              final textPainter = TextPainter(
                text: TextSpan(text: venueText, style: textStyle),
                maxLines: 1,
                textDirection: TextDirection.ltr,
              )..layout(minWidth: 0, maxWidth: double.infinity);

              if (textPainter.width > constraints.maxWidth) {
                return Marquee(
                  text: venueText,
                  style: textStyle,
                  velocity: 40.0,
                  blankSpace: 30.0,
                );
              }
              return Text(venueText, style: textStyle);
            },
          ),
        ),
        const Gap(2),
        Text(
          dateText,
          style:
          TextStyle(color: themeColor, fontSize: 16, shadows: glowShadows),
        ),
      ],
    );
  }

  Widget _buildSliverTrackList(
      BuildContext context, Color themeColor, List<Shadow> glowShadows) {
    final provider = context.watch<TrackPlayerProvider>();
    final playlist = provider.playlist;
    final currentIndex = provider.currentIndex;

    if (playlist.isEmpty) {
      return const SliverFillRemaining(
        child: Center(
            child: Text('Playlist is empty',
                style: TextStyle(color: Colors.white))),
      );
    }

    return SliverList.separated(
      itemCount: playlist.length,
      separatorBuilder: (context, index) => const Divider(
          height: 0.5, color: Colors.white10, indent: 16, endIndent: 16),
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
                  child: _buildTrackTile(track, index, isCurrentlyPlaying,
                      themeColor, provider, glowShadows),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildTrackTile(
      dynamic track,
      int index,
      bool isCurrentlyPlaying,
      Color themeColor,
      TrackPlayerProvider provider,
      List<Shadow> glowShadows) {
    final settingsProvider = context.watch<AlbumSettingsProvider>();
    final isThisTrackInTimeout =
        isCurrentlyPlaying && provider.isLoadingTimeout;
    final formattedTitle = formatTrackTitle(track.trackName,
        hideNumber: settingsProvider.hideLeadingTrackNumberInTitle);

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
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 0.5),
      child: InkWell(
        onTap: () {
          if (!isCurrentlyPlaying) {
            HapticFeedback.lightImpact();
            provider.seekToIndex(index);
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 12.0),
          child: Row(
            children: [
              if (settingsProvider.showTrackNumbersInLists)
                Padding(
                  padding: const EdgeInsets.only(right: 16.0, left: 16.0),
                  child: Text(
                    track.trackNumber,
                    style: TextStyle(
                      color: isCurrentlyPlaying
                          ? themeColor.withOpacity(0.8)
                          : Colors.white70,
                      fontSize: 24.0,
                      shadows: isCurrentlyPlaying ? glowShadows : null,
                    ),
                  ),
                ),
              Expanded(
                child: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    final style = TextStyle(
                      color: isCurrentlyPlaying ? themeColor : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: isCurrentlyPlaying ? 28.0 : 26.0,
                      shadows: isCurrentlyPlaying ? glowShadows : null,
                    );

                    final textPainter = TextPainter(
                      text: TextSpan(text: formattedTitle, style: style),
                      maxLines: 1,
                      textDirection: TextDirection.ltr,
                    )..layout(minWidth: 0, maxWidth: double.infinity);

                    if (textPainter.width > constraints.maxWidth) {
                      return SizedBox(
                        height: 42,
                        child: Marquee(
                          text: formattedTitle,
                          style: style,
                          velocity: 70.0,
                          blankSpace: 30.0,
                          fadingEdgeStartFraction: 0.1,
                          fadingEdgeEndFraction: 0.1,
                        ),
                      );
                    } else {
                      return Text(
                        formattedTitle,
                        style: style,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                      );
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              if (isThisTrackInTimeout)
                const Icon(Icons.wifi_tethering_error_rounded,
                    color: Colors.orange, size: 28)
              else
                Text(
                  formatDurationSeconds(track.trackDuration),
                  style: TextStyle(
                    color: isCurrentlyPlaying
                        ? themeColor.withOpacity(0.8)
                        : Colors.white70,
                    shadows: isCurrentlyPlaying ? glowShadows : null,
                    fontSize: 24.0,
                  ),
                ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlsArea(
      BuildContext context,
      AlbumSettingsProvider settingsProvider,
      Color themeColor,
      Color themeAccentColor,
      List<Shadow> glowShadows) {
    final trackPlayerProvider = context.watch<TrackPlayerProvider>();
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.0),
                Colors.black.withOpacity(0.7)
              ],
              stops: const [0.0, 0.4],
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (trackPlayerProvider.isLoadingTimeout)
                LoadingTimeoutControls(
                  provider: trackPlayerProvider,
                  themeColor: themeColor,
                )
              else
                _buildPlayerTransportControls(
                    trackPlayerProvider, themeColor, glowShadows),
              const Gap(8),
              ThemedProgressBar(
                provider: trackPlayerProvider,
                activeColor: themeColor,
                shadowColor: themeAccentColor,
                bufferColor: themeColor.withOpacity(0.3),
                overlayColor: themeAccentColor.withOpacity(0.2),
              ),
              const Gap(6),
              if (settingsProvider.showBufferInfo)
                BufferInfoPanel(provider: trackPlayerProvider),
              const Gap(8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerTransportControls(TrackPlayerProvider provider,
      Color themeColor, List<Shadow> glowShadows) {
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
        _buildPlayPauseButton(provider, themeColor, glowShadows),
        IconButton(
          icon: const Icon(Icons.skip_next, size: 48.0, color: Colors.white),
          onPressed: () {
            HapticFeedback.lightImpact();
            provider.next();
          },
        ),
      ],
    );
  }

  Widget _buildPlayPauseButton(
      TrackPlayerProvider provider, Color themeColor, List<Shadow> glowShadows) {
    const heroTag = 'play_pause_button_hero_matrix';
    Widget buttonContent;
    if (provider.isLoading) {
      buttonContent = CircularProgressIndicator(
        strokeWidth: 3.0,
        valueColor: AlwaysStoppedAnimation<Color>(themeColor),
      );
    } else {
      buttonContent = AnimatedBuilder(
        animation: Listenable.merge([_trackChangeController, _pulseAnimation]),
        builder: (context, child) {
          final scale = _pulseAnimation.value *
              (1.0 + (0.1 * (1.0 - _trackChangeController.value)));
          return Transform.scale(
            scale: scale,
            child: Icon(
              provider.isPlaying
                  ? Icons.pause_circle_filled
                  : Icons.play_circle_fill,
              key: ValueKey(provider.isPlaying),
              size: 64.0,
              color: themeColor,
              shadows: glowShadows,
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
          onLongPress: () {
            provider.clearPlaylist();
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

  void _showClearPlaylistDialog(
      BuildContext context, TrackPlayerProvider provider) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Clear Playlist'),
          content: const Text(
              'Are you sure you want to clear the current playlist?'),
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
