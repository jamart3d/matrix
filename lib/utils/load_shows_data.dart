// lib/utils/load_shows_data.dart

import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:matrix/models/show.dart';
import 'package:matrix/models/track.dart';
import 'package:logger/logger.dart';

// Global logger instance for this utility file.
final _logger = Logger();

/// Loads, parses, and formats show data from the application's assets.
///
/// This function is completely decoupled from the Flutter UI. It reads and
/// parses the 'assets/archive_tracks_shnid_opt.json' file.
/// On failure, it logs the error and re-throws the exception to be handled
/// by the caller (e.g., a FutureBuilder).
Future<List<Show>> loadShowsData() async {
  _logger.i("Starting to load and process shows data...");
  final stopwatch = Stopwatch()..start();
  const assetPath = 'assets/archive_tracks_shnid_opt.json';

  try {
    // 1. Load the JSON string from assets using rootBundle (no context needed).
    final jsonString = await rootBundle.loadString(assetPath);

    // 2. Decode the JSON string. The root is expected to be a List.
    final List<dynamic> jsonData = jsonDecode(jsonString);

    final List<Show> shows = [];

    // 3. Iterate over each show object in the JSON list.
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

      final Map<String, List<Track>> sourcesMap = {};

      // 4. Iterate over the sources within the current show.
      for (final sourceJson in sourcesJson) {
        if (sourceJson is! Map<String, dynamic>) continue;

        final String shnid = sourceJson['id']?.toString() ?? 'unknown_shnid';
        final List<dynamic> tracksJson = sourceJson['tracks'] ?? [];
        final List<Track> sourceTracks = [];
        int trackIndex = 0;

        // 5. Iterate over the tracks within the current source.
        for (final trackJson in tracksJson) {
          if (trackJson is! Map<String, dynamic>) continue;

          final track = Track.fromJsonCompact(
            trackJson,
            albumName: showName,
            artistName: artist,
            trackIndex: trackIndex++,
            shnid: shnid, // Associate the track with its source ID.
          );
          sourceTracks.add(track);
        }

        if (sourceTracks.isNotEmpty) {
          sourcesMap[shnid] = sourceTracks;
        }
      }

      // 6. If the show has any valid sources, create the Show object.
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

    stopwatch.stop();
    _logger.i("Successfully loaded and processed ${shows.length} shows in ${stopwatch.elapsedMilliseconds}ms.");

    // The initial sort can be handled by the widget if needed, but doing it here provides a consistent default.
    shows.sort((a, b) => b.date.compareTo(a.date));

    return shows;

  } catch (e, stacktrace) {
    _logger.e(
      "A fatal error occurred in loadShowsData while processing $assetPath",
      error: e,
      stackTrace: stacktrace,
    );
    // Re-throw the exception to allow the caller (FutureBuilder) to handle it.
    rethrow;
  }
}