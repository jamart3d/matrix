// lib/pages/music_player_page.dart

import 'dart:ui';
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
      duration: const Duration(milliseconds: 600),
    );

    _opacityAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(parent: _animationController, curve: Curves.easeIn)
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
      appBar: AppBar(
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
      ),
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

  Widget _buildMusicPlayerContent(
      BuildContext context, TrackPlayerProvider trackPlayerProvider) {
    final albumArt = trackPlayerProvider.currentAlbumArt;
    final Color shadowColor = Colors.redAccent;
    final settingsProvider = context.watch<AlbumSettingsProvider>();

    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(image: AssetImage(albumArt), fit: BoxFit.cover),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          color: Colors.black.withOpacity(0.5),
          child: trackPlayerProvider.currentTrack == null
              ? const Center(
            child: Text(
              'No Tracks Available',
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
          )
              : SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  _buildAlbumArt(albumArt),
                  const Gap(30),
                  Text(
                    trackPlayerProvider.currentTrack!.trackName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                      color: Colors.yellow,
                      shadows: [
                        Shadow(color: shadowColor, blurRadius: 3),
                        Shadow(color: shadowColor, blurRadius: 6),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const Spacer(),
                  const _PlaybackControls(),
                  const Gap(20),
                  _ProgressBar(trackPlayerProvider: trackPlayerProvider),
                  const Gap(10),
                  if (settingsProvider.showBufferInfo)
                    BufferInfoPanel(provider: trackPlayerProvider),
                  const Gap(10),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlbumArt(String albumArt) {
    return AspectRatio(
      aspectRatio: 1,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.asset(
          albumArt,
          gaplessPlayback: true,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Center(child: Icon(Icons.music_note, color: Colors.white, size: 50));
          },
        ),
      ),
    );
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
  final Curve _animationCurve = Curves.easeInOut;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: _animationCurve,
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
    final double fabSize = isLarge ? 70.0 : 56.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(
            Icons.skip_previous,
            size: 40,
            color: Colors.yellow,
            shadows: [
              Shadow(color: Colors.redAccent, blurRadius: 3),
              Shadow(color: Colors.redAccent, blurRadius: 6),
            ],
          ),
          onPressed: trackPlayerProvider.previous,
        ),
        const Gap(20),

        Hero(
          tag: heroTag,
          createRectTween: (begin, end) {
            return SeamlessRectTween(curve: _animationCurve, begin: begin!, end: end!);
          },
          child: Material(
            color: Colors.transparent,
            child: Consumer<TrackPlayerProvider>(
              builder: (context, provider, child) {
                if (provider.isPlaying && !_animationController.isAnimating) {
                  _animationController.repeat(reverse: true);
                } else if (!provider.isPlaying && _animationController.isAnimating) {
                  _animationController.stop();
                  _animationController.animateTo(0.0, duration: const Duration(milliseconds: 100));
                }

                return Container(
                  width: fabSize,
                  height: fabSize,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                  ),
                  child: GestureDetector(
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
                    child: Center(
                      child: provider.isLoading
                          ? const CircularProgressIndicator(
                        strokeWidth: 3.0,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.yellow),
                      )
                          : ScaleTransition(
                        scale: _scaleAnimation,
                        child: Icon(
                          provider.isPlaying ? Icons.pause_circle : Icons.play_circle,
                          size: fabSize,
                          color: Colors.yellow,
                          shadows: const [
                            Shadow(color: Colors.redAccent, blurRadius: 3),
                            Shadow(color: Colors.redAccent, blurRadius: 6),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        const Gap(20),
        IconButton(
          icon: const Icon(
            Icons.skip_next,
            size: 40,
            color: Colors.yellow,
            shadows: [
              Shadow(color: Colors.redAccent, blurRadius: 3),
              Shadow(color: Colors.redAccent, blurRadius: 6),
            ],
          ),
          onPressed: trackPlayerProvider.next,
        ),
      ],
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final TrackPlayerProvider trackPlayerProvider;

  const _ProgressBar({required this.trackPlayerProvider});

  @override
  Widget build(BuildContext context) {
    return ProgressBar(provider: trackPlayerProvider);
  }
}