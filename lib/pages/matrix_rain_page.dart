// lib/pages/matrix_rain_page.dart

import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:matrix/models/show.dart';
import 'package:matrix/providers/album_settings_provider.dart'; // <-- IMPORT ADDED
import 'package:matrix/providers/track_player_provider.dart';
import 'package:matrix/utils/load_shows_data.dart';
import 'package:matrix/helpers/shows_helper.dart';
import 'package:provider/provider.dart';

// ... (MatrixRainColumn class is unchanged) ...
class MatrixRainColumn {
  final List<String> characters;
  final String showVenue;
  double xPosition;
  double yPosition;
  final double speed;
  bool isFinished = false;

  MatrixRainColumn({
    required this.characters,
    required this.showVenue,
    required this.xPosition,
    required this.yPosition,
    required this.speed,
  });

  void fall(double screenHeight) {
    yPosition += speed;
    if (yPosition > screenHeight) {
      isFinished = true;
    }
  }
}


class MatrixRainPage extends StatefulWidget {
  const MatrixRainPage({super.key});

  @override
  State<MatrixRainPage> createState() => _MatrixRainPageState();
}

class _MatrixRainPageState extends State<MatrixRainPage> {
  late final Future<List<Show>> _showsFuture;
  final List<MatrixRainColumn> _columns = [];
  List<Show> _shows = [];
  final Random _random = Random();
  final GlobalKey _paintKey = GlobalKey();
  Timer? _animationTimer;
  Timer? _spawnTimer;

  static const List<Color> _greenShades = [
    Color(0xFF003B00),
    Color(0xFF008F11),
    Color(0xFF00C725),
    Color(0xFF00FF41),
  ];

  @override
  void initState() {
    super.initState();
    _showsFuture = loadShowsData();
    _showsFuture.then((loadedShows) {
      if (mounted) {
        setState(() => _shows = loadedShows);
        _startTimers(); // Pass context here if needed, or use context.read later
      }
    }).catchError((_) {});
  }

  @override
  void dispose() {
    _animationTimer?.cancel();
    _spawnTimer?.cancel();
    super.dispose();
  }

  void _startTimers() {
    _animationTimer = Timer.periodic(const Duration(milliseconds: 40), (_) {
      if (!mounted) return;
      setState(() {
        final size = _paintKey.currentContext?.size;
        if (size == null) return;
        for (var column in _columns) {
          column.fall(size.height);
        }
        _columns.removeWhere((column) => column.isFinished);
      });
    });

    // --- IMPROVEMENT: Spawn timer now uses the value from the provider ---
    // Use context.read to get the setting once when the timer starts.
    final settings = context.read<AlbumSettingsProvider>();

    // Convert the slider value (1-10) to a duration.
    // A higher value means more density, so a shorter duration.
    // We use an inverse relationship. 800ms for speed 1, 80ms for speed 10.
    final int spawnMilliseconds = (800 / settings.matrixRainSpeed).clamp(50, 1000).round();

    _spawnTimer = Timer.periodic(Duration(milliseconds: spawnMilliseconds), (_) {
      if (!mounted) return;
      setState(() {
        _spawnNewRain();
      });
    });
  }

  // ... (_spawnNewRain and other methods are unchanged) ...
  void _spawnNewRain() {
    if (_shows.isEmpty) return;
    final size = _paintKey.currentContext?.size;
    if (size == null) return;

    final show = _shows[_random.nextInt(_shows.length)];

    final titleChars = show.venue.split('').map((char) {
      if (char == ' ') {
        return String.fromCharCode(_random.nextInt(512));
      }
      return char;
    }).toList();

    final String randomTailChar = String.fromCharCode(_random.nextInt(512));
    titleChars.add(randomTailChar);

    final String leadingChar = String.fromCharCode(_random.nextInt(512));
    final List<String> finalCharacters = [...titleChars, leadingChar];

    if (finalCharacters.isEmpty) return;

    _columns.add(
      MatrixRainColumn(
        characters: finalCharacters,
        showVenue: show.venue,
        xPosition: _random.nextDouble() * size.width,
        yPosition: -finalCharacters.length * 20.0,
        speed: _random.nextDouble() * 4 + 2,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Matrix Rain'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/t_steal.webp'),
                fit: BoxFit.cover,
              ),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
              child: Container(color: Colors.black.withOpacity(0.3)),
            ),
          ),
          FutureBuilder<List<Show>>(
            future: _showsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
              }

              final loadedShows = snapshot.data;
              if (loadedShows == null || loadedShows.isEmpty) {
                return const Center(child: Text("No shows found.", style: TextStyle(color: Colors.white)));
              }

              return Consumer<TrackPlayerProvider>(
                builder: (context, trackPlayer, child) {
                  final currentAlbumTitle = trackPlayer.currentAlbumTitle;

                  return GestureDetector(
                    onLongPress: () => playRandomShow(loadedShows),
                    child: ShaderMask(
                      shaderCallback: (Rect bounds) {
                        return const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: [0.0, 0.4, 1.0],
                          colors: <Color>[Colors.transparent, Colors.black, Colors.black],
                        ).createShader(bounds);
                      },
                      blendMode: BlendMode.dstIn,
                      child: Stack(
                        key: _paintKey,
                        children: _columns.map((col) => _buildColumnWidget(col, currentAlbumTitle)).toList(),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildColumnWidget(MatrixRainColumn column, String? currentAlbumTitle) {
    final bool isCurrentShowColumn = column.showVenue == currentAlbumTitle;

    return Positioned(
      top: column.yPosition,
      left: column.xPosition,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(column.characters.length, (index) {
          Color charColor;
          FontWeight fontWeight = FontWeight.normal;

          if (index == column.characters.length - 1) {
            charColor = isCurrentShowColumn ? Colors.yellow : Colors.white;
            fontWeight = FontWeight.bold;
          } else {
            charColor = _greenShades.reversed.toList()[index % _greenShades.length];
          }

          return Text(
            column.characters[index],
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 16,
              height: 1.1,
              color: charColor,
              fontWeight: fontWeight,
              shadows: [
                Shadow(
                  color: charColor,
                  blurRadius: (index == column.characters.length - 1) ? (isCurrentShowColumn ? 12 : 8) : 4,
                )
              ],
            ),
          );
        }),
      ),
    );
  }
}