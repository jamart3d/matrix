// lib/pages/music_player_page.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:logger/logger.dart';
import 'package:matrix/pages/track_playlist_page.dart';
import 'package:matrix/providers/track_player_provider.dart';
import 'package:provider/provider.dart';
import 'package:matrix/components/player/progress_bar.dart';

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
                        const Gap(4),
                        Text(
                          trackPlayerProvider.currentTrack!.trackArtistName,
                          style: const TextStyle(fontSize: 16, color: Colors.white70),
                          textAlign: TextAlign.center,
                        ),
                        const Spacer(),
                        const _PlaybackControls(), 
                        const Gap(20),
                        _ProgressBar(trackPlayerProvider: trackPlayerProvider),
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

class _PlaybackControls extends StatelessWidget {
  const _PlaybackControls();

  @override
  Widget build(BuildContext context) {
    // We get the provider once for the side buttons.
    final trackPlayerProvider = context.read<TrackPlayerProvider>();

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
        
        // --- FIX IS HERE ---
        // This Consumer widget will listen for changes and rebuild ONLY the center button.
        Consumer<TrackPlayerProvider>(
          builder: (context, provider, child) {
            // Case 1: Player is loading.
            if (provider.isLoading) {
              return const SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  strokeWidth: 3.0,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.yellow),
                ),
              );
            }

            // Case 2: Player is ready, so show the correct play/pause icon.
            return IconButton(
              icon: Icon(
                provider.isPlaying ? Icons.pause_circle : Icons.play_circle,
                size: 60,
                color: Colors.yellow,
                shadows: const [
                  Shadow(color: Colors.redAccent, blurRadius: 3),
                  Shadow(color: Colors.redAccent, blurRadius: 6),
                ],
              ),
              onPressed: () {
                // The onPressed callback now correctly toggles the state.
                if (provider.isPlaying) {
                  provider.pause();
                } else {
                  provider.play();
                }
              },
            );
          },
        ),
        // --- END OF FIX ---
        
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