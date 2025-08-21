import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:matrix/components/my_drawer.dart';
import 'package:matrix/helpers/album_helper.dart';
import 'package:matrix/models/album.dart';
import 'package:matrix/pages/album_detail_page.dart';
import 'package:matrix/providers/album_settings_provider.dart';
import 'package:matrix/providers/track_player_provider.dart';
import 'package:matrix/services/album_data_service.dart';
import 'package:provider/provider.dart';
// import 'package:logger/logger.dart';

class AlbumListWheelPage extends StatefulWidget {
  const AlbumListWheelPage({super.key});

  @override
  State<AlbumListWheelPage> createState() => _AlbumListWheelPageState();
}

class _AlbumListWheelPageState extends State<AlbumListWheelPage> {
  // final _logger = Logger(printer: PrettyPrinter(methodCount: 1));

  late final Future<void> _initializationFuture;

  // State variables
  String _currentAlbumArt = 'assets/images/t_steal.webp';
  String? _highlightedAlbumName; // This is ONLY controlled by the player's state

  // Controllers
  late final FixedExtentScrollController _scrollController;
  late final TrackPlayerProvider _playerProvider;

  bool _isInitialSetupComplete = false;

  @override
  void initState() {
    super.initState();
    _scrollController = FixedExtentScrollController();

    _playerProvider = context.read<TrackPlayerProvider>();
    _playerProvider.addListener(_onPlayerChange);

    _initializationFuture = AlbumDataService().init();
  }

  @override
  void dispose() {
    _playerProvider.removeListener(_onPlayerChange);
    _scrollController.dispose();
    super.dispose();
  }

  // --- THIS METHOD IS NOW THE ONLY SOURCE OF TRUTH FOR HIGHLIGHTS ---
  void _onPlayerChange() {
    final currentlyPlayingSong = _playerProvider.currentTrack;
    String newArt = 'assets/images/t_steal.webp';
    String? newAlbumName;

    if (currentlyPlayingSong != null) {
      final album = AlbumDataService().albums.cast<Album?>().firstWhere(
              (a) => a?.name == currentlyPlayingSong.albumName,
          orElse: () => null
      );
      if (album != null) {
        newArt = album.albumArt;
        newAlbumName = album.name;
      }
    }

    // Only update state and scroll if the album has actually changed
    if (newAlbumName != _highlightedAlbumName) {
      if (mounted) {
        setState(() {
          _currentAlbumArt = newArt;
          _highlightedAlbumName = newAlbumName;
        });
        if (newAlbumName != null) {
          _scrollToPlayingAlbum();
        }
      }
    }
  }

  void _setupInitialState(List<Album> albums) {
    if (!mounted || _isInitialSetupComplete || albums.isEmpty) return;

    final currentlyPlaying = _playerProvider.currentTrack;

    // Set initial state based on the player
    if (currentlyPlaying != null) {
      final album = albums.cast<Album?>().firstWhere((a) => a?.name == currentlyPlaying.albumName, orElse: () => null);
      if (album != null) {
        _currentAlbumArt = album.albumArt;
        _highlightedAlbumName = album.name;
        final initialIndex = albums.indexOf(album);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.jumpToItem(initialIndex);
          }
        });
      }
    } else {
      // Default to the first album art if nothing is playing
      _currentAlbumArt = albums.first.albumArt;
      _highlightedAlbumName = null; // Nothing is highlighted
    }

    _isInitialSetupComplete = true;
  }

  void _scrollToPlayingAlbum() {
    final currentlyPlaying = _playerProvider.currentTrack;
    if (currentlyPlaying == null || !_scrollController.hasClients) return;

    final albums = AlbumDataService().albums;
    final index = albums.indexWhere((album) => album.name == currentlyPlaying.albumName);

    if (index != -1 && _scrollController.selectedItem != index) {
      _scrollController.animateToItem(
        index,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      drawer: const MyDrawer(),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(_currentAlbumArt),
            fit: BoxFit.cover,
            onError: (e,s) => setState(() => _currentAlbumArt = 'assets/images/t_steal.webp'),
          ),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            color: Colors.black.withOpacity(0.5),
            child: FutureBuilder<void>(
              future: _initializationFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final albums = AlbumDataService().albums;
                _setupInitialState(albums);

                if (albums.isEmpty) {
                  return const Center(child: Text("No albums available."));
                }

                return _buildAlbumWheel(albums);
              },
            ),
          ),
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text("Hunter's Matrix"),
      centerTitle: true,
      forceMaterialTransparency: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.question_mark),
          onPressed: () {
            if (AlbumDataService().albums.isNotEmpty) {
              playRandomAlbum(AlbumDataService().albums);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please wait for albums to load')),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildAlbumWheel(List<Album> albums) {
    final albumSettings = context.watch<AlbumSettingsProvider>();
    return LayoutBuilder(
      builder: (context, constraints) {
        final double itemExtent = constraints.maxHeight * 0.5;

        return NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification is ScrollUpdateNotification) {
              if (notification.metrics.pixels % itemExtent < 1) {
                HapticFeedback.selectionClick();
              }
            }
            return true;
          },
          child: ListWheelScrollView.useDelegate(
            controller: _scrollController,
            itemExtent: itemExtent,
            diameterRatio: 2.0,
            perspective: 0.002,
            physics: const FixedExtentScrollPhysics(),
            // --- UPDATED: This no longer changes state, only provides feedback ---
            onSelectedItemChanged: (index) {
              HapticFeedback.mediumImpact();
            },
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: albums.length,
              builder: (context, index) {
                final album = albums[index];
                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AlbumDetailPage(
                        tracks: album.tracks,
                        albumArt: album.albumArt,
                        albumName: album.name,
                      ),
                    ),
                  ),
                  onLongPress: () => playAlbumFromTracks(album.tracks),
                  child: _buildWheelItem(album, albumSettings, itemExtent),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildWheelItem(Album album, AlbumSettingsProvider settings, double itemExtent) {
    // This now correctly and exclusively reflects the player's state
    final isSelected = _highlightedAlbumName == album.name;

    return Container(
      width: itemExtent * 0.9,
      height: itemExtent * 0.9,
      margin: EdgeInsets.symmetric(vertical: itemExtent * 0.05),
      child: Card(
        elevation: isSelected ? 8 : 2,
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isSelected ? Colors.yellow : Colors.white24,
            width: isSelected ? 3 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(album.albumArt, fit: BoxFit.cover, gaplessPlayback: true),
            if (album.releaseNumber == 105)
              const Positioned(
                bottom: 8,
                right: 8,
                child: Icon(Icons.album, color: Colors.green, size: 24),
              ),
            if (settings.displayAlbumReleaseNumber)
              Align(
                alignment: Alignment.bottomLeft,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 56),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black, Colors.transparent],
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${album.releaseNumber}. ${formatAlbumName(album.name)}',
                        style: TextStyle(
                          color: isSelected ? Colors.yellow : Colors.white,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 18,
                          shadows: const [Shadow(color: Colors.black, blurRadius: 4)],
                        ),
                      ),
                      Text(
                        extractDateFromAlbumName(album.name),
                        style: TextStyle(
                          color: isSelected ? Colors.yellow.withOpacity(0.8) : Colors.white70,
                          fontSize: 12,
                          shadows: const [Shadow(color: Colors.black, blurRadius: 2)],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
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
          _scrollToPlayingAlbum();
          Navigator.pushNamed(context, '/music_player_page');
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const Icon(
          Icons.play_circle,
          color: Colors.yellow,
          shadows: [Shadow(color: Colors.redAccent, blurRadius: 4)],
          size: 50,
        ),
      );
    }

    return null;
  }
}