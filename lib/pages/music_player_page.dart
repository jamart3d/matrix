// lib/pages/music_player_page.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:logger/logger.dart';
import 'package:matrix/components/player/album_art_view.dart';
import 'package:matrix/components/player/playback_controls.dart';
import 'package:matrix/pages/track_playlist_page.dart';
import 'package:matrix/providers/album_settings_provider.dart';
import 'package:matrix/providers/track_player_provider.dart';
import 'package:matrix/utils/string_formatter.dart';
import 'package:provider/provider.dart';
import 'package:matrix/components/player/progress_bar.dart';
import '../components/player/buffer_info_panel.dart';
import 'package:matrix/components/player/loading_timeout_controls.dart';
import 'package:marquee/marquee.dart';

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

  // Constants for styling
  static const double _albumArtBlurRadius = 15.0;
  static const double _appBarFontSize = 24.0;
  static const Duration _fadeAnimationDuration = Duration(milliseconds: 800);

  @override
  void initState() {
    super.initState();
    _logger.d('_MusicPlayerPageState initState called');

    _animationController = AnimationController(
      vsync: this,
      duration: _fadeAnimationDuration,
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));

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
          fontSize: _appBarFontSize,
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
      child: RepaintBoundary(
        child: BackdropFilter(
          filter: ImageFilter.blur(
              sigmaX: _albumArtBlurRadius, sigmaY: _albumArtBlurRadius),
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
                ? _buildEmptyState()
                : SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    const Spacer(flex: 1),
                    // Layer 1: The Album Art.
                    AlbumArtView(
                      albumArt: albumArt,
                      heroTag: 'album_art_$albumArt',
                    ),
                    const Spacer(flex: 2),
                    // Layer 2: The current song info.
                    _buildTrackInfo(context),
                    const Spacer(flex: 2),
                    // Layer 3: The playback controls and info, grouped at the bottom.
                    if (trackPlayerProvider.isLoadingTimeout)
                      Padding(
                        padding:
                        const EdgeInsets.symmetric(vertical: 16.0),
                        child: LoadingTimeoutControls(
                          provider: trackPlayerProvider,
                          themeColor: Colors.yellow,
                        ),
                      )
                    else
                      const PlaybackControls(),
                    const Gap(12),
                    ProgressBar(provider: trackPlayerProvider),
                    const Gap(8),
                    if (settingsProvider.showBufferInfo)
                      BufferInfoPanel(provider: trackPlayerProvider),
                    const Gap(8),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrackInfo(BuildContext context) {
    final trackPlayerProvider = context.watch<TrackPlayerProvider>();
    final settingsProvider = context.watch<AlbumSettingsProvider>();
    final currentTrack = trackPlayerProvider.currentTrack;

    if (currentTrack == null) {
      return const SizedBox.shrink();
    }

    final formattedTitle = formatTrackTitle(
      currentTrack.trackName,
      hideNumber: settingsProvider.hideLeadingTrackNumberInTitle,
    );

    const titleStyle = TextStyle(
      color: Colors.yellow,
      fontSize: 24,
      fontWeight: FontWeight.bold,
      shadows: [
        Shadow(color: Colors.redAccent, blurRadius: 3),
        Shadow(color: Colors.redAccent, blurRadius: 6),
      ],
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // For the track title
        SizedBox(
          height: 30, // to contain marquee
          child: LayoutBuilder(
            builder: (context, constraints) {
              final textPainter = TextPainter(
                text: TextSpan(text: formattedTitle, style: titleStyle),
                maxLines: 1,
                textDirection: TextDirection.ltr,
              )..layout(minWidth: 0, maxWidth: double.infinity);

              if (textPainter.width > constraints.maxWidth) {
                return Marquee(
                  text: formattedTitle,
                  style: titleStyle,
                  velocity: 40.0,
                  blankSpace: 30.0,
                );
              }
              return Text(
                formattedTitle,
                style: titleStyle,
                textAlign: TextAlign.center,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return const Center(
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
    );
  }
}
