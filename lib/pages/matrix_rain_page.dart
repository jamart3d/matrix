// lib/pages/matrix_rain_page.dart

import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:matrix/components/animated_playing_fab.dart'; // <-- IMPORT THE NEW WIDGET
import 'package:matrix/components/matrix_rain/matrix_rain_column.dart';
import 'package:matrix/components/matrix_rain/matrix_rain_painter.dart';
import 'package:matrix/components/matrix_rain/matrix_search_bar.dart';
import 'package:matrix/components/my_drawer.dart';
import 'package:matrix/models/show.dart';
import 'package:matrix/providers/album_settings_provider.dart';
import 'package:matrix/providers/track_player_provider.dart';
import 'package:matrix/utils/load_shows_data.dart';
import 'package:matrix/helpers/shows_helper.dart';
import 'package:provider/provider.dart';
import 'package:matrix/routes.dart';

class MatrixRainPage extends StatefulWidget {
  const MatrixRainPage({super.key});
  @override
  State<MatrixRainPage> createState() => _MatrixRainPageState();
}

class _MatrixRainPageState extends State<MatrixRainPage> with TickerProviderStateMixin {
  late final Future<List<Show>> _showsFuture;
  final List<MatrixRainColumn> _columns = [];
  List<Show> _shows = [], _filteredShows = [];
  final Random _random = Random();
  final GlobalKey _paintKey = GlobalKey();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearchVisible = false;
  String _searchQuery = '';
  late AnimationController _rainAnimationController, _searchAnimationController;
  late Animation<double> _searchAnimation;
  Timer? _spawnTimer;
  double _currentMatrixRainSpeed = 1.0;
  int _currentColumnLimit = 50;

  final Set<int> _occupiedLanes = {};

  @override
  void initState() {
    super.initState();
    _rainAnimationController = AnimationController(vsync: this, duration: const Duration(days: 99))..addListener(_updateAnimation);
    _searchAnimationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _searchAnimation = CurvedAnimation(parent: _searchAnimationController, curve: Curves.easeInOutCubic);
    _searchController.addListener(_onSearchChanged);
    _showsFuture = loadShowsData();
    _showsFuture.then((loadedShows) {
      if (mounted) {
        final settings = context.read<AlbumSettingsProvider>();
        _currentMatrixRainSpeed = settings.matrixRainSpeed;
        _currentColumnLimit = settings.matrixColumnLimit;
        setState(() {
          _shows = loadedShows;
          _filteredShows = loadedShows;
        });
        _rainAnimationController.forward();
        _startSpawnTimer();
      }
    });
  }

  void _updateAnimation() {
    final size = _paintKey.currentContext?.size;
    if (size == null || !mounted) return;
    final playerProvider = context.read<TrackPlayerProvider>();
    final settingsProvider = context.read<AlbumSettingsProvider>();
    final currentAlbum = playerProvider.currentAlbumTitle;

    for (var column in _columns) {
      column.fall(size.height, _random, settingsProvider.matrixChaoticLeading, settingsProvider.matrixStepMode);
      column.isCurrentlyPlaying = column.showVenue == currentAlbum;
    }

    final finishedColumns = _columns.where((c) => c.isFinished).toList();
    for (final column in finishedColumns) {
      _occupiedLanes.remove(column.laneIndex);
    }
    _columns.removeWhere((c) => c.isFinished);

    setState(() {});
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    if (query == _searchQuery) return;
    setState(() {
      _searchQuery = query;
      _filteredShows = query.isEmpty
          ? _shows
          : _shows.where((s) {
        final venueMatch = s.venue.toLowerCase().contains(query);
        final yearMatch = s.year.endsWith(query);
        return venueMatch || yearMatch;
      }).toList();

      for (var column in _columns) {
        final venueMatch = column.showVenue.toLowerCase().contains(query);
        final yearMatch = column.year.endsWith(query);
        column.isHighlighted = query.isNotEmpty && (venueMatch || yearMatch);
      }
    });
  }

  void _toggleSearch() => setState(() {
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final settings = context.watch<AlbumSettingsProvider>();
    bool restart = false;
    if (settings.matrixRainSpeed != _currentMatrixRainSpeed) {
      _currentMatrixRainSpeed = settings.matrixRainSpeed;
      restart = true;
    }
    if (settings.matrixColumnLimit != _currentColumnLimit) {
      _currentColumnLimit = settings.matrixColumnLimit;
      restart = true;
    }
    if (restart && _rainAnimationController.isAnimating) _startSpawnTimer();
  }

  @override
  void dispose() {
    _rainAnimationController.dispose();
    _searchAnimationController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _spawnTimer?.cancel();
    super.dispose();
  }

  void _startSpawnTimer() {
    _spawnTimer?.cancel();
    _spawnTimer = Timer.periodic(Duration(milliseconds: (800 / _currentMatrixRainSpeed).clamp(50, 1000).round()), (_) => _spawnNewRain());
  }

  double _calculateLaneWidth(MatrixLaneSpacing spacing) {
    const baseWidth = MatrixRainColumn.hitBoxWidth;
    switch (spacing) {
      case MatrixLaneSpacing.tight:
        return baseWidth;
      case MatrixLaneSpacing.overlap:
        return baseWidth * 0.95;
      case MatrixLaneSpacing.standard:
      default:
        return baseWidth * 1.15;
    }
  }

  double _getFontSize(MatrixFontSize size) {
    switch (size) {
      case MatrixFontSize.small: return 12.0;
      case MatrixFontSize.large: return 20.0;
      case MatrixFontSize.medium:
      default: return 16.0;
    }
  }

  void _spawnNewRain() {
    if (_filteredShows.isEmpty || _columns.length >= _currentColumnLimit) return;
    final size = _paintKey.currentContext?.size;
    if (size == null) return;

    final settings = context.read<AlbumSettingsProvider>();

    final double laneWidth = _calculateLaneWidth(settings.matrixLaneSpacing);
    final int numLanes = (size.width / laneWidth).floor();
    if (numLanes <= 0) return;

    int randomLaneIndex;

    if (settings.matrixAllowOverlap) {
      randomLaneIndex = _random.nextInt(numLanes);
    } else {
      final allLanes = List.generate(numLanes, (index) => index);
      final availableLanes = allLanes.where((lane) => !_occupiedLanes.contains(lane)).toList();

      if (availableLanes.isEmpty) {
        return;
      }
      randomLaneIndex = availableLanes[_random.nextInt(availableLanes.length)];
    }

    final show = _filteredShows[_random.nextInt(_filteredShows.length)];
    final titleChars = show.venue.split('').map((c) => c == ' ' ? MatrixRainColumn.getRandomMatrixChar() : c).toList();
    final finalChars = [MatrixRainColumn.getRandomMatrixChar(), ...titleChars, MatrixRainColumn.getRandomMatrixChar()];
    if (finalChars.isEmpty) return;

    final xPosition = (randomLaneIndex * laneWidth) + (_random.nextDouble() * laneWidth * 0.5);

    _occupiedLanes.add(randomLaneIndex);

    final baseSpeed = _random.nextDouble() * 4 + 2;
    final finalSpeed = settings.matrixHalfSpeed ? baseSpeed * 0.5 : baseSpeed;

    final venueMatch = show.venue.toLowerCase().contains(_searchQuery);
    final yearMatch = show.year.endsWith(_searchQuery);

    final fontSize = _getFontSize(settings.matrixFontSize);
    final textHeight = fontSize + 4.0;

    _columns.add(MatrixRainColumn(
      characters: finalChars,
      showVenue: show.venue,
      originalVenue: show.venue,
      year: show.year,
      laneIndex: randomLaneIndex,
      xPosition: xPosition,
      yPosition: -finalChars.length * textHeight,
      speed: finalSpeed,
      textHeight: textHeight,
    )..isHighlighted = _searchQuery.isNotEmpty && (venueMatch || yearMatch));
  }

  Color _getThemeColor(MatrixColorTheme theme) {
    switch (theme) {
      case MatrixColorTheme.cyanBlue: return Colors.cyan;
      case MatrixColorTheme.purpleMatrix: return Colors.purpleAccent;
      case MatrixColorTheme.redAlert: return Colors.redAccent;
      case MatrixColorTheme.goldLux: return Colors.amber;
      case MatrixColorTheme.classicGreen:
      default: return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final playerProvider = context.watch<TrackPlayerProvider>();
    final settingsProvider = context.watch<AlbumSettingsProvider>();
    final isSearching = _searchQuery.isNotEmpty;

    return Scaffold(
      drawer: const MyDrawer(),
      floatingActionButton: _buildFloatingActionButton(playerProvider, settingsProvider),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('select a matrix'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isSearchVisible ? Icons.close : Icons.search),
            tooltip: 'Search Venues',
            onPressed: _toggleSearch,
          ),
        ],
      ),
      body: Stack(fit: StackFit.expand, children: [
        GestureDetector(
          onTapUp: (d) {
            if (_isSearchVisible) {
              _toggleSearch();
            } else {
              _handleTap(d.localPosition);
            }
          },
          child: CustomPaint(
            key: _paintKey,
            painter: MatrixRainPainter(
              columns: _columns,
              titleStyle: settingsProvider.matrixTitleStyle,
              colorTheme: settingsProvider.matrixColorTheme,
              feedbackIntensity: settingsProvider.matrixFeedbackIntensity,
              fillerStyle: settingsProvider.matrixFillerStyle,
              fillerColor: settingsProvider.matrixFillerColor,
              leadingColor: settingsProvider.matrixLeadingColor,
              glowIntensitySetting: settingsProvider.matrixGlowIntensity,
              isSearching: isSearching,
              fontSizeSetting: settingsProvider.matrixFontSize,
              fontWeightSetting: settingsProvider.matrixFontWeight,
            ),
            child: const SizedBox.expand(),
          ),
        ),
        MatrixSearchBar(
          animation: _searchAnimation,
          controller: _searchController,
          focusNode: _searchFocusNode,
        ),
      ]),
    );
  }

  // --- THIS METHOD HAS BEEN REPLACED ---
  Widget _buildFloatingActionButton(TrackPlayerProvider playerProvider, AlbumSettingsProvider settingsProvider) {
    final themeColor = _getThemeColor(settingsProvider.matrixColorTheme);
    final isLarge = settingsProvider.fabSize == FabSize.large;
    final double fabSize = isLarge ? 80.0 : 50.0;

    // The logic is now entirely handled by the new reusable widget.
    return AnimatedPlayingFab(
      heroTag: 'play_pause_button_hero_matrix', // Use a unique hero tag
      isLoading: playerProvider.isLoading,
      isPlaying: playerProvider.isPlaying,
      hasTrack: playerProvider.currentTrack != null,
      themeColor: themeColor,
      size: fabSize,
      onPressed: () => Navigator.pushNamed(context, Routes.matrixMusicPlayerPage),
    );
  }

  void _handleTap(Offset pos) {
    final tapped = _columns.cast<MatrixRainColumn?>().firstWhere((c) => c?.getBounds().contains(pos) ?? false, orElse: () => null);
    if (tapped != null) {
      final settings = context.read<AlbumSettingsProvider>();
      if(settings.matrixRippleEffects) {
        tapped.triggerRipple();
      }

      final show = _shows.cast<Show?>().firstWhere((s) => s?.venue == tapped.showVenue, orElse: () => null);
      if (show != null) {
        playTracklist(context.read<TrackPlayerProvider>(), show.primaryTracks);
      }
    }
  }
}