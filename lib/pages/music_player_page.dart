import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:huntrix/components/player/progress_bar.dart';
import 'package:huntrix/pages/track_playlist_page.dart';
import 'package:huntrix/providers/track_player_provider.dart';
import 'package:provider/provider.dart';
import 'package:logger/logger.dart';

class MusicPlayerPage extends StatelessWidget {
  const MusicPlayerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final trackPlayerProvider = Provider.of<TrackPlayerProvider>(context);
    final logger = Provider.of<Logger>(context);

    logger.d('Building MusicPlayerPage');

    // Load album and artist data (will use cached data if applicable)
    trackPlayerProvider.loadAlbumAndArtistData();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Now Playing'),
        actions: [
          IconButton(
            icon: const Icon(Icons.queue_music),
            onPressed: () {
              logger.i("Navigating to TrackPlaylistPage");
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
      body: trackPlayerProvider.playlist.isEmpty
          ? const Center(
              child: Text('No songs in playlist'),
            )
          : Column(
              children: [
                Expanded(
                  child: _buildAlbumArt(trackPlayerProvider, context),
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Track Title
                      Text(
                        trackPlayerProvider
                            .playlist[trackPlayerProvider.currentIndex]
                            .trackName,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center, // Center the text
                      ),
                      const Gap.expand(10),

                      // Playback Controls
                      _PlaybackControls(
                          trackPlayerProvider: trackPlayerProvider,
                          logger: logger),
                      const SizedBox(height: 10),

                      // Progress Bar
                      _ProgressBar(trackPlayerProvider: trackPlayerProvider),
                      const SizedBox(height: 10),

                      // Album Name
                      Text(
                        trackPlayerProvider.currentAlbumTitle,
                        style: const TextStyle(fontSize: 16),
                        textAlign: TextAlign.center, // Center the text
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildAlbumArt(
      TrackPlayerProvider trackPlayerProvider, BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;

    // Calculate the desired height for the album art
    final albumArtHeight =
        (screenHeight * 0.5).toInt(); // Adjust the 0.5 factor as needed

    // Use the calculated height and width to set the album art size
    return Center(
      child: SizedBox(
        width: screenWidth,
        height: albumArtHeight.toDouble(),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4.0),
          ),
          child: ClipRRect(
            // Apply rounded corners to the image directly
            borderRadius: BorderRadius.circular(4.0),
            child: Image.asset(
              trackPlayerProvider.currentAlbumArt,
              fit: BoxFit.cover, // Ensure the image covers the entire container
              errorBuilder: (context, error, stackTrace) {
                return Image.asset('assets/images/t_steal.webp');
              },
            ),
          ),
        ),
      ),
    );
  }
}

// Playback Controls Widget
class _PlaybackControls extends StatelessWidget {
  final TrackPlayerProvider trackPlayerProvider;
  final Logger logger;

  const _PlaybackControls({required this.trackPlayerProvider, required this.logger});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: trackPlayerProvider
          .audioPlayer.playingStream, // Listen to the playing stream
      builder: (context, snapshot) {
        final isPlaying = snapshot.data ?? false;

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(
                Icons.skip_previous,
                size: 40,
                color: Colors.deepPurple,
              ),
              onPressed: () {
                trackPlayerProvider.previous();
                logger.i('Previous button pressed');
              },
            ),
            IconButton(
              icon: Icon(
                isPlaying ? Icons.pause_circle : Icons.play_circle,
                color: Colors.deepPurple,
                size: 60,
              ),
              onPressed: () {
                if (isPlaying) {
                  trackPlayerProvider.pause();
                  logger.i('Pause button pressed');
                } else {
                  trackPlayerProvider.play();
                  logger.i('Play button pressed');
                }
              },
            ),
            IconButton(
              icon: const Icon(
                Icons.skip_next,
                size: 40,
                color: Colors.deepPurple,
              ),
              onPressed: () {
                trackPlayerProvider.next();
                logger.i('Next button pressed');
              },
            ),
          ],
        );
      },
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
