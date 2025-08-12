// lib/pages/shows_page.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:matrix/helpers/shows_helper.dart';
import 'package:matrix/models/show.dart';
import 'package:matrix/models/track.dart';
import 'package:matrix/providers/album_settings_provider.dart';
import 'package:matrix/providers/track_player_provider.dart';
import 'package:matrix/utils/load_shows_data.dart';
import 'package:matrix/utils/duration_formatter.dart';
import 'package:provider/provider.dart';
import 'package:matrix/components/my_drawer.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:logger/logger.dart';
import 'package:marquee/marquee.dart';

class ShowsPage extends StatefulWidget {
  const ShowsPage({super.key});

  @override
  State<ShowsPage> createState() => _ShowsPageState();
}

class _ShowsPageState extends State<ShowsPage> with AutomaticKeepAliveClientMixin {
  final _logger = Logger();
  late final Future<List<Show>> _showsFuture;
  static const String _defaultAlbumArt = 'assets/images/t_steal.webp';
  String? _currentShowName;
  String? _currentSourceShnid;

  // Tracks the uniqueId of the expanded show.
  String? _expandedShowId;

  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _logger.i("ShowsPage initState: Kicking off loadShowsData.");
    _showsFuture = loadShowsData(context);
  }

  @override
  void dispose() {
    _logger.i("ShowsPage disposed.");
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.watch<TrackPlayerProvider>();

    if (provider.currentTrack == null) {
      if (_currentShowName != null || _currentSourceShnid != null) {
        setState(() {
          _currentSourceShnid = null;
          _currentShowName = null;
        });
      }
      return;
    }

    final newShowName = provider.currentAlbumTitle;
    final newShnid = provider.currentTrack?.shnid;

    if (_currentShowName != newShowName) {
      _logger.d("Show name changed: '$_currentShowName' -> '$newShowName'");

      setState(() {
        _currentShowName = newShowName;
        _currentSourceShnid = newShnid;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _scrollToCurrentShow();
        }
      });

    } else if (_currentSourceShnid != newShnid) {
      _logger.d("Source SHNID changed within the same show: '$_currentSourceShnid' -> '$newShnid'");
      setState(() {
        _currentSourceShnid = newShnid;
      });
    }
  }

  Future<void> _scrollToCurrentShow() async {
    if (_currentShowName == null || !_itemScrollController.isAttached) {
      return;
    }

    try {
      final shows = await _showsFuture;
      final sortOrder = context.read<AlbumSettingsProvider>().showSortOrder;

      shows.sort((a, b) {
        if (sortOrder == ShowSortOrder.dateDescending) {
          return b.date.compareTo(a.date);
        } else {
          return a.date.compareTo(b.date);
        }
      });
      final index = shows.indexWhere((show) => show.name == _currentShowName);

      if (index != -1) {
        _itemScrollController.scrollTo(
          index: index,
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeInOutCubic,
          alignment: 0.25,
        );
      }
    } catch (e) {
      _logger.e("Error scrolling to show: $e");
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
            onPressed: () async {
              _logger.i("Random show button pressed.");
              final shows = await _showsFuture;
              playRandomShow(shows);
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
        image: DecorationImage(image: AssetImage(_defaultAlbumArt), fit: BoxFit.cover),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(color: Colors.black.withOpacity(0.3)),
      ),
    );
  }

  Widget _buildShowsList() {
    final settings = context.watch<AlbumSettingsProvider>();
    final playerProvider = context.read<TrackPlayerProvider>();

    return FutureBuilder<List<Show>>(
      future: _showsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Could not load shows.'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No shows found.'));
        }

        final shows = snapshot.data!;

        shows.sort((a, b) {
          if (settings.showSortOrder == ShowSortOrder.dateDescending) {
            return b.date.compareTo(a.date);
          } else {
            return a.date.compareTo(b.date);
          }
        });

        return SafeArea(
          child: ScrollablePositionedList.builder(
            itemScrollController: _itemScrollController,
            itemPositionsListener: _itemPositionsListener,
            itemCount: shows.length,
            itemBuilder: (context, index) {
              final show = shows[index];
              final bool isCurrentShow = _currentSourceShnid != null && show.sources.containsKey(_currentSourceShnid);
              final titleStyle = TextStyle(
                color: isCurrentShow ? Colors.yellow : Colors.white,
                fontWeight: FontWeight.bold,
              );

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
                    title: Text("SHNID: $shnid", style: TextStyle(color: isCurrentSource ? Colors.yellow : Colors.white70, fontWeight: isCurrentSource ? FontWeight.bold : FontWeight.normal, fontStyle: FontStyle.italic, fontSize: 14)),
                    subtitle: Text("${sourceTracks.length} tracks", style: const TextStyle(color: Colors.grey, fontSize: 12)),
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
                    key: Key(show.uniqueId), // Ensures state is handled correctly on rebuild
                    initiallyExpanded: settings.singleExpansion && _expandedShowId == show.uniqueId,
                    onExpansionChanged: (isExpanding) {
                      if (settings.singleExpansion) {
                        setState(() {
                          if (isExpanding) {
                            _expandedShowId = show.uniqueId;
                          } else if (_expandedShowId == show.uniqueId) {
                            // This tile was the one expanded, and it's being collapsed
                            _expandedShowId = null;
                          }
                        });
                      }
                    },
                    title: (settings.marqueeTitles)
                        ? SizedBox(
                      height: 20,
                      child: Marquee(text: show.venue, style: titleStyle, velocity: 50.0, blankSpace: 30, pauseAfterRound: const Duration(seconds: 1)),
                    )
                        : Text(show.venue, style: titleStyle, overflow: TextOverflow.ellipsis),
                    subtitle: Text(
                      show.sourceCount > 1
                          ? "${show.date} (${show.sourceCount} sources)"
                          : show.date,
                      style: TextStyle(color: isCurrentShow ? Colors.yellow.withOpacity(0.8) : Colors.grey.shade300),
                    ),
                    iconColor: isCurrentShow ? Colors.yellow : Colors.white,
                    collapsedIconColor: Colors.white70,
                    children: children,
                  ),
                ),
              );
            },
          ),
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
          width: 50, height: 50,
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
          width: 50, height: 50,
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