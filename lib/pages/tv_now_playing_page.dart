import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:huntrix/helpers/album_helper.dart'; // Import for playback logic
import 'package:provider/provider.dart';
import 'package:huntrix/models/track.dart';
import 'package:huntrix/utils/duration_formatter.dart';
import 'package:huntrix/providers/track_player_provider.dart';
import 'package:huntrix/components/player/progress_bar.dart';

class TvNowPlayingPage extends StatefulWidget {
  final List<Track> tracks;
  final String albumArt;
  final String albumName;

  const TvNowPlayingPage({
    super.key,
    required this.tracks,
    required this.albumArt,
    required this.albumName,
  });

  @override
  State<TvNowPlayingPage> createState() => _TvNowPlayingPageState();
}

class _TvNowPlayingPageState extends State<TvNowPlayingPage> {
  // Focus index is the only piece of UI state we need to manage here.
  int _focusedIndex = 0;
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Start by focusing the currently playing track.
    final provider = context.read<TrackPlayerProvider>();
    _focusedIndex = provider.currentIndex;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusNode);
      _scrollToFocusedItem(initial: true);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    setState(() {
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        _focusedIndex = (_focusedIndex + 1).clamp(0, widget.tracks.length - 1);
        _scrollToFocusedItem();
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        _focusedIndex = (_focusedIndex - 1).clamp(0, widget.tracks.length - 1);
        _scrollToFocusedItem();
      } else if (event.logicalKey == LogicalKeyboardKey.select || event.logicalKey == LogicalKeyboardKey.enter) {
        _handleSelection();
      }
    });
  }

  void _scrollToFocusedItem({bool initial = false}) {
    if (!_scrollController.hasClients) return;
    // A simple and effective way to ensure the focused item is visible.
    final targetOffset = (_focusedIndex * 56.0) - (MediaQuery.of(context).size.height / 4);
    _scrollController.animateTo(
      targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: Duration(milliseconds: initial ? 0 : 300),
      curve: Curves.easeInOut,
    );
  }

  /// Refactored: Uses the robust album_helper for playback.
  void _handleSelection() {
    final trackToPlay = widget.tracks[_focusedIndex];
    final provider = context.read<TrackPlayerProvider>();
    
    // Only call the helper if we are not already playing this track.
    if (provider.currentTrack != trackToPlay) {
      playTrackFromAlbum(widget.tracks, trackToPlay);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the provider to make the UI reactive to player state changes.
    final provider = context.watch<TrackPlayerProvider>();

    // If the player's current index changes, update our focused index.
    if (provider.currentIndex != _focusedIndex) {
      setState(() {
        _focusedIndex = provider.currentIndex;
      });
      // Use a post-frame callback to scroll after the UI has been updated.
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToFocusedItem());
    }

    return Scaffold(
      body: KeyboardListener(
        focusNode: _focusNode,
        onKeyEvent: _handleKeyEvent,
        child: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              // Use the provider's current art for a dynamic background.
              image: AssetImage(provider.currentAlbumArt),
              fit: BoxFit.cover,
            ),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
            child: Container(
              color: Colors.black.withOpacity(0.5),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(flex: 2, child: _buildLeftSide(provider)),
                    Expanded(flex: 3, child: _buildRightSide(provider)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeftSide(TrackPlayerProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16.0),
            child: Image.asset(provider.currentAlbumArt, fit: BoxFit.cover),
          ),
          const SizedBox(height: 20),
          Text(
            provider.currentTrack?.trackName ?? "No Track Playing",
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          Text(
            provider.currentAlbumTitle,
            style: const TextStyle(color: Colors.white70, fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ProgressBar(provider: provider),
        ],
      ),
    );
  }

  Widget _buildRightSide(TrackPlayerProvider provider) {
    return ListView.builder(
      controller: _scrollController,
      itemCount: widget.tracks.length,
      itemBuilder: (context, index) {
        final track = widget.tracks[index];
        final bool isCurrentlyPlaying = provider.currentTrack == track;
        final bool isFocused = _focusedIndex == index;

        return GestureDetector(
          onTap: () => setState(() {
            _focusedIndex = index;
            _handleSelection();
          }),
          child: Container(
            decoration: BoxDecoration(
              color: isFocused ? Colors.white.withOpacity(0.3) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListTile(
              leading: Text(
                '${index + 1}',
                style: TextStyle(
                  color: isCurrentlyPlaying ? Colors.yellow : Colors.white70,
                  fontSize: 18,
                ),
              ),
              title: Text(
                track.trackName,
                style: TextStyle(
                  color: isCurrentlyPlaying ? Colors.yellow : Colors.white,
                  fontSize: 18,
                  fontWeight: isFocused || isCurrentlyPlaying ? FontWeight.bold : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    formatDurationSeconds(track.trackDuration),
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(width: 20),
                  // Conditionally show the smart play/pause/loading button
                  if (isCurrentlyPlaying) _buildPlayPauseButton(provider),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// **REFRACTORED: Smart Play/Pause Button**
  /// This button now shows a loading indicator during buffering.
  Widget _buildPlayPauseButton(TrackPlayerProvider provider) {
    if (provider.isLoading) {
      return const SizedBox(
        width: 24, // Icon button default size
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2.0, color: Colors.white),
      );
    }
    
    return IconButton(
      icon: Icon(
        provider.isPlaying ? Icons.pause_circle_outline : Icons.play_circle_outline,
        color: Colors.white,
      ),
      onPressed: provider.isPlaying ? provider.pause : provider.play,
    );
  }
}