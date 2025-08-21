// lib/pages/shows_page.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:matrix/components/animated_playing_fab.dart';
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
import 'package:matrix/routes.dart';

class ShowsPage extends StatefulWidget {
  const ShowsPage({super.key});

  @override
  State<ShowsPage> createState() => _ShowsPageState();
}

class _ShowsPageState extends State<ShowsPage> with AutomaticKeepAliveClientMixin {
  late final Future<List<Show>> _showsFuture;
  List<Show> _originalShows = [];
  String? _currentShowName;
  String? _currentSourceShnid;
  bool _showDeepLinkMessage = false;

  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _showsFuture = loadShowsData();
    _showsFuture.then((shows) {
      if (mounted) {
        setState(() {
          _originalShows = shows;
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final playerProvider = context.watch<TrackPlayerProvider>();

    if (playerProvider.wasInitiatedByDeepLink) {
      playerProvider.consumeDeepLinkInitiation();
      _showDeepLinkNotification();
    }

    final newShowName = playerProvider.currentAlbumTitle;
    final newShnid = playerProvider.currentTrack?.shnid;

    if (_currentShowName != newShowName || _currentSourceShnid != newShnid) {
      setState(() {
        _currentShowName = newShowName;
        _currentSourceShnid = newShnid;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scrollToCurrentShow();
      });
    }
  }

  void _showDeepLinkNotification() {
    setState(() => _showDeepLinkMessage = true);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showDeepLinkMessage = false);
    });
  }

  Future<void> _scrollToCurrentShow() async {
    if (_currentShowName == null || !_itemScrollController.isAttached || _originalShows.isEmpty) return;

    final category = ModalRoute.of(context)?.settings.arguments as String?;
    final filteredShows = _getFilteredShows(category);
    final sortedShows = _getSortedShows(filteredShows, context.read<AlbumSettingsProvider>().showSortOrder);

    final index = sortedShows.indexWhere((show) => show.name == _currentShowName);

    if (index != -1) {
      _itemScrollController.scrollTo(index: index, duration: const Duration(milliseconds: 700), curve: Curves.easeInOutCubic, alignment: 0.25);
    }
  }

  List<Show> _getFilteredShows(String? category) {
    if (category == null) {
      return _originalShows; // Return all shows
    }
    return _originalShows.where((show) => show.sourceCreator == category).toList();
  }

  List<Show> _getSortedShows(List<Show> shows, ShowSortOrder sortOrder) {
    final sorted = List<Show>.from(shows);
    sorted.sort((a, b) => (sortOrder == ShowSortOrder.dateDescending) ? b.date.compareTo(a.date) : a.date.compareTo(b.date));
    return sorted;
  }

  String _getPageTitle(String? category) {
    switch (category) {
      case 'seamons': return "Seamons' matrix -> ";
      case 'tobin': return "random Tobin's -> ";
      case 'sirmick': return "random SirMick's -> ";
      case 'dusborne': return "random Dusborne's -> ";
      case 'misc': return "random misc maxtrix - >";
      default: return "select a random show - >";
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final playerProvider = context.watch<TrackPlayerProvider>();
    final settingsProvider = context.watch<AlbumSettingsProvider>();

    final category = ModalRoute.of(context)?.settings.arguments as String?;
    final pageTitle = _getPageTitle(category);

    final filteredShows = _getFilteredShows(category);
    final sortedShows = _getSortedShows(filteredShows, settingsProvider.showSortOrder);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        // --- UPDATED: Dynamic title ---
        title: Text(pageTitle),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.question_mark),
            tooltip: 'Play Random Show',
            onPressed: () {
              if (sortedShows.isNotEmpty) {
                playRandomShow(playerProvider, sortedShows);
              }
            },
          ),
        ],
      ),
      drawer: const MyDrawer(),
      floatingActionButton: _buildFloatingActionButton(playerProvider, settingsProvider),
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildBlurredBackground(),
          _buildShowsList(sortedShows),
          if (_showDeepLinkMessage) _buildDeepLinkNotification(),
        ],
      ),
    );
  }

  Widget _buildDeepLinkNotification() {
    return Positioned(
      top: 20,
      left: 20,
      right: 20,
      child: AnimatedOpacity(
        opacity: _showDeepLinkMessage ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 500),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.9),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Row(
            children: [
              Icon(Icons.assistant, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Google Assistant activated! Playing random show...",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton(TrackPlayerProvider playerProvider, AlbumSettingsProvider settingsProvider) {
    final isLarge = settingsProvider.fabSize == FabSize.large;
    final double fabSize = isLarge ? 80.0 : 50.0;

    return AnimatedPlayingFab(
      heroTag: 'play_pause_button_hero_shows',
      isLoading: playerProvider.isLoading,
      isPlaying: playerProvider.isPlaying,
      hasTrack: playerProvider.currentTrack != null,
      themeColor: Colors.yellow,
      size: fabSize,
      onPressed: () => Navigator.pushNamed(context, Routes.showsMusicPlayerPage),
    );
  }

  Widget _buildBlurredBackground() {
    return Container(
      decoration: const BoxDecoration(image: DecorationImage(image: AssetImage('assets/images/t_steal.webp'), fit: BoxFit.cover)),
      child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0), child: Container(color: Colors.black.withOpacity(0.3))),
    );
  }

  Widget _buildShowsList(List<Show> showsToDisplay) {
    return FutureBuilder<List<Show>>(
      future: _showsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Could not load shows. Error: ${snapshot.error}'));
        }
        if (showsToDisplay.isEmpty) {
          return const Center(child: Text('No shows found for this category.', style: TextStyle(color: Colors.white, fontSize: 16)));
        }

        final settings = context.watch<AlbumSettingsProvider>();
        final playerProvider = context.read<TrackPlayerProvider>();

        final showYears = showsToDisplay
            .map((show) => int.tryParse(show.year) ?? 0)
            .where((year) => year > 0)
            .toList();

        Widget mainContent = ScrollablePositionedList.builder(
          itemScrollController: _itemScrollController,
          itemPositionsListener: _itemPositionsListener,
          itemCount: showsToDisplay.length,
          itemBuilder: (context, index) => _buildShowTile(settings, playerProvider, showsToDisplay[index]),
        );

        return SafeArea(
          child: settings.yearScrollbarBehavior != YearScrollbarBehavior.off
              ? YearScrollbar(
            years: showYears,
            itemPositionsListener: _itemPositionsListener,
            itemScrollController: _itemScrollController,
            alwaysShow: settings.yearScrollbarBehavior == YearScrollbarBehavior.always,
            child: mainContent,
          )
              : mainContent,
        );
      },
    );
  }

  Widget _buildShowTile(AlbumSettingsProvider settings, TrackPlayerProvider playerProvider, Show show) {
    final bool isCurrentShow = _currentSourceShnid != null && show.sources.containsKey(_currentSourceShnid);
    final titleStyle = TextStyle(color: isCurrentShow ? Colors.yellow : Colors.white, fontWeight: FontWeight.bold);

    return GestureDetector(
      onLongPress: () {
        playTracklist(playerProvider, show.primaryTracks);
        Navigator.pushNamed(context, Routes.showsMusicPlayerPage);
      },
      child: Card(
        color: isCurrentShow ? Colors.yellow.withOpacity(0.2) : Colors.black.withOpacity(0.4),
        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: ExpansionTile(
          key: PageStorageKey<String>(show.uniqueId),
          title: Text(show.venue, style: titleStyle, overflow: TextOverflow.ellipsis),
          subtitle: Text(show.sourceCount > 1 ? "${show.date} (${show.sourceCount} sources)" : show.date, style: TextStyle(color: isCurrentShow ? Colors.yellow.withOpacity(0.8) : Colors.grey.shade300)),
          children: _buildExpansionChildren(playerProvider, show),
        ),
      ),
    );
  }

  List<Widget> _buildExpansionChildren(TrackPlayerProvider playerProvider, Show show) {
    if (show.sourceCount == 1) {
      return show.sources.values.first.map((track) => _buildTrackTile(playerProvider, track, show.sources.values.first)).toList();
    } else {
      return show.sources.entries.map((entry) {
        final shnid = entry.key;
        final sourceTracks = entry.value;
        final bool isCurrentSource = shnid == _currentSourceShnid;
        return ExpansionTile(
          tilePadding: const EdgeInsets.only(left: 32.0, right: 16.0),
          title: Text("SHNID: $shnid", style: TextStyle(color: isCurrentSource ? Colors.yellow : Colors.white70, fontWeight: isCurrentSource ? FontWeight.bold : FontWeight.normal, fontStyle: FontStyle.italic, fontSize: 14)),
          children: sourceTracks.map((track) => _buildTrackTile(playerProvider, track, sourceTracks)).toList(),
        );
      }).toList();
    }
  }

  Widget _buildTrackTile(TrackPlayerProvider playerProvider, Track track, List<Track> sourceTracks) {
    // ... (This method is unchanged)
    final bool isCurrentlyPlaying = playerProvider.currentTrack == track;
    return Container(
      color: isCurrentlyPlaying ? Colors.yellow.withOpacity(0.15) : Colors.transparent,
      child: ListTile(
        contentPadding: const EdgeInsets.only(left: 48.0, right: 16.0),
        leading: Text(track.trackNumber, style: TextStyle(color: isCurrentlyPlaying ? Colors.yellow : Colors.grey.shade300)),
        title: Text(track.trackName, style: TextStyle(color: isCurrentlyPlaying ? Colors.yellow : Colors.white)),
        trailing: Text(formatDurationSeconds(track.trackDuration), style: TextStyle(color: isCurrentlyPlaying ? Colors.yellow.withOpacity(0.8) : Colors.grey.shade400)),
        onTap: () {
          playTracklistFrom(playerProvider, sourceTracks, track);
          Navigator.pushNamed(context, Routes.showsMusicPlayerPage);
        },
        dense: true,
      ),
    );
  }
}