// lib/pages/matrix_rain_page.dart

import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:matrix/components/matrix_rain/matrix_rain_column.dart';
import 'package:matrix/components/matrix_rain/matrix_rain_painter.dart';
import 'package:matrix/components/matrix_rain/matrix_search_bar.dart';
import 'package:matrix/models/show.dart';
import 'package:matrix/providers/album_settings_provider.dart';
import 'package:matrix/providers/track_player_provider.dart';
import 'package:matrix/utils/load_shows_data.dart';
import 'package:matrix/helpers/shows_helper.dart';
import 'package:provider/provider.dart';
import 'package:matrix/components/my_drawer.dart';
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
  late AnimationController _controller, _searchAnimationController;
  late Animation<double> _searchAnimation;
  Timer? _spawnTimer;
  double _currentMatrixRainSpeed = 1.0;
  int _currentColumnLimit = 50;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(days: 99))..addListener(_updateAnimation);
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
        _controller.forward();
        _startSpawnTimer();
      }
    });
  }

  void _updateAnimation() {
    final size = _paintKey.currentContext?.size;
    if (size == null || !mounted) return;
    final playerProvider = context.read<TrackPlayerProvider>(), settingsProvider = context.read<AlbumSettingsProvider>();
    final currentAlbum = playerProvider.currentAlbumTitle;
    final bool glowEnabled = settingsProvider.matrixGlowStyle != MatrixGlowStyle.none;
    final bool rippleEnabled = settingsProvider.matrixRippleEffects;
    for (var column in _columns) {
      column.fall(size.height);
      column.isCurrentlyPlaying = glowEnabled && (column.showVenue == currentAlbum);
      if (!rippleEnabled) column.rippleEffect = 0;
    }
    _columns.removeWhere((c) => c.isFinished);
    setState(() {});
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    if (query == _searchQuery) return;
    setState(() {
      _searchQuery = query;
      _filteredShows = query.isEmpty ? _shows : _shows.where((s) => s.venue.toLowerCase().contains(query)).toList();
      for (var column in _columns) {
        column.isHighlighted = query.isNotEmpty && column.showVenue.toLowerCase().contains(query);
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
    if (restart && _controller.isAnimating) _startSpawnTimer();
  }

  @override
  void dispose() {
    _controller.dispose();
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

  void _spawnNewRain() {
    if (_filteredShows.isEmpty || _columns.length >= _currentColumnLimit) return;
    final size = _paintKey.currentContext?.size;
    if (size == null) return;
    final show = _filteredShows[_random.nextInt(_filteredShows.length)];
    final titleChars = show.venue.split('').map((c) => c == ' ' ? String.fromCharCode(_random.nextInt(512)) : c).toList();
    final finalChars = [String.fromCharCode(_random.nextInt(512)), ...titleChars, String.fromCharCode(_random.nextInt(512))];
    if (finalChars.isEmpty) return;
    final playerProvider = context.read<TrackPlayerProvider>();
    _columns.add(MatrixRainColumn(
      characters: finalChars,
      showVenue: show.venue,
      originalVenue: show.venue,
      xPosition: _random.nextDouble() * size.width,
      yPosition: -finalChars.length * MatrixRainColumn.textHeight,
      speed: _random.nextDouble() * 4 + 2,
    )
      ..isHighlighted = _searchQuery.isNotEmpty && show.venue.toLowerCase().contains(_searchQuery)
      ..isCurrentlyPlaying = show.venue == playerProvider.currentAlbumTitle);
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
        Container(decoration: const BoxDecoration(image: DecorationImage(image: AssetImage('assets/images/t_steal.webp'), fit: BoxFit.cover)), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0), child: Container(color: Colors.black.withOpacity(0.3)))),
        FutureBuilder<List<Show>>(
          future: _showsFuture,
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
            return GestureDetector(
              onTapUp: (d) => _handleTap(d.localPosition),
              onLongPress: () {
                playRandomShow(playerProvider, _filteredShows);
                Navigator.pushNamed(context, Routes.matrixMusicPlayerPage);
              },
              child: Consumer<AlbumSettingsProvider>(
                builder: (context, settings, child) => CustomPaint(
                  key: _paintKey,
                  painter: MatrixRainPainter(
                    columns: _columns,
                    titleStyle: settings.matrixTitleStyle,
                    colorTheme: settings.matrixColorTheme,
                    feedbackIntensity: settings.matrixFeedbackIntensity,
                    fillerStyle: settings.matrixFillerStyle,
                    fillerColor: settings.matrixFillerColor,
                    glowStyle: settings.matrixGlowStyle,
                    leadingColor: settings.matrixLeadingColor,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            );
          },
        ),
        MatrixSearchBar(
          animation: _searchAnimation,
          controller: _searchController,
          focusNode: _searchFocusNode,
        ),
      ]),
    );
  }

  Widget? _buildFloatingActionButton(TrackPlayerProvider playerProvider, AlbumSettingsProvider settingsProvider) {
    const heroTag = 'matrix_play_pause_hero';
    final themeColor = _getThemeColor(settingsProvider.matrixColorTheme);

    if (playerProvider.isLoading) {
      return FloatingActionButton(
        heroTag: heroTag,
        onPressed: null,
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: SizedBox(
          width: 50, height: 50,
          child: CircularProgressIndicator(strokeWidth: 3.0, valueColor: AlwaysStoppedAnimation<Color>(themeColor)),
        ),
      );
    }
    if (playerProvider.currentTrack != null) {
      return FloatingActionButton(
        heroTag: heroTag,
        onPressed: () {
          Navigator.pushNamed(context, Routes.matrixMusicPlayerPage);
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Icon(
          Icons.play_circle_fill,
          color: themeColor,
          shadows: [Shadow(color: themeColor.withOpacity(0.7), blurRadius: 4)],
          size: 50,
        ),
      );
    }
    return null;
  }

  void _handleTap(Offset pos) {
    final tapped = _columns.cast<MatrixRainColumn?>().firstWhere((c) => c?.getBounds().contains(pos) ?? false, orElse: () => null);
    if (tapped != null) {
      tapped.triggerRipple();
      final show = _shows.cast<Show?>().firstWhere((s) => s?.venue == tapped.showVenue, orElse: () => null);
      if (show != null) {
        playTracklist(context.read<TrackPlayerProvider>(), show.primaryTracks);
        Navigator.pushNamed(context, Routes.matrixMusicPlayerPage);
      }
    }
  }
}