// lib/models/show.dart

import 'package:flutter/foundation.dart';
import 'package:matrix/models/track.dart';

@immutable // Enforce immutability for the class
class Show {
  // Properties defining the conceptual show.
  final String uniqueId; // e.g., "Grateful Dead-1977-05-08"
  final String name;     // The full album name from the first source
  final String artist;
  final String date;
  final String year;
  final String venue;

  // A map of sources. Key is the shnid (String), value is the list of tracks for that source.
  final Map<String, List<Track>> sources;

  const Show({ // Make constructor const
    required this.uniqueId,
    required this.name,
    required this.artist,
    required this.date,
    required this.year,
    required this.venue,
    required this.sources,
  });

  /// Creates a Show instance from a JSON object.
  /// This is used for pre-structured data sources like 'data_opt.json'.
  /// It assumes the JSON represents a show with a single source/shnid.
  factory Show.fromJson(Map<String, dynamic> json) {
    // 1. Parse all the simple properties, providing default values for safety.
    final showName = json['name'] as String? ?? 'Unknown Show';
    final showArtist = json['artist'] as String? ?? 'Unknown Artist';
    final showDate = json['date'] as String? ?? 'Unknown Date';
    final showYear = json['year'] as String? ?? 'Unknown Year';
    final shnid = json['shnid'] as String? ?? '0';
    final tracksJson = json['tracks'] as List? ?? [];

    // 2. Map track JSON to Track objects.
    // --- IMPROVEMENT: Pass `shnid` directly to the constructor ---
    final List<Track> parsedTracks = tracksJson.map((trackJson) {
      return Track.fromJson(trackJson as Map<String, dynamic>, shnid: shnid);
    }).toList();

    // 3. Derive the venue and uniqueId for consistency with the other data loader.
    final venueRegex = RegExp(r'Live at (.+?) on');
    final venue = venueRegex.firstMatch(showName)?.group(1) ?? 'Unknown Venue';
    final uniqueId = '$showArtist-$showDate-$venue';

    // 4. Return a new Show instance.
    // The 'sources' map is created with a single entry for this shnid.
    return Show(
      uniqueId: uniqueId,
      name: showName,
      artist: showArtist,
      date: showDate,
      year: showYear,
      venue: venue,
      sources: {
        shnid: parsedTracks,
      },
    );
  }

  // --- Helper Getters (Unchanged) ---

  bool get hasSources => sources.isNotEmpty;
  int get sourceCount => sources.length;
  List<Track> get primaryTracks => sources.values.firstOrNull ?? [];
  String get displayName => '$venue - $date';

  @override
  String toString() {
    return 'Show(name: $displayName, artist: $artist, sources: ${sources.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Show && other.uniqueId == uniqueId;
  }

  @override
  int get hashCode => uniqueId.hashCode;
}