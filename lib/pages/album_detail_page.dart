import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:matrix/models/track.dart';
import 'package:matrix/utils/duration_formatter.dart';
import 'package:provider/provider.dart';
import 'package:matrix/providers/track_player_provider.dart';

class AlbumDetailPage extends StatelessWidget {
  final List<Track> tracks;
  final String albumArt;
  final String albumName;

  const AlbumDetailPage({
    super.key,
    required this.tracks,
    required this.albumArt,
    required this.albumName,
  });

  @override
  Widget build(BuildContext context) {
    final isCapitolTheatre = albumName == '1982-04-10 - Capitol Theatre';
    return Scaffold(
      body: Stack(
        children: [
          // Blurred background
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(albumArt),
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
          // Content

          SafeArea(
            top: true,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverAppBar(
                  elevation: 0,
                  expandedHeight: 360.0,
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.transparent,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16.0),
                            child: Image.asset(
                              albumArt,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 2.0, right:20.0),
                            child: Icon(Icons.album,
                            color: isCapitolTheatre ? Colors.green : Colors.transparent,  
                            size: 30),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(16.0),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const Gap(1),
                      ..._buildTrackList(context, tracks),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTrackList(BuildContext context, List<Track> tracks) {
    final trackPlayerProvider = Provider.of<TrackPlayerProvider>(context);
    final currentAlbumTitle = trackPlayerProvider.currentAlbumTitle;
      Color shadowColor = Colors.redAccent;

    return tracks.asMap().entries.map((entry) {
      final index = entry.key;
      final track = entry.value;
      final isCurrentlyPlaying = trackPlayerProvider.currentIndex == index;

      return ListTile(
        onTap: () {
          if (isCurrentlyPlaying && currentAlbumTitle == track.albumName) {
            Navigator.pushReplacementNamed(context, '/music_player_page');
          }
        },
        dense: true,
        leading: Text(
          (index + 1).toString(),
          style: TextStyle(
                        fontSize: 18,
                        fontWeight: isCurrentlyPlaying && currentAlbumTitle == track.albumName
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isCurrentlyPlaying && currentAlbumTitle == track.albumName
                            ? Colors.yellow
                            : Colors.white,
                        shadows: isCurrentlyPlaying && currentAlbumTitle == track.albumName
                            ? [
                                Shadow(color: shadowColor, blurRadius: 3),
                                Shadow(color: shadowColor, blurRadius: 6),
                              ]
                            : null,
                      ),
        ),
        title: Text(
          track.trackName,
          style: TextStyle(
                        fontSize: 16,
                        fontWeight: isCurrentlyPlaying && currentAlbumTitle == track.albumName
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isCurrentlyPlaying && currentAlbumTitle == track.albumName
                            ? Colors.yellow
                            : Colors.white,
                        shadows: isCurrentlyPlaying && currentAlbumTitle == track.albumName
                            ? [
                                Shadow(color: shadowColor, blurRadius: 3),
                                Shadow(color: shadowColor, blurRadius: 6),
                              ]
                            : null,
                      ),
        ),
        trailing: Text(
          formatDurationSeconds(track.trackDuration),
                style: TextStyle(
                        fontSize: 16,
                        fontWeight: isCurrentlyPlaying && currentAlbumTitle == track.albumName
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isCurrentlyPlaying && currentAlbumTitle == track.albumName
                            ? Colors.yellow
                            : Colors.white,
                        shadows: isCurrentlyPlaying && currentAlbumTitle == track.albumName
                            ? [
                                Shadow(color: shadowColor, blurRadius: 3),
                                Shadow(color: shadowColor, blurRadius: 6),
                              ]
                            : null,
                      ),
        ),
      );
    }).toList();
  }
}

