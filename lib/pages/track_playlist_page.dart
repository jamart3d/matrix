import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:myapp/pages/albums_page.dart';
import 'package:provider/provider.dart';
import 'package:myapp/pages/track_detail_page.dart';
import 'package:myapp/providers/track_player_provider.dart';
import 'package:myapp/utils/duration_formatter.dart';

class TrackPlaylistPage extends StatefulWidget {
  const TrackPlaylistPage({Key? key}) : super(key: key);

  @override
  _TrackPlaylistPageState createState() => _TrackPlaylistPageState();
}

class _TrackPlaylistPageState extends State<TrackPlaylistPage> {
  late Logger logger;

  @override
  void initState() {
    super.initState();
    logger = context.read<Logger>();
  }

  @override
  Widget build(BuildContext context) {
    final trackPlayerProvider = Provider.of<TrackPlayerProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title:
            // Text('${trackPlayerProvider.playlist.length} Tracks in ${trackPlayerProvider.currentAlbumTitle}'),
                        Text('${trackPlayerProvider.currentAlbumTitle}'),
        actions: [
          IconButton(
            icon: Icon(Icons.clear),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('Clear Playlist'),
                    content:
                        Text('Clear playlist?'),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          trackPlayerProvider.clearPlaylist();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AlbumsPage(),
                            ),
                          );
                        },
                        child: Text('Clear'),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: _buildBody(trackPlayerProvider),
    );
  }

  Widget _buildBody(TrackPlayerProvider trackPlayerProvider) {
    final currentTrack =
        trackPlayerProvider.currentlyPlayingSong; // Get the currently playing track

    return Stack(
      children: [
        // Blurred Background
        Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(
                  currentTrack?.albumArt ?? 'assets/images/t_steal.webp'),
              fit: BoxFit.cover,
            ),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
            child: Container(
              color: Colors.black.withOpacity(0.5),
            ),
          ),
        ),
        // Track List
        _buildTrackList(trackPlayerProvider),
      ],
    );
  }

  Widget _buildTrackList(TrackPlayerProvider trackPlayerProvider) {
    // final currentTrack =
    //     trackPlayerProvider.currentlyPlayingSong; // Get the currently playing track

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: trackPlayerProvider.playlist.length,
            itemBuilder: (context, index) {
              final track = trackPlayerProvider.playlist[index];
              final isCurrentlyPlayingTrack =
                  index == trackPlayerProvider.currentIndex;

              return GestureDetector(
                onTap: () {
                      Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      TrackDetailPage(track: track),
                                ),
                              );
             
                },
                onLongPress: () {
                        if (!isCurrentlyPlayingTrack) {
                    trackPlayerProvider.seekTo(Duration.zero, index: index);
                    trackPlayerProvider.play();
                  }
                },
                child: Card(
                  // Make the card completely transparent
                  color: Colors.transparent,
                  elevation: 0,
                  child: ListTile(
                  
                    title: Text(
                      track.trackName,
                      style: TextStyle(
                          color: isCurrentlyPlayingTrack
                              ? Colors.yellow
                              : Colors.white,
                          fontWeight: FontWeight.bold),
                    ),
                    
                    trailing: Text(
                      formatDurationSeconds(track.trackDuration),
                      style: TextStyle(
                        color: isCurrentlyPlayingTrack
                            ? Colors.yellow
                            : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}