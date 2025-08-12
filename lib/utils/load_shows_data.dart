// lib/utils/load_shows_data.dart

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:matrix/models/show.dart';
import 'package:matrix/models/track.dart';
import 'package:logger/logger.dart';

final _logger = Logger();

/// Loads, parses, and formats show data from the new JSON array structure.
///
/// This function reads 'assets/archive_tracks_matrix_opt.json', which is a list of shows.
/// It processes each show and its nested sources to build a final list of `Show` objects.
Future<List<Show>> loadShowsData(BuildContext context) async {
  _logger.i("Starting to load and process shows data from new format...");
  final stopwatch = Stopwatch()..start();

  try {
    // 1. Load the JSON from the specified asset file.
    final jsonString = await DefaultAssetBundle.of(context)
        .loadString('assets/archive_tracks_shnid_opt.json');
    
    // The root of this JSON is a List.
    final List<dynamic> jsonData = jsonDecode(jsonString);

    final List<Show> shows = [];

    // 2. Iterate over each show object in the JSON list.
    for (final showJson in jsonData) {
      if (showJson is! Map<String, dynamic>) continue;

      final String showName = showJson['name'] ?? 'Unknown Show';
      final String artist = showJson['artist'] ?? 'Unknown Artist';
      final String date = showJson['date'] ?? 'Unknown Date';
      final String year = showJson['year'] ?? 'Unknown Year';
      final List<dynamic> sourcesJson = showJson['sources'] ?? [];

      // Use a regex to extract a cleaner venue name for display.
      final venueRegex = RegExp(r'Live at (.+?) on');
      final venue = venueRegex.firstMatch(showName)?.group(1) ?? 'Unknown Venue';
      final uniqueId = '$artist-$date-$venue';

      // This map will hold the sources for the current show being processed.
      final Map<String, List<Track>> sourcesMap = {};

      // 3. Iterate over the sources within the current show.
      for (final sourceJson in sourcesJson) {
        if (sourceJson is! Map<String, dynamic>) continue;

        // Use the source 'id' as the SHNID.
        final String shnid = sourceJson['id']?.toString() ?? 'unknown_shnid_${DateTime.now().millisecondsSinceEpoch}';
        final List<dynamic> tracksJson = sourceJson['tracks'] ?? [];
        
        final List<Track> sourceTracks = [];
        int trackIndex = 0;

        // 4. Iterate over the tracks within the current source.
        for (final trackJson in tracksJson) {
          if (trackJson is! Map<String, dynamic>) continue;
          
          // Use the `fromJsonCompact` factory, as the keys are abbreviated ('t', 'd', 'u').
          // We provide the necessary context (albumName, artistName, etc.).
          final track = Track.fromJsonCompact(
            trackJson,
            albumName: showName,
            artistName: artist,
            trackIndex: trackIndex++,
            shnid: shnid, // Crucially, associate the track with its source ID.
          );
          sourceTracks.add(track);
        }
        
        // Add the fully parsed list of tracks to our sources map.
        if (sourceTracks.isNotEmpty) {
          sourcesMap[shnid] = sourceTracks;
        }
      }

      // 5. If the show has any valid sources, create the Show object.
      if (sourcesMap.isNotEmpty) {
        final newShow = Show(
          uniqueId: uniqueId,
          name: showName,
          artist: artist,
          date: date,
          year: year,
          venue: venue,
          sources: sourcesMap,
        );
        shows.add(newShow);
      }
    }

    // Sort the final list of shows by date, newest first.
    shows.sort((a, b) => b.date.compareTo(a.date));

    stopwatch.stop();
    _logger.i("Successfully loaded and processed ${shows.length} shows in ${stopwatch.elapsedMilliseconds}ms.");
    return shows;

  } catch (e, stacktrace) {
    _logger.e("A fatal error occurred in loadShowsData", error: e, stackTrace: stacktrace);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Could not load show data.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
    return []; // Return an empty list on failure to prevent crashes.
  }
}