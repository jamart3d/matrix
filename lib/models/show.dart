import 'package:huntrix/models/track.dart';

class Show {
  final String name;
  final String artist;
  final List<Track> tracks;

  Show({
    required this.name,
    required this.artist,
    required this.tracks,
  });

  factory Show.fromJson(Map<String, dynamic> json) {
    final String showName = json['name'] as String? ?? 'Unknown Show';
    final String showArtist = json['artist'] as String? ?? 'Unknown Artist';
    
    var trackList = json['tracks'] as List? ?? [];
    
    // **UPDATED:** Use asMap().entries to get both index and track data
    List<Track> parsedTracks = trackList.asMap().entries.map((entry) {
      final trackIndex = entry.key; // 0-based index from JSON order
      final trackJson = entry.value; // The actual track JSON data
      
      return Track.fromJsonCompact(
        trackJson,
        albumName: showName,
        artistName: showArtist,
        trackIndex: trackIndex, // Pass the index for proper numbering
      );
    }).toList();

    return Show(
      name: showName,
      artist: showArtist,
      tracks: parsedTracks,
    );
  }
}