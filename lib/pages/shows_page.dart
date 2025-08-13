// lib/pages/shows_page.dart

import 'dart:ui';
import 'package:flutter/foundation.dart'; // <-- IMPORT ADDED HERE
import 'package:flutter/material.dart';
import 'package:matrix/helpers/shows_helper.dart';
import 'package:matrix/models/show.dart';
import 'package:matrix/models/track.dart';
import 'package:matrix/providers/album_settings_provider.dart';
import 'package:matrix/providers/track_player_provider.dart';
import 'package:matrix/utils/load_shows_data.dart';
import 'package:matrix/utils/duration_formatter.dart';
import 'package:matrix/components/year_scrollbar.dart';
import 'package:provider/provider.dart';
import 'package:matrix/components/my_drawer.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:logger/logger.dart';
import 'package:marquee/marquee.dart';

// Top-level logger for consistent logging.
final _logger = Logger();

class ShowsPage extends StatefulWidget {
  const ShowsPage({super.key});

  @override
  State<ShowsPage> createState() => _ShowsPageState();
}

class _ShowsPageState extends State<ShowsPage> with AutomaticKeepAliveClientMixin {
  // Futures and Data
  late final Future<List<Show>> _showsFuture;
  List<Show> _originalShows = [];
  List<Show> _sortedShows = [];

  // State
  String? _currentShowName;
  String? _currentSourceShnid;
  String? _expandedShowId; // Tracks the uniqueId of the expanded show.

  // Controllers
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();

  // Keep state when switching tabs/pages.
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _logger.i("ShowsPage initState: Kicking off data load.");
    // 1. Data loading is now independent of context.
    _showsFuture = loadShowsData();
    // 2. Once data is loaded, store it and perform the initial sort.
    _showsFuture.then((shows) {
      if (mounted) {
        final settings = context.read<AlbumSettingsProvider>();
        setState(() {
          _originalShows = shows;
          _sortAndRefreshShows(settings.showSortOrder);
        });
      }
    }).catchError((error) {
      _logger.e("Error loading shows data: $error");
    });
  }

  @override
  void dispose() {
    _logger.i("ShowsPage disposed.");
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final playerProvider = context.watch<TrackPlayerProvider>();
    final settingsProvider = context.watch<AlbumSettingsProvider>();

    // Sort shows if the sort order preference changes.
    _sortAndRefreshShows(settingsProvider.showSortOrder);

    // Update state based on the currently playing track.
    final newShowName = playerProvider.currentAlbumTitle;
    final newShnid = playerProvider.currentTrack?.shnid;

    if (_currentShowName != newShowName || _currentSourceShnid != newShnid) {
      setState(() {
        _currentShowName = newShowName;
        _currentSourceShnid = newShnid;
      });

      // After the state is updated, scroll to the current show.
      if (newShowName != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _scrollToCurrentShow();
          }
        });
      }
    }
  }

  /// Sorts the original list of shows based on the provided order and updates the state.
  void _sortAndRefreshShows(ShowSortOrder sortOrder) {
    // Create a new sorted list from the original data.
    final sorted = List<Show>.from(_originalShows);
    sorted.sort((a, b) {
      return (sortOrder == ShowSortOrder.dateDescending)
          ? b.date.compareTo(a.date)
          : a.date.compareTo(b.date);
    });

    // Only update state if the sorted list is actually different.
    if (!listEquals(_sortedShows, sorted)) {
      setState(() {
        _sortedShows = sorted;
      });
    }
  }


  Future<void> _scrollToCurrentShow() async {
    if (_currentShowName == null || !_itemScrollController.isAttached || _sortedShows.isEmpty) {
      return;
    }

    // Find the index in the *already sorted* list.
    final index = _sortedShows.indexWhere((show) => show.name == _currentShowName);

    if (index != -1) {
      _itemScrollController.scrollTo(
        index: index,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOutCubic,
        alignment: 0.25, // Aligns the item 25% from the top of the viewport.
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.black,
        title: const Text("Select a random show -->"),
        actions: [
          IconButton(
            icon: const Icon(Icons.question_mark),
            tooltip: 'Play Random Show',
            onPressed: () {
              if (_originalShows.isNotEmpty) {
                _logger.i("Random show button pressed.");
                playRandomShow(_originalShows);
              }
            },
          ),
        ],
      ),
      drawer: const MyDrawer(),
      floatingActionButton: _buildFloatingActionButton(),
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildBlurredBackground(),
          _buildShowsList(),
        ],
      ),
    );
  }

  Widget _buildBlurredBackground() {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(image: AssetImage('assets/images/t_steal.webp'), fit: BoxFit.cover),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(color: Colors.black.withOpacity(0.3)),
      ),
    );
  }

  Widget _buildShowsList() {
    return FutureBuilder<List<Show>>(
      future: _showsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Could not load shows. Error: ${snapshot.error}'));
        }
        if (_sortedShows.isEmpty) {
          return const Center(child: Text('No shows found.'));
        }

        final settings = context.watch<AlbumSettingsProvider>();
        final playerProvider = context.read<TrackPlayerProvider>();

        final showYears = _sortedShows
            .map((show) => int.tryParse(show.year) ?? 0)
            .where((year) => year > 0)
            .toList();

        Widget mainContent = ScrollablePositionedList.builder(
          itemScrollController: _itemScrollController,
          itemPositionsListener: _itemPositionsListener,
          itemCount: _sortedShows.length,
          itemBuilder: (context, index) {
            final show = _sortedShows[index];
            final bool isCurrentShow = _currentSourceShnid != null && show.sources.containsKey(_currentSourceShnid);
            final titleStyle = TextStyle(
              color: isCurrentShow ? Colors.yellow : Colors.white,
              fontWeight: FontWeight.bold,
            );

            final isExpanded = settings.singleExpansion && _expandedShowId == show.uniqueId;

            List<Widget> children;
            if (show.sourceCount == 1) {
              final singleSourceTracks = show.sources.values.first;
              children = singleSourceTracks.map((track) => _buildTrackTile(track, singleSourceTracks)).toList();
            } else {
              children = show.sources.entries.map((entry) {
                final shnid = entry.key;
                final sourceTracks = entry.value;
                final bool isCurrentSource = shnid == _currentSourceShnid;

                return ExpansionTile(
                  tilePadding: const EdgeInsets.only(left: 32.0, right: 16.0),
                  title: Text(
                    "SHNID: $shnid",
                    style: TextStyle(
                      color: isCurrentSource ? Colors.yellow : Colors.white70,
                      fontWeight: isCurrentSource ? FontWeight.bold : FontWeight.normal,
                      fontStyle: FontStyle.italic,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    "${sourceTracks.length} tracks",
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  iconColor: isCurrentSource ? Colors.yellow : Colors.white,
                  collapsedIconColor: Colors.white70,
                  children: sourceTracks.map((track) => _buildTrackTile(track, sourceTracks)).toList(),
                );
              }).toList();
            }

            return GestureDetector(
              onLongPress: () async {
                await playerProvider.clearPlaylist();
                playTracklist(show.primaryTracks);
                if (mounted) {
                  Navigator.pushNamed(context, '/shows_music_player_page');
                }
              },
              child: Card(
                color: isCurrentShow ? Colors.yellow.withOpacity(0.2) : Colors.black.withOpacity(0.4),
                margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: ExpansionTile(
                  key: PageStorageKey<String>(show.uniqueId),
                  initiallyExpanded: isExpanded,
                  onExpansionChanged: (isExpanding) {
                    if (settings.singleExpansion) {
                      setState(() {
                        if (isExpanding) {
                          _expandedShowId = show.uniqueId;
                        } else if (_expandedShowId == show.uniqueId) {
                          _expandedShowId = null;
                        }
                      });
                    }
                  },
                  title: (settings.marqueeTitles)
                      ? SizedBox(
                    height: 20,
                    child: Marquee(
                      text: show.venue,
                      style: titleStyle,
                      velocity: 50.0,
                      blankSpace: 30,
                      pauseAfterRound: const Duration(seconds: 1),
                    ),
                  )
                      : Text(show.venue, style: titleStyle, overflow: TextOverflow.ellipsis),
                  subtitle: Text(
                    show.sourceCount > 1 ? "${show.date} (${show.sourceCount} sources)" : show.date,
                    style: TextStyle(color: isCurrentShow ? Colors.yellow.withOpacity(0.8) : Colors.grey.shade300),
                  ),
                  iconColor: isCurrentShow ? Colors.yellow : Colors.white,
                  collapsedIconColor: Colors.white70,
                  children: children,
                ),
              ),
            );
          },
        );

        return SafeArea(
          child: settings.showYearScrollbar
              ? YearScrollbar(
            years: showYears,
            itemPositionsListener: _itemPositionsListener,
            child: mainContent,
          )
              : mainContent,
        );
      },
    );
  }

  Widget _buildTrackTile(Track track, List<Track> sourceTracks) {
    final provider = context.watch<TrackPlayerProvider>();
    final bool isCurrentlyPlaying = provider.currentTrack == track;

    return Container(
      color: isCurrentlyPlaying ? Colors.yellow.withOpacity(0.15) : Colors.transparent,
      child: ListTile(
        contentPadding: const EdgeInsets.only(left: 48.0, right: 16.0),
        leading: Text(
          track.trackNumber,
          style: TextStyle(color: isCurrentlyPlaying ? Colors.yellow : Colors.grey.shade300),
        ),
        title: Text(
          track.trackName,
          style: TextStyle(color: isCurrentlyPlaying ? Colors.yellow : Colors.white),
        ),
        trailing: Text(
          formatDurationSeconds(track.trackDuration),
          style: TextStyle(color: isCurrentlyPlaying ? Colors.yellow.withOpacity(0.8) : Colors.grey.shade400),
        ),
        onTap: () {
          playTracklistFrom(sourceTracks, track);
          Navigator.pushNamed(context, '/shows_music_player_page');
        },
        dense: true,
      ),
    );
  }

  Widget? _buildFloatingActionButton() {
    final playerProvider = context.watch<TrackPlayerProvider>();

    if (playerProvider.isLoading) {
      return FloatingActionButton(
        onPressed: null,
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const SizedBox(
          width: 50,
          height: 50,
          child: CircularProgressIndicator(strokeWidth: 3.0, valueColor: AlwaysStoppedAnimation<Color>(Colors.yellow)),
        ),
      );
    }

    if (playerProvider.currentTrack != null) {
      return FloatingActionButton(
        onPressed: () {
          _scrollToCurrentShow();
          Navigator.pushNamed(context, '/shows_music_player_page');
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const SizedBox(
          width: 50,
          height: 50,
          child: Icon(
            Icons.play_circle_fill,
            color: Colors.yellow,
            shadows: [Shadow(color: Colors.redAccent, blurRadius: 4)],
            size: 50,
          ),
        ),
      );
    }

    return null;
  }
}