// lib/components/player/song_scroll_wheel.dart

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
        _scrollToCurrentTrack(isInitial: true);
      }
    });
  }

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
      return const Center(
        child: Text(
          'No tracks available',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 16,
          ),
        ),
      );
    }

    final currentIndex = widget.trackPlayerProvider.currentIndex;

    return ScrollablePositionedList.builder(
      itemScrollController: _itemScrollController,
      scrollDirection: Axis.vertical,
      itemCount: allSongs.length,
      itemBuilder: (context, index) {
        final isCurrentTrack = (index == currentIndex);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: isCurrentTrack
                ? Colors.yellow.withOpacity(0.3)
                : Colors.transparent,
          ),
          child: Center(
            child: Text(
              allSongs[index],
              style: TextStyle(
                color: isCurrentTrack
                    ? Colors.yellow
                    : Colors.white.withOpacity(0.8),
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
