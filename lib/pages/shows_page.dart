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

class _ShowsPageState extends State<ShowsPage>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  late final Future<List<Show>> _showsFuture;
  List<Show> _originalShows = [];
  String? _currentShowName;
  bool _showDeepLinkMessage = false;

  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
  ItemPositionsListener.create();

  // --- SEARCH STATE ---
  bool _isSearchVisible = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  late AnimationController _searchAnimationController;
  late Animation<double> _searchAnimation;

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

    // --- SEARCH INITIALIZATION ---
    _searchAnimationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _searchAnimation =
        CurvedAnimation(parent: _searchAnimationController, curve: Curves.easeInOutCubic);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _searchAnimationController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_searchQuery != _searchController.text) {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    }
  }

  void _toggleSearch() {
    setState(() {
      _isSearchVisible = !_isSearchVisible;
      if (_isSearchVisible) {
        _searchAnimationController.forward();
        _searchFocusNode.requestFocus();
      } else {
        _searchAnimationController.reverse();
        _searchController.clear();
        _searchFocusNode.unfocus();
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
    if (_currentShowName == null ||
        !_itemScrollController.isAttached ||
        _originalShows.isEmpty) {
      return;
    }

    final category = ModalRoute.of(context)?.settings.arguments as String?;
    final filteredShows = _getFilteredShows(category);
    final sortedShows = _getSortedShows(
        filteredShows, context.read<AlbumSettingsProvider>().showSortOrder);
    final searchedShows = _getSearchedShows(sortedShows);

    final index = searchedShows.indexWhere((show) => show.name == _currentShowName);

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
    return _originalShows
        .where((show) => show.sourceCreator == category)
        .toList();
  }

  List<Show> _getSortedShows(List<Show> shows, ShowSortOrder sortOrder) {
    final sorted = List<Show>.from(shows);
    sorted.sort((a, b) => (sortOrder == ShowSortOrder.dateDescending)
        ? b.date.compareTo(a.date)
        : a.date.compareTo(b.date));
    return sorted;
  }

  List<Show> _getSearchedShows(List<Show> shows) {
    if (_searchQuery.isEmpty) {
      return shows;
    }
    return shows.where((show) {
      final venueMatch = show.venue.toLowerCase().contains(_searchQuery);
      final yearMatch = show.year.contains(_searchQuery);
      final dateMatch = show.date.contains(_searchQuery);
      return venueMatch || yearMatch || dateMatch;
    }).toList();
  }

  String _getPageTitle(String? category) {
    switch (category) {
      case 'seamons':
        return "Seamons' matrix -> ";
      case 'tobin':
        return "random Tobin's -> ";
      case 'sirmick':
        return "random SirMick's -> ";
      case 'dusborne':
        return "random Dusborne's -> ";
      case 'misc':
        return "random misc maxtrix - >";
      default:
        return "select a random show - >";
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
    final searchedShows = _getSearchedShows(sortedShows);

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
              if (searchedShows.isNotEmpty) {
                playRandomShow(playerProvider, searchedShows);
              }
            },
          ),
          IconButton(
            icon: Icon(_isSearchVisible ? Icons.close : Icons.search),
            tooltip: 'Search Shows',
            onPressed: _toggleSearch,
          ),
        ],
      ),
      drawer: const MyDrawer(),
      floatingActionButton:
      _buildFloatingActionButton(playerProvider, settingsProvider),
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
                return Center(
                    child:
                    Text('Could not load shows. Error: ${snapshot.error}'));
              }
              return Column(
                children: [
                  _buildSearchBar(),
                  Expanded(
                    child: ShowList(
                      shows: searchedShows,
                      itemScrollController: _itemScrollController,
                      itemPositionsListener: _itemPositionsListener,
                    ),
                  ),
                ],
              );
            },
          ),
          if (_showDeepLinkMessage) _buildDeepLinkNotification(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return SizeTransition(
      sizeFactor: _searchAnimation,
      axisAlignment: -1.0,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white30),
        ),
        child: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Search by venue, year, or date...',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
            icon: const Icon(Icons.search, color: Colors.white70),
            border: InputBorder.none,
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
              icon: const Icon(Icons.clear, color: Colors.white70),
              onPressed: () {
                _searchController.clear();
              },
            )
                : null,
          ),
        ),
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

  Widget _buildFloatingActionButton(
      TrackPlayerProvider playerProvider, AlbumSettingsProvider settingsProvider) {
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
      decoration: const BoxDecoration(
          image: DecorationImage(
              image: AssetImage('assets/images/t_steal.webp'),
              fit: BoxFit.cover)),
      child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: Container(color: Colors.black.withOpacity(0.3))),
    );
  }
}
