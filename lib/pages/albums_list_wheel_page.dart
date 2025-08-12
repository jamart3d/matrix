import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:matrix/components/my_drawer.dart';
import 'package:matrix/helpers/album_helper.dart';
import 'package:matrix/models/track.dart';
import 'package:matrix/pages/album_detail_page.dart';
import 'package:matrix/providers/track_player_provider.dart';
import 'package:matrix/utils/album_utils.dart';
import 'package:provider/provider.dart';
import 'package:matrix/utils/load_json_data.dart';
import 'package:matrix/providers/album_settings_provider.dart';
import 'package:logger/logger.dart';

class AlbumListWheelPage extends StatefulWidget {
  const AlbumListWheelPage({super.key});

  @override
  State<AlbumListWheelPage> createState() => _AlbumListWheelPageState();
}

class _AlbumListWheelPageState extends State<AlbumListWheelPage> {
  final _logger = Logger(printer: PrettyPrinter(methodCount: 1));
  
  // State variables
  List<Map<String, dynamic>>? _cachedAlbumData;
  String _currentAlbumArt = 'assets/images/t_steal.webp';
  String? _currentAlbumName;
  bool _isDataLoading = true;

  // Controllers
  late final FixedExtentScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = FixedExtentScrollController();
    _initializePage();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializePage() async {
    await _loadAlbumData();
    _setupInitialAlbumScroll();
  }

  Future<void> _loadAlbumData() async {
    try {
      _logger.i("Loading album data for list wheel...");
      await loadData(context, (albumData) {
        if (mounted) {
          setState(() {
            _cachedAlbumData = albumData;
            _isDataLoading = false;
          });
          if (albumData != null) {
            preloadAlbumImages(albumData, context);
          }
        }
      });
    } catch (e) {
      if(mounted) {
        setState(() => _isDataLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error loading album data."), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _setupInitialAlbumScroll() {
    if (!mounted) return;
    final currentlyPlaying = context.read<TrackPlayerProvider>().currentTrack ;
    if (currentlyPlaying != null) {
      _updateCurrentAlbum(currentlyPlaying);
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrentAlbum(animate: false));
    }
  }

  void _updateCurrentAlbum(Track? currentlyPlayingSong) {
    if (currentlyPlayingSong == null) {
      // Handle player stopping
      if (_currentAlbumName != null) {
        setState(() {
          _currentAlbumName = null;
          _currentAlbumArt = 'assets/images/t_steal.webp';
        });
      }
      return;
    }
    
    final newAlbumArt = currentlyPlayingSong.albumArt ?? 'assets/images/t_steal.webp';
    final newAlbumName = currentlyPlayingSong.albumName;
    
    if (newAlbumArt != _currentAlbumArt || newAlbumName != _currentAlbumName) {
      _logger.d("Provider changed album. Updating wheel UI for: $newAlbumName");
      if(mounted) {
        setState(() {
          _currentAlbumArt = newAlbumArt;
          _currentAlbumName = newAlbumName;
        });
        _scrollToCurrentAlbum(animate: true);
      }
    }
  }

  void _scrollToCurrentAlbum({bool animate = true}) {
    if (_currentAlbumName == null || _cachedAlbumData == null || !_scrollController.hasClients) return;
    
    final index = _cachedAlbumData!.indexWhere((album) => album['album'] == _currentAlbumName);
    if (index != -1) {
      if (animate) {
        _scrollController.animateToItem(
          index,
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeInOut,
        );
      } else {
        _scrollController.jumpToItem(index);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to the provider to update the background art in real-time
    final currentlyPlaying = context.watch<TrackPlayerProvider>().currentTrack ;
    _updateCurrentAlbum(currentlyPlaying);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Hunter's Matrix"),
        centerTitle: true,
        forceMaterialTransparency: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.question_mark),
            onPressed: () {
              if (_cachedAlbumData != null) {
                playRandomAlbum(_cachedAlbumData!);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please wait for albums to load')),
                );
              }
            },
          ),
        ],
      ),
      drawer: const MyDrawer(),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(_currentAlbumArt),
            fit: BoxFit.cover,
          ),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            color: Colors.black.withOpacity(0.5),
            child: _buildBody(),
          ),
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildBody() {
    if (_isDataLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_cachedAlbumData == null || _cachedAlbumData!.isEmpty) {
      return const Center(child: Text("No albums available."));
    }
    return _buildAlbumWheel();
  }

  Widget _buildAlbumWheel() {
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
            onSelectedItemChanged: (index) => HapticFeedback.mediumImpact(),
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: _cachedAlbumData!.length,
              builder: (context, index) {
                final albumData = _cachedAlbumData![index];
                final tracks = albumData['songs'] as List<Track>;

                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AlbumDetailPage(
                        tracks: tracks,
                        albumArt: albumData['albumArt'] as String,
                        albumName: albumData['album'] as String,
                      ),
                    ),
                  ),
                  onLongPress: () {
                    playAlbumFromTracks(tracks);
                  },
                  child: _buildWheelItem(albumData, albumSettings, itemExtent),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildWheelItem(Map<String, dynamic> albumData, AlbumSettingsProvider settings, double itemExtent) {
    final albumName = albumData['album'] as String;
    final albumArt = albumData['albumArt'] as String;
    final index = _cachedAlbumData!.indexOf(albumData);
    final isSelected = _currentAlbumName == albumName;

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
            Image.asset(albumArt, fit: BoxFit.cover, gaplessPlayback: true),
            if (index == 104) // Offline album indicator
              const Positioned(
                bottom: 8,
                right: 8,
                child: Icon(Icons.album, color: Colors.green, size: 24),
              ),
            if (settings.displayAlbumReleaseNumber)
              Align(
                alignment: Alignment.bottomLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                        '${index + 1}. ${formatAlbumName(albumName)}',
                        style: TextStyle(
                          color: isSelected ? Colors.yellow : Colors.white,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 18,
                          shadows: const [Shadow(color: Colors.black, blurRadius: 4)],
                        ),
                      ),
                      Text(
                        extractDateFromAlbumName(albumName),
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

  /// **MODIFIED FAB**
  /// This FAB now shows a loading indicator when the player is buffering.
  Widget? _buildFloatingActionButton() {
    final playerProvider = context.watch<TrackPlayerProvider>();

    // Case 1: Player is actively loading or buffering a track.
    if (playerProvider.isLoading) {
      return FloatingActionButton(
        onPressed: null, // Disable press action while loading
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const SizedBox(
          width: 50,
          height: 50,
          child: CircularProgressIndicator(
            strokeWidth: 3.0,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.yellow),
          ),
        ),
      );
    }

    // Case 2: A song is loaded and ready (or playing/paused), but not loading.
    if (playerProvider.currentTrack != null) {
      return FloatingActionButton(
        onPressed: () {
          _scrollToCurrentAlbum(animate: true);
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
    
    // Case 3: No song is loaded and the player is not loading.
    return null;
  }
}