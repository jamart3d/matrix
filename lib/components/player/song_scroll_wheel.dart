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
  late ItemPositionsListener _itemPositionsListener;
  int _currentVisibleIndex = 0;
  String? _lastKnownTrackName;

  static const int _maxTitleLength = 25;
  static const Duration _scrollDelay = Duration(milliseconds: 100);

  @override
  void initState() {
    super.initState();
    _itemScrollController = ItemScrollController();
    _itemPositionsListener = ItemPositionsListener.create();
    _lastKnownTrackName = widget.trackPlayerProvider.currentTrack?.trackName;

    _itemPositionsListener.itemPositions.addListener(() {
      final positions = _itemPositionsListener.itemPositions.value;
      if (positions.isNotEmpty) {
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(_scrollDelay, () {
        if (mounted) {
          _scrollToCurrentTrack();
        }
      });
    });
  }

  void _scrollToCurrentTrack() {
    final playlist = widget.trackPlayerProvider.playlist;
    final currentTrack = widget.trackPlayerProvider.currentTrack;

    if (currentTrack == null || playlist.isEmpty) return;

    int index = -1;
    for (int i = 0; i < playlist.length; i++) {
      if (playlist[i].trackName == currentTrack.trackName) {
        index = i;
        break;
      }
    }

    if (index != -1 && _itemScrollController.isAttached) {
      try {
        _itemScrollController.jumpTo(index: index);
        setState(() {
          _currentVisibleIndex = index;
        });
      } catch (e) {
        // Silent fallback
      }
    }
  }

  bool _isTrackMatch(String displayTitle, String currentTrack, bool hideNumbers) {
    final formatted = formatTrackTitle(currentTrack, hideNumber: hideNumbers);
    final normalizedDisplay = displayTitle.toLowerCase().trim().replaceAll('...', '');
    final normalizedCurrent = formatted.toLowerCase().trim();

    return normalizedDisplay == normalizedCurrent ||
        normalizedCurrent.startsWith(normalizedDisplay);
  }

  @override
  void didUpdateWidget(SongScrollWheel oldWidget) {
    super.didUpdateWidget(oldWidget);

    final currentTrackName = widget.trackPlayerProvider.currentTrack?.trackName;

    if (currentTrackName != _lastKnownTrackName) {
      _lastKnownTrackName = currentTrackName;

      if (currentTrackName != null) {
        Future.delayed(_scrollDelay, () {
          if (mounted) _scrollToCurrentTrack();
        });
      }
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

    final settingsProvider = context.watch<AlbumSettingsProvider>();
    final currentRawTrackName = widget.trackPlayerProvider.currentTrack?.trackName ?? '';

    return SizedBox(
      height: 120,
      child: ScrollablePositionedList.builder(
        itemScrollController: _itemScrollController,
        itemPositionsListener: _itemPositionsListener,
        scrollDirection: Axis.vertical,
        itemCount: allSongs.length,
        itemBuilder: (context, index) {
          final songTitle = allSongs[index];
          final isCurrentTrack = _isTrackMatch(
            songTitle,
            currentRawTrackName,
            settingsProvider.hideLeadingTrackNumberInTitle,
          );
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
                songTitle,
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