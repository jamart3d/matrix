import 'dart:math';

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

class AlbumsPage extends StatefulWidget {
  const AlbumsPage({super.key});

  @override
  _AlbumsPageState createState() => _AlbumsPageState();
}

class _AlbumsPageState extends State<AlbumsPage> {
  late Logger logger;
  List<Map<String, dynamic>>? _cachedAlbumData;

  @override
  void initState() {
    super.initState();
    logger = context.read<Logger>();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      if (_cachedAlbumData == null) {
        final tracks = await loadJsonData(context);
        logger.d("LOADED HOMEPAGE JSON: ${tracks.length}");
        final albumTracks = groupTracksByAlbum(tracks);
        setState(() {
          _cachedAlbumData = _createAlbumDataList(albumTracks);
        });
      }
    } catch (e) {
      logger.e("Error loading data: $e");
    }
  }

  List<Map<String, dynamic>> _createAlbumDataList(
      Map<String, List<Track>> albumTracks) {
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
              'artistName': entry.value.first.artistName ??
                  entry.value.first.trackArtistName,
              'albumArt': entry.value.first.albumArt,
            })
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Hunters Trix"),
        actions: _buildAppBarActions(context),
      ),
      drawer: const MyDrawer(),
      body: _buildBody(),
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
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please wait for albums to load')));
    }
  }

  Widget _buildBody() {
    if (_cachedAlbumData == null) {
      return const Center(child: CircularProgressIndicator());
    } else if (_cachedAlbumData!.isEmpty) {
      return const Center(child: Text("No albums available."));
    } else {
      return _buildAlbumList();
    }
  }

  Widget _buildAlbumList() {
    return ListView.builder(
      itemCount: _cachedAlbumData?.length ?? 0,
      itemBuilder: (context, index) {
        final albumData = _cachedAlbumData![index];
        final albumName = albumData['album'] as String;
        final albumArt = albumData['albumArt'] as String;

        return ListTile(
          leading: Image.asset(
            albumArt,
            // width: 50,
            // height: 50,
            fit: BoxFit.cover,
          ),
          title: Text(
            albumName,
            softWrap: true,
            overflow: TextOverflow.ellipsis,
          ),
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
        );
      },
    );
  }

  void _handleAlbumTap(Map<String, dynamic> albumData) {
    final trackPlayerProvider =
        Provider.of<TrackPlayerProvider>(context, listen: false);
    final albumTracks = albumData['songs'] as List<Track>;

    trackPlayerProvider.clearPlaylist();
    trackPlayerProvider.addAllToPlaylist(albumTracks);
    trackPlayerProvider.play();

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MusicPlayerPage()),
    );
  }

  Future<void> _selectRandomAlbum(
    BuildContext context,
    List<Map<String, dynamic>> albumDataList,
    Logger logger,
  ) async {
    if (albumDataList.isNotEmpty) {
      final trackPlayerProvider =
          Provider.of<TrackPlayerProvider>(context, listen: false);

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
    } else {
      logger.w('No albums available in albumDataList.');
    }
  }
}
