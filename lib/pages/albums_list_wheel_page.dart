// lib/pages/albums_list_wheel_page.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:matrix/components/animated_playing_fab.dart';
import 'package:matrix/components/my_drawer.dart';
import 'package:matrix/helpers/album_helper.dart';
import 'package:matrix/models/album.dart';
import 'package:matrix/pages/album_detail_page.dart';
import 'package:matrix/providers/album_settings_provider.dart';
import 'package:matrix/providers/track_player_provider.dart';
import 'package:matrix/services/album_data_service.dart';
import 'package:provider/provider.dart';
import 'package:matrix/providers/enums.dart';
import 'package:matrix/routes.dart';

class AlbumListWheelPage extends StatefulWidget {
  const AlbumListWheelPage({super.key});

  @override
  State<AlbumListWheelPage> createState() => _AlbumListWheelPageState();
}

class _AlbumListWheelPageState extends State<AlbumListWheelPage> {
  late final Future<void> _initializationFuture;
  late final FixedExtentScrollController _scrollController;
  late final TrackPlayerProvider _playerProvider;
  String? _previousAlbumName;

  @override
  void initState() {
    super.initState();
    _scrollController = FixedExtentScrollController();
    _playerProvider = context.read<TrackPlayerProvider>();
    _playerProvider.addListener(_onPlayerChange);
    _initializationFuture = _initializeApp();
  }

  // Combine initialization and data loading
  Future<void> _initializeApp() async {
    await AlbumDataService().init();
    // After data is loaded, set up the initial scroll position
    _setupInitialScrollPosition();
  }

  @override
  void dispose() {
    _playerProvider.removeListener(_onPlayerChange);
    _scrollController.dispose();
    super.dispose();
  }

  // The listener's ONLY job now is to handle the side-effect of scrolling.
  // It no longer calls setState.
  void _onPlayerChange() {
    final currentAlbumName = _playerProvider.currentTrack?.albumName;
    if (currentAlbumName != null && currentAlbumName != _previousAlbumName) {
      _scrollToPlayingAlbum(currentAlbumName);
      _previousAlbumName = currentAlbumName;
    }
  }

  // This method now only runs once after the initial data load.
  void _setupInitialScrollPosition() {
    final currentlyPlaying = _playerProvider.currentTrack;
    if (!mounted || currentlyPlaying == null) return;

    final albums = AlbumDataService().albums;
    if (albums.isEmpty) return;

    final album = albums.cast<Album?>().firstWhere((a) => a?.name == currentlyPlaying.albumName, orElse: () => null);
    if (album != null) {
      final initialIndex = albums.indexOf(album);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpToItem(initialIndex);
        }
      });
    }
  }

  void _scrollToPlayingAlbum(String albumName) {
    if (!_scrollController.hasClients) return;

    final albums = AlbumDataService().albums;
    final index = albums.indexWhere((album) => album.name == albumName);

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
    // Watch the provider here. This will cause the page to rebuild when the player state changes.
    final playerProvider = context.watch<TrackPlayerProvider>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      drawer: const MyDrawer(),
      body: FutureBuilder<void>(
        future: _initializationFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final albums = AlbumDataService().albums;
          if (albums.isEmpty) {
            return const Center(child: Text("No albums available."));
          }

          // --- STATE IS NOW DERIVED DIRECTLY FROM THE PROVIDER ---
          final highlightedAlbumName = playerProvider.currentTrack?.albumName;
          final currentAlbumArt = playerProvider.currentAlbumArt; // Use the provider's art

          return Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(currentAlbumArt),
                fit: BoxFit.cover,
              ),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                color: Colors.black.withOpacity(0.5),
                child: _buildAlbumWheel(albums, highlightedAlbumName),
              ),
            ),
          );
        },
      ),
      floatingActionButton: _buildFloatingActionButton(playerProvider),
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

  Widget _buildAlbumWheel(List<Album> albums, String? highlightedAlbumName) {
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
                  child: _buildWheelItem(album, albumSettings, itemExtent, highlightedAlbumName),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildWheelItem(Album album, AlbumSettingsProvider settings, double itemExtent, String? highlightedAlbumName) {
    final isSelected = highlightedAlbumName == album.name;
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

  Widget? _buildFloatingActionButton(TrackPlayerProvider playerProvider) {
    final settingsProvider = context.watch<AlbumSettingsProvider>();
    final isLarge = settingsProvider.fabSize == FabSize.large;
    final double fabSize = isLarge ? 70.0 : 56.0;
    const String fabHeroTag = 'albums_wheel_fab_hero';

    return AnimatedPlayingFab(
      heroTag: fabHeroTag,
      isLoading: playerProvider.isLoading,
      isPlaying: playerProvider.isPlaying,
      hasTrack: playerProvider.currentTrack != null,
      themeColor: Colors.yellow,
      shadowColor: Colors.redAccent,
      size: fabSize,
      onPressed: () {
        _scrollToPlayingAlbum(playerProvider.currentTrack!.albumName);
        Navigator.pushNamed(
          context,
          Routes.musicPlayerPage,
          arguments: fabHeroTag,
        );
      },
      onLongPress: () => context.read<TrackPlayerProvider>().clearPlaylist(),
    );
  }
}