// lib/models/album.dart

import 'package:flutter/foundation.dart';
import 'package:matrix/models/track.dart';

@immutable
class Album {
  final String name;
  final String artist;
  final String releaseDate;
  final int releaseNumber;
  final String albumArt;
  final List<Track> tracks;

  const Album({
    required this.name,
    required this.artist,
    required this.releaseDate,
    required this.releaseNumber,
    required this.albumArt,
    required this.tracks,
  });

  // Helper getter for the UI
  int get songCount => tracks.length;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Album &&
              runtimeType == other.runtimeType &&
              name == other.name &&
              releaseNumber == other.releaseNumber;

  @override
  int get hashCode => name.hashCode ^ releaseNumber.hashCode;
}