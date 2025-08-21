

// lib/utils/load_shows_data.dart

import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:matrix/models/show.dart';
import 'package:matrix/models/track.dart';
import 'package:logger/logger.dart';

final _logger = Logger();

// --- NEW HELPER FUNCTION ---
/// Determines the source creator category based on the first track's URL.
String _determineSourceCreator(Map<String, List<Track>> sources) {
  if (sources.isEmpty || sources.values.first.isEmpty) {
    return 'misc';
  }
  final firstTrackUrl = sources.values.first.first.url.toLowerCase();

  if (firstTrackUrl.contains('tobin')) return 'tobin';
  if (firstTrackUrl.contains('seamons')) return 'seamons';
  if (firstTrackUrl.contains('dusborne')) return 'dusborne';
  if (firstTrackUrl.contains('sirmick')) return 'sirmick';

  return 'misc';
}

Future<List<Show>> loadShowsData() async {
  _logger.i("Starting to load and process shows data...");
  final stopwatch = Stopwatch()..start();
  const assetPath = 'assets/archive_tracks_shnid_opt.json';

  try {
    final jsonString = await rootBundle.loadString(assetPath);
    final List<dynamic> jsonData = jsonDecode(jsonString);
    final List<Show> shows = [];

    for (final showJson in jsonData) {
      if (showJson is! Map<String, dynamic>) continue;

      final String showName = showJson['name'] ?? 'Unknown Show';
      final String artist = showJson['artist'] ?? 'Unknown Artist';
      final String date = showJson['date'] ?? 'Unknown Date';
      final String year = showJson['year'] ?? 'Unknown Year';
      final List<dynamic> sourcesJson = showJson['sources'] ?? [];

      final venueRegex = RegExp(r'Live at (.+?) on');
      final venue = venueRegex.firstMatch(showName)?.group(1) ?? 'Unknown Venue';
      final uniqueId = '$artist-$date-$venue';

      final Map<String, List<Track>> sourcesMap = {};

      for (final sourceJson in sourcesJson) {
        if (sourceJson is! Map<String, dynamic>) continue;
        final String shnid = sourceJson['id']?.toString() ?? 'unknown_shnid';
        final List<dynamic> tracksJson = sourceJson['tracks'] ?? [];
        final List<Track> sourceTracks = [];
        int trackIndex = 0;
        for (final trackJson in tracksJson) {
          if (trackJson is! Map<String, dynamic>) continue;
          final track = Track.fromJsonCompact(
            trackJson,
            albumName: showName,
            artistName: artist,
            trackIndex: trackIndex++,
            shnid: shnid,
          );
          sourceTracks.add(track);
        }
        if (sourceTracks.isNotEmpty) {
          sourcesMap[shnid] = sourceTracks;
        }
      }

      if (sourcesMap.isNotEmpty) {
        // --- CATEGORIZATION LOGIC IS APPLIED HERE ---
        final String creator = _determineSourceCreator(sourcesMap);

        final newShow = Show(
          uniqueId: uniqueId,
          name: showName,
          artist: artist,
          date: date,
          year: year,
          venue: venue,
          sources: sourcesMap,
          sourceCreator: creator, // <-- SAVE THE CATEGORY
        );
        shows.add(newShow);
      }
    }

    stopwatch.stop();
    _logger.i("Successfully loaded and processed ${shows.length} shows in ${stopwatch.elapsedMilliseconds}ms.");
    shows.sort((a, b) => b.date.compareTo(a.date));
    return shows;

  } catch (e, stacktrace) {
    _logger.e(
      "A fatal error occurred in loadShowsData while processing $assetPath",
      error: e,
      stackTrace: stacktrace,
    );
    rethrow;
  }
}