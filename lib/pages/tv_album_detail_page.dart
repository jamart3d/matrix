import 'dart:ui';
// This is the corrected import statement.
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:huntrix/helpers/album_helper.dart'; // Import the helper
import 'package:huntrix/models/track.dart';
import 'package:huntrix/pages/tv_now_playing_page.dart';
import 'package:huntrix/providers/track_player_provider.dart';
import 'package:huntrix/utils/duration_formatter.dart';
import 'package:provider/provider.dart';

class TvAlbumDetailPage extends StatefulWidget {
  final List<Track> tracks;
  final String albumArt;
  final String albumName;

  const TvAlbumDetailPage({
    super.key,
    required this.tracks,
    required this.albumArt,
    required this.albumName,
  });

  @override
  State<TvAlbumDetailPage> createState() => _TvAlbumDetailPageState();
}

class _TvAlbumDetailPageState extends State<TvAlbumDetailPage> {
  int _focusedIndex = 0;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Request focus for the page so keyboard events are captured immediately.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusNode);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    setState(() {
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        _focusedIndex = (_focusedIndex + 1).clamp(0, widget.tracks.length - 1);
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        _focusedIndex = (_focusedIndex - 1).clamp(0, widget.tracks.length - 1);
      } else if (event.logicalKey == LogicalKeyboardKey.select || event.logicalKey == LogicalKeyboardKey.enter) {
        // When a track is selected, call the refactored method.
        _selectTrack(widget.tracks[_focusedIndex]);
      }
    });
  }

  /// Uses the album_helper to handle playback, making this method much cleaner.
  void _selectTrack(Track selectedTrack) {
    // The helper function contains all the logic to start playback from the correct track.
    playTrackFromAlbum(widget.tracks, selectedTrack);
    
    // Navigate to the now playing screen.
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => TvNowPlayingPage(
          tracks: widget.tracks,
          albumArt: widget.albumArt,
          albumName: widget.albumName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: KeyboardListener(
        focusNode: _focusNode,
        onKeyEvent: _handleKeyEvent,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Blurred background
            _buildBlurredBackground(),
            // Content
            SafeArea(
              child: Row(
                children: [
                  // Left panel: Album art and details
                  Expanded(flex: 1, child: _buildAlbumHeader()),
                  // Right panel: Track list
                  Expanded(flex: 1, child: _buildTrackList()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlurredBackground() {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(image: AssetImage(widget.albumArt), fit: BoxFit.cover),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(color: Colors.black.withOpacity(0.5)),
      ),
    );
  }

  Widget _buildAlbumHeader() {
    final bool isSpecialRelease = widget.albumName == '1982-04-10 - Capitol Theatre';
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16.0),
            child: Image.asset(widget.albumArt, fit: BoxFit.cover),
          ),
          const Gap(20),
          Text(
            widget.albumName,
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const Gap(10),
          Text(
            '${widget.tracks.length} tracks',
            style: const TextStyle(color: Colors.white70, fontSize: 24),
          ),
          if (isSpecialRelease) ...[
            const Gap(10),
            Row(
              children: const [
                Icon(Icons.album, color: Colors.green, size: 30),
                Gap(10),
                Text('Special Release', style: TextStyle(color: Colors.green, fontSize: 24)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTrackList() {
    // Use a Consumer widget to rebuild only the track list when the player state changes.
    // This is more efficient than rebuilding the whole page.
    return Consumer<TrackPlayerProvider>(
      builder: (context, provider, child) {
        return ListView.builder(
          itemCount: widget.tracks.length,
          itemBuilder: (context, index) {
            final track = widget.tracks[index];
            final bool isFocused = _focusedIndex == index;
            final bool isCurrentlyPlaying = provider.currentTrack == track;

            return GestureDetector(
              onTap: () => setState(() { // Allow mouse/tap to change focus
                _focusedIndex = index;
                _selectTrack(track);
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                decoration: BoxDecoration(
                  color: isFocused ? Colors.white.withOpacity(0.3) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: isCurrentlyPlaying ? Colors.yellow : Colors.white70,
                        fontSize: 24,
                      ),
                    ),
                    const Gap(16),
                    Expanded(
                      child: Text(
                        track.trackName,
                        style: TextStyle(
                          color: isCurrentlyPlaying ? Colors.yellow : Colors.white,
                          fontSize: 24,
                          fontWeight: isFocused || isCurrentlyPlaying ? FontWeight.bold : FontWeight.normal,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Gap(16),
                    Text(
                      formatDurationSeconds(track.trackDuration),
                      style: TextStyle(
                        color: isCurrentlyPlaying ? Colors.yellow.withOpacity(0.8) : Colors.white70,
                        fontSize: 24,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}