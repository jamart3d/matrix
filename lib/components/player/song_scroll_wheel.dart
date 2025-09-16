import 'package:flutter/material.dart';
import 'package:matrix/providers/album_settings_provider.dart';
import 'package:matrix/providers/track_player_provider.dart';
import 'package:matrix/utils/string_formatter.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class SongScrollWheel extends StatefulWidget {
  final TrackPlayerProvider trackPlayerProvider;

  const SongScrollWheel({super.key, required this.trackPlayerProvider});

  @override
  State<SongScrollWheel> createState() => _SongScrollWheelState();
}

class _SongScrollWheelState extends State<SongScrollWheel> {
  // --- SIMPLIFIED STATE ---
  // The ItemPositionsListener and related state are no longer needed.
  late ItemScrollController _itemScrollController;
  int _lastKnownIndex = -1;

  static const int _maxTitleLength = 25;
  static const Duration _scrollAnimationDuration = Duration(milliseconds: 300);

  @override
  void initState() {
    super.initState();
    _itemScrollController = ItemScrollController();
    _lastKnownIndex = widget.trackPlayerProvider.currentIndex;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Use jumpTo for the initial scroll to avoid animations on page load.
        _scrollToCurrentTrack(isInitial: true);
      }
    });
  }

  // This method is now much simpler.
  void _scrollToCurrentTrack({bool isInitial = false}) {
    final index = widget.trackPlayerProvider.currentIndex;

    if (index != -1 && _itemScrollController.isAttached) {
      if (isInitial) {
        _itemScrollController.jumpTo(index: index);
      } else {
        _itemScrollController.scrollTo(
          index: index,
          duration: _scrollAnimationDuration,
          curve: Curves.easeInOutCubic,
        );
      }
    }
  }

  @override
  void didUpdateWidget(SongScrollWheel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final currentIndex = widget.trackPlayerProvider.currentIndex;
    if (currentIndex != _lastKnownIndex) {
      _lastKnownIndex = currentIndex;
      _scrollToCurrentTrack();
    }
  }

  @override
  Widget build(BuildContext context) {
    final allSongs = _getAllSongs(context);

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

    final currentIndex = widget.trackPlayerProvider.currentIndex;

    return SizedBox(
      height: 120,
      child: ScrollablePositionedList.builder(
        itemScrollController: _itemScrollController,
        // The ItemPositionsListener is no longer needed here.
        scrollDirection: Axis.vertical,
        itemCount: allSongs.length,
        itemBuilder: (context, index) {
          final isCurrentTrack = (index == currentIndex);

          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            // The margin is now constant, not dependent on the center position.
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              // The color only depends on whether it's the current track.
              color: isCurrentTrack
                  ? Colors.yellow.withValues(alpha:0.3)
                  : Colors.transparent,
            ),
            child: Center(
              child: Text(
                allSongs[index],
                style: TextStyle(
                  // The text color only depends on whether it's the current track.
                  color: isCurrentTrack
                      ? Colors.yellow
                      : Colors.white.withValues(alpha:0.7), // Non-current tracks are slightly dimmed.
                  // There are now only two states: current or not current.
                  fontSize: isCurrentTrack ? 18 : 16,
                  fontWeight: isCurrentTrack ? FontWeight.bold : FontWeight.w400,
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

  List<String> _getAllSongs(BuildContext context) {
    final settingsProvider = context.read<AlbumSettingsProvider>();
    final playlist = widget.trackPlayerProvider.playlist;

    if (playlist.isEmpty) return [];

    List<String> songs = [];
    for (int i = 0; i < playlist.length; i++) {
      String songName = formatTrackTitle(
        playlist[i].trackName,
        hideNumber: settingsProvider.hideLeadingTrackNumberInTitle,
      );

      if (songName.length > _maxTitleLength) {
        songName = '${songName.substring(0, _maxTitleLength)}...';
      }
      songs.add(songName);
    }
    return songs;
  }
}