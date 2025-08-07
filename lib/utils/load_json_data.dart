// lib/utils/load_json_data.dart

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:huntrix/models/track.dart';
import 'package:huntrix/utils/album_utils.dart';

/// Correctly loads and parses `data_opt.json` which uses a compact key format.
Future<void> loadData(BuildContext context,
    Function(List<Map<String, dynamic>>?) callback) async {
  try {
    // 1. Load the raw JSON string from the asset.
    final jsonString =
        await DefaultAssetBundle.of(context).loadString('assets/data_opt.json');
    final List<dynamic> jsonData = jsonDecode(jsonString);

    // This list will hold the final, UI-ready data.
    final List<Map<String, dynamic>> albumDataList = [];
    // This map is used temporarily to make album art assignment easy.
    final Map<String, List<Track>> albumTracksMapForArt = {};

    int releaseCounter = 1;

    // 2. Iterate over each album object in the JSON array.
    for (final albumJson in jsonData) {
      if (albumJson is Map<String, dynamic>) {
        final String albumName = albumJson['name'] ?? 'Unknown Album';
        final String artistName = albumJson['artist'] ?? 'Unknown Artist';
        final List<dynamic> tracksJson = albumJson['tracks'] ?? [];
        
        List<Track> parsedTracks = [];
        
        // 3. Iterate over the tracks within the current album.
        for (final compactTrackJson in tracksJson) {
          if (compactTrackJson is Map<String, dynamic>) {
            
            // *** THE FIX IS HERE ***
            // We create a new Track object by manually mapping the compact keys ('t', 'd', 'u')
            // to the full property names that the Track model expects.
            final track = Track(
              albumName: albumName,
              artistName: artistName,
              trackArtistName: artistName,
              trackName: compactTrackJson['t'] as String? ?? 'Unknown Track',
              trackDuration: (compactTrackJson['d'] as num? ?? 0).toInt(),
              trackNumber: (compactTrackJson['n'] as num? ?? 0).toString(),
              url: compactTrackJson['u'] as String? ?? '',
            );
            parsedTracks.add(track);
          }
        }
        
        // Store tracks for later art assignment.
        albumTracksMapForArt[albumName] = parsedTracks;

        // 4. Build the album map structure that the UI pages expect.
        albumDataList.add({
          'album': albumName,
          'songs': parsedTracks,
          'songCount': parsedTracks.length,
          'artistName': artistName,
          'albumArt': 'assets/images/t_steal.webp', // Placeholder art
          'releaseNumber': releaseCounter++,
          'releaseDate': albumName, 
        });
      }
    }

    // 5. Assign the correct album art to each track.
    final Map<String, int> albumIndexMap = {
      for (var album in albumDataList) album['album']: album['releaseNumber']
    };
    assignAlbumArtToTracks(albumTracksMapForArt, albumIndexMap);

    // 6. Update the 'albumArt' in the main list with the newly assigned art.
    for (var album in albumDataList) {
      final tracks = album['songs'] as List<Track>;
      if (tracks.isNotEmpty) {
        album['albumArt'] = tracks.first.albumArt ?? 'assets/images/t_steal.webp';
      }
    }
    
    // Sort albums by their release number to ensure consistent order.
    albumDataList.sort((a, b) => (a['releaseNumber'] as int).compareTo(b['releaseNumber'] as int));

    callback(albumDataList);

  } catch (e, stacktrace) {
    debugPrint("Error loading or processing data_opt.json: $e");
    debugPrintStack(stackTrace: stacktrace);
    if (context.mounted) _showErrorSnackBar(context, 'Error loading album data.');
    callback(null);
  }
}

// Helper to show an error message.
void _showErrorSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 5),
      backgroundColor: Colors.red,
    ),
  );
}