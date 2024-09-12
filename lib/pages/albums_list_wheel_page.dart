import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:huntrix/components/my_drawer.dart';
import 'package:huntrix/helpers/album_helper.dart';
import 'package:huntrix/models/track.dart';
import 'package:huntrix/pages/album_detail_page.dart';
import 'package:huntrix/pages/music_player_page.dart';
import 'package:huntrix/providers/track_player_provider.dart';
import 'package:provider/provider.dart';
import 'package:huntrix/utils/load_json_data.dart';
import 'package:logger/logger.dart';

class AlbumListWheelPage extends StatefulWidget {
  const AlbumListWheelPage({super.key});

  @override
  State<AlbumListWheelPage> createState() => _AlbumListWheelPageState();
}

class _AlbumListWheelPageState extends State<AlbumListWheelPage> {
  late Logger logger;
  List<Map<String, dynamic>>? _cachedAlbumData;
  String? _currentAlbumArt; // To store current album art
  String? _currentAlbumName; // To store the name of the currently playing album

  @override
  void initState() {
    super.initState();
    _currentAlbumArt = 'assets/images/t_steal.webp'; // Default album art
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    logger = context.read<Logger>();

    // Restore the current album art and name from TrackPlayerProvider
    final trackPlayerProvider = Provider.of<TrackPlayerProvider>(context, listen: false);
    final currentlyPlayingSong = trackPlayerProvider.currentlyPlayingSong;

    if (currentlyPlayingSong != null) {
      _currentAlbumArt = currentlyPlayingSong.albumArt;
      _currentAlbumName = currentlyPlayingSong.albumName;
    }

    _loadData(); // Load album data
  }

  Future<void> _loadData() async {
    try {
      if (_cachedAlbumData == null) {
        final tracks = await loadJsonData(context);
        logger.d("LOADED Wheel JSON: ${tracks.length}");
        final albumTracks = groupTracksByAlbum(tracks);
        setState(() {
          _cachedAlbumData = _createAlbumDataList(albumTracks);
        });
      }
    } catch (e) {
      logger.e("Error loading data: $e");
    }
  }

  List<Map<String, dynamic>> _createAlbumDataList(Map<String, List<Track>> albumTracks) {
    final Map<String, int> albumIndex = {};
    int index = 1;
    for (final albumName in albumTracks.keys) {
      albumIndex[albumName] = index++;
    }
    assignAlbumArtToTracks(albumTracks, albumIndex);

    return albumTracks.entries
        .map((entry) => {
              'album': entry.key,
              'songs': entry.value,
              'songCount': entry.value.length,
              'artistName': entry.value.first.artistName ?? entry.value.first.trackArtistName,
              'albumArt': entry.value.first.albumArt,
            })
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Album Wheel"),
        actions: _buildAppBarActions(context),
      ),
      drawer: const MyDrawer(),
      body: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          image: DecorationImage(
            image: AssetImage(_currentAlbumArt ?? 'assets/images/t_steal.webp'),
            fit: BoxFit.cover,
            colorFilter: _currentAlbumArt != null
                ? null
                : ColorFilter.mode(Colors.black.withOpacity(0.3), BlendMode.darken),
          ),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // Blur effect
          child: Stack(
            children: [
              // Album list wheel
              _buildBody(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MusicPlayerPage()),
          );
        },
        child: const Icon(Icons.play_circle),
      ),
    );
  }

  List<Widget> _buildAppBarActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.question_mark),
        onPressed: () => _handleRandomAlbumSelection(context),
      ),
    ];
  }

  void _handleRandomAlbumSelection(BuildContext context) {
    if (_cachedAlbumData != null) {
      _selectRandomAlbum(context, _cachedAlbumData!, logger);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please wait for albums to load')));
    }
  }

  Widget _buildBody() {
    if (_cachedAlbumData == null) {
      return const Center(child: CircularProgressIndicator());
    } else if (_cachedAlbumData!.isEmpty) {
      return const Center(child: Text("No albums available."));
    } else {
      return _buildAlbumWheel();
    }
  }

  Widget _buildAlbumWheel() {
    const int infiniteScrollMultiplier = 1000; // Number of times to repeat the album list

    return ListWheelScrollView.useDelegate(
      itemExtent: 250, // Height of each item
      diameterRatio: 3.0, // Curve of the wheel
      physics: const FixedExtentScrollPhysics(), // Snapping effect
      onSelectedItemChanged: (index) {
        // Use modulo to wrap around the list
        // final actualIndex = index % _cachedAlbumData!.length;
        // final albumData = _cachedAlbumData![actualIndex];

        // setState(() {
        //   _currentAlbumArt = albumData['albumArt'] as String;
        //   _currentAlbumName = albumData['album'] as String;
        // });
      },
      childDelegate: ListWheelChildBuilderDelegate(
        builder: (context, index) {
          if (_cachedAlbumData == null || _cachedAlbumData!.isEmpty) {
            return null; // Guard clause for empty data
          }

          // Modulo operation to simulate infinite looping
          final actualIndex = index % _cachedAlbumData!.length;
          final albumData = _cachedAlbumData![actualIndex];
          final albumName = albumData['album'] as String;
          final albumArt = albumData['albumArt'] as String;

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AlbumDetailPage(
                    tracks: albumData['songs'] as List<Track>,
                    albumArt: albumArt,
                    albumName: albumName,
                  ),
                ),
              );
            },
            onLongPress: () => _handleAlbumTap(albumData),
            child: Card(
              elevation: 22,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: _currentAlbumName == albumName ? Colors.yellow : Colors.black,
                  width: 2,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                albumArt,
                fit: BoxFit.fitWidth,
              ),
            ),
          );
        },
        childCount: _cachedAlbumData == null ? 0 : _cachedAlbumData!.length * infiniteScrollMultiplier,
      ),
    );
  }

  void _handleAlbumTap(Map<String, dynamic> albumData) {
    final trackPlayerProvider = Provider.of<TrackPlayerProvider>(context, listen: false);
    final albumTracks = albumData['songs'] as List<Track>;

    trackPlayerProvider.clearPlaylist();
    trackPlayerProvider.addAllToPlaylist(albumTracks);
    trackPlayerProvider.play();

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MusicPlayerPage()),
    );

    setState(() {
      _currentAlbumArt = albumData['albumArt'] as String;
      _currentAlbumName = albumData['album'] as String;
    });
  }

  Future<void> _selectRandomAlbum(
    BuildContext context,
    List<Map<String, dynamic>> albumDataList,
    Logger logger,
  ) async {
    if (albumDataList.isNotEmpty) {
      final trackPlayerProvider = Provider.of<TrackPlayerProvider>(context, listen: false);

      final randomIndex = Random().nextInt(albumDataList.length);
      final randomAlbum = albumDataList[randomIndex];

      final albumTitle = randomAlbum['album'] as String?;

      if (albumTitle == null || albumTitle.isEmpty) {
        logger.e('Random album title is null or empty');
        return;
      }

      final randomAlbumTracks = randomAlbum['songs'] as List<Track>;

      trackPlayerProvider.clearPlaylist();
      trackPlayerProvider.addAllToPlaylist(randomAlbumTracks);

      trackPlayerProvider.play();

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MusicPlayerPage()),
      );
      logger.d('Playing random album: $albumTitle');

      setState(() {
        _currentAlbumArt = randomAlbum['albumArt'] as String;
        _currentAlbumName = randomAlbum['album'] as String;
      });
    } else {
      logger.w('No albums available in albumDataList.');
    }
  }
}
