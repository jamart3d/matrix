// lib/utils/load_json_data.dart

import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:matrix/models/album.dart';
import 'package:matrix/models/track.dart';
import 'package:logger/logger.dart';

final _logger = Logger();

// This helper is now private to this file since it's only used here.
String _generateAlbumArt(int albumIndex) {
  const pathPrefix = 'assets/images/trix_album_art/trix';
  const extension = '.webp';
  return '$pathPrefix${albumIndex.toString().padLeft(2, '0')}$extension';
}

/// Loads and parses album data from the 'data_opt.json' asset.
///
/// This function is fully self-contained, has no UI dependencies, and returns
/// a Future with a type-safe list of [Album] objects.
Future<List<Album>> loadAlbums() async {
  const assetPath = 'assets/data_opt.json';
  _logger.i("Loading and parsing albums from $assetPath...");
  final stopwatch = Stopwatch()..start();

  try {
    final jsonString = await rootBundle.loadString(assetPath);
    final List<dynamic> jsonData = jsonDecode(jsonString);

    final List<Album> finalAlbums = [];
    int releaseCounter = 1;

    for (final albumJson in jsonData) {
      if (albumJson is! Map<String, dynamic>) continue;

      final String albumName = albumJson['name'] ?? 'Unknown Album';
      final String artistName = albumJson['artist'] ?? 'Unknown Artist';
      final String albumDate = albumJson['date'] ?? 'Unknown Date';
      final List<dynamic> tracksJson = albumJson['tracks'] as List? ?? [];

      // Determine the final album art path for this album upfront.
      final String albumArtPath = _generateAlbumArt(releaseCounter);

      if (tracksJson.isNotEmpty) {
        // Create final track objects with the correct art path already included.
        final List<Track> parsedTracks = tracksJson.map((trackJson) {
          final initialTrack = Track.fromAlbumOptJson(
            json: trackJson,
            albumName: albumName,
            artistName: artistName,
            albumReleaseNumber: releaseCounter,
            albumReleaseDate: albumDate,
          );
          // Return a new, immutable copy with the album art correctly set.
          return initialTrack.copyWith(albumArt: () => albumArtPath);
        }).toList();

        // Create the final Album object.
        finalAlbums.add(Album(
          name: albumName,
          artist: artistName,
          tracks: parsedTracks,
          releaseNumber: releaseCounter,
          releaseDate: albumDate,
          albumArt: albumArtPath,
        ));
      }
      releaseCounter++;
    }

    stopwatch.stop();
    _logger.i("Successfully loaded ${finalAlbums.length} albums in ${stopwatch.elapsed}ms.");

    return finalAlbums;

  } catch (e, stacktrace) {
    _logger.e("Fatal error loading or processing $assetPath", error: e, stackTrace: stacktrace);
    rethrow;
  }
}