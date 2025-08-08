// lib/utils/load_json_data.dart

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:huntrix/models/track.dart';
import 'package:huntrix/utils/album_utils.dart';

Future<void> loadData(BuildContext context,
    Function(List<Map<String, dynamic>>?) callback) async {
  try {
    final jsonString =
        await DefaultAssetBundle.of(context).loadString('assets/data_opt.json');
    final List<dynamic> jsonData = jsonDecode(jsonString);

    final List<Map<String, dynamic>> albumDataList = [];
    final Map<String, List<Track>> albumTracksMapForArt = {};
    int releaseCounter = 1;

    for (final albumJson in jsonData) {
      if (albumJson is Map<String, dynamic>) {
        final String albumName = albumJson['name'] ?? 'Unknown Album';
        final String artistName = albumJson['artist'] ?? 'Unknown Artist';
        final String albumDate = albumJson['date'] ?? 'Unknown Date';
        final List<dynamic> tracksJson = albumJson['tracks'] ?? [];
        
        // Use the new, dedicated factory to parse tracks correctly
        final List<Track> parsedTracks = tracksJson.map((trackJson) {
          return Track.fromAlbumOptJson(
            json: trackJson,
            albumName: albumName,
            artistName: artistName,
            albumReleaseNumber: releaseCounter,
            albumReleaseDate: albumDate,
          );
        }).toList();

        if (parsedTracks.isNotEmpty) {
          albumTracksMapForArt[albumName] = parsedTracks;

          albumDataList.add({
            'album': albumName,
            'songs': parsedTracks,
            'songCount': parsedTracks.length,
            'artistName': artistName,
            'albumArt': 'assets/images/t_steal.webp',
            'releaseNumber': releaseCounter,
            'releaseDate': albumDate,
          });
        }
        releaseCounter++;
      }
    }

    final Map<String, int> albumIndexMap = {
      for (var album in albumDataList) album['album']: album['releaseNumber']
    };
    assignAlbumArtToTracks(albumTracksMapForArt, albumIndexMap);

    for (var album in albumDataList) {
      final tracks = album['songs'] as List<Track>;
      if (tracks.isNotEmpty) {
        album['albumArt'] = tracks.first.albumArt ?? 'assets/images/t_steal.webp';
      }
    }
    
    callback(albumDataList);

  } catch (e, stacktrace) {
    debugPrint("Fatal error loading or processing data_opt.json: $e");
    debugPrintStack(stackTrace: stacktrace);
    if (context.mounted) _showErrorSnackBar(context, 'Error loading album data.');
    callback(null);
  }
}

void _showErrorSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 5),
      backgroundColor: Colors.red,
    ),
  );
}