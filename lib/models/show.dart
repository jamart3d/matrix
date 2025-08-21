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

  // The new property to store the determined category.
  final String sourceCreator;

  const Show({ // Make constructor const
    required this.uniqueId,
    required this.name,
    required this.artist,
    required this.date,
    required this.year,
    required this.venue,
    required this.sources,
    required this.sourceCreator, // Added to the constructor
  });

  // The 'fromJson' factory was removed from this model because the creation logic,
  // including the new categorization, is now handled more robustly in the
  // `load_shows_data.dart` utility. This keeps the model clean and focused on data structure.

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