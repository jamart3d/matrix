// lib/pages/shows_page.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:matrix/components/animated_playing_fab.dart';
import 'package:matrix/components/my_drawer.dart';
import 'package:matrix/components/shows/show_list.dart';
import 'package:matrix/helpers/shows_helper.dart';
import 'package:matrix/models/show.dart';
import 'package:matrix/providers/album_settings_provider.dart';
import 'package:matrix/providers/track_player_provider.dart';
import 'package:matrix/providers/enums.dart';
import 'package:matrix/routes.dart';
import 'package:matrix/utils/load_shows_data.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class ShowsPage extends StatefulWidget {
  const ShowsPage({super.key});

  @override
  State<ShowsPage> createState() => _ShowsPageState();
}

class _ShowsPageState extends State<ShowsPage> with AutomaticKeepAliveClientMixin {
  late final Future<List<Show>> _showsFuture;
  List<Show> _originalShows = [];
  String? _currentShowName;
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
        _checkAndScrollOnLoad();
      }
    });
  }

  void _checkAndScrollOnLoad() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final playerProvider = context.read<TrackPlayerProvider>();
        if (playerProvider.currentTrack != null) {
          setState(() {
            _currentShowName = playerProvider.currentAlbumTitle;
          });
          _scrollToCurrentShow();
        }
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
    if (_currentShowName != newShowName) {
      setState(() {
        _currentShowName = newShowName;
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
      _itemScrollController.scrollTo(
        index: index,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOutCubic,
        alignment: 0.25,
      );
    }
  }

  List<Show> _getFilteredShows(String? category) {
    if (category == null) {
      return _originalShows;
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
          FutureBuilder<List<Show>>(
            future: _showsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Could not load shows. Error: ${snapshot.error}'));
              }
              return ShowList(
                shows: sortedShows,
                itemScrollController: _itemScrollController,
                itemPositionsListener: _itemPositionsListener,
              );
            },
          ),
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
      shadowColor: Colors.redAccent,
      size: fabSize,
      onPressed: () => Navigator.pushNamed(context, Routes.showsMusicPlayerPage),
      onLongPress: () => context.read<TrackPlayerProvider>().clearPlaylist(),
    );
  }

  Widget _buildBlurredBackground() {
    return Container(
      decoration: const BoxDecoration(image: DecorationImage(image: AssetImage('assets/images/t_steal.webp'), fit: BoxFit.cover)),
      child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0), child: Container(color: Colors.black.withOpacity(0.3))),
    );
  }
}