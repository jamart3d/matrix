import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:huntrix/models/show.dart';
import 'package:huntrix/models/track.dart';
import 'package:huntrix/utils/album_utils.dart'; // Still needed for assignAlbumArtToTracks

/// **REFACTORED**
/// Loads data from the new 'data_opt.json', parses it into Show objects,
/// and then transforms that data into the Map structure required by the AlbumsPage.
Future<void> loadData(BuildContext context, Function(List<Map<String, dynamic>>?) callback) async {
  try {
    // 1. Load the raw JSON string from the new file.
    final jsonString = await DefaultAssetBundle.of(context).loadString('assets/data_opt.json');
    final List<dynamic> jsonData = jsonDecode(jsonString);

    // 2. Parse the JSON into a list of strongly-typed Show objects.
    // This uses the updated Show.fromJson and Track.fromJson constructors.
    final List<Show> shows = jsonData.map((item) => Show.fromJson(item)).toList();
    
    // 3. Transform the List<Show> into the List<Map<String, dynamic>> that the UI expects.
    final albumDataList = _createAlbumDataListFromShows(shows);
    
    callback(albumDataList);
  } catch (e) {
    debugPrint("Error loading or processing data_opt.json: $e");
    if (context.mounted) _showErrorSnackBar(context, 'Error loading data: $e');
    callback(null); // Ensure callback is always called
  }
}

/// **REFACTORED**
/// Transforms a list of Show objects into the data structure needed by the AlbumsPage.
List<Map<String, dynamic>> _createAlbumDataListFromShows(List<Show> shows) {
  // We still need to create a map of tracks to assign album art correctly.
  // The key is the album name (show.name) and the value is the list of tracks.
  final Map<String, List<Track>> albumTracks = {
    for (var show in shows) show.name: show.tracks
  };

  // The album art assignment logic can now be simplified as it's part of the show-to-album transformation.
  final Map<String, int> albumIndex = {};
  int index = 1;
  for (final albumName in albumTracks.keys) {
    albumIndex[albumName] = index++;
  }
  assignAlbumArtToTracks(albumTracks, albumIndex);

  // Now, map the shows to the final list structure.
  return shows.map((show) {
    // We get the (now art-populated) tracks for the current show.
    final tracksWithArt = albumTracks[show.name] ?? [];
    
    return {
      'album': show.name,
      'songs': tracksWithArt,
      'songCount': tracksWithArt.length,
      'artistName': show.artist,
      // Get the album art from the first track after it has been assigned.
      'albumArt': tracksWithArt.isNotEmpty ? tracksWithArt.first.albumArt : 'assets/images/t_steal.webp',
      'releaseNumber': albumIndex[show.name],
      'releaseDate': show.name, // The show name is the date in the new format.
    };
  }).toList();
}

// Helper function to show an error snackbar
void _showErrorSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 5),
      backgroundColor: Colors.red,
    ),
  );
}

// The old functions below are no longer needed with the new data structure.
// You can safely delete them.

/*
Future<List<Track>> loadJsonData(BuildContext context) async {
  // ... this logic is now inside loadData()
}

List<Map<String, dynamic>> _createAlbumDataList(Map<String, List<Track>> albumTracks) {
  // ... this is replaced by _createAlbumDataListFromShows()
}

List<Map<String, dynamic>> _insertAlbumsWithout19Prefix(List<Map<String, dynamic>> albumDataList) {
  // ... this is no longer needed as the new format is consistent
}
*/