// lib/helpers/shows_helper.dart

import 'dart:math';
import 'package:matrix/models/show.dart';
import 'package:matrix/models/track.dart';
import 'package:matrix/providers/track_player_provider.dart';
import 'package:logger/logger.dart';

final _logger = Logger();


/// Plays a list of tracks from the beginning.
Future<void> playTracklist(TrackPlayerProvider provider, List<Track> tracks) async {
  if (tracks.isEmpty) {
    _logger.w("Attempted to play an empty tracklist.");
    return;
  }
  await provider.replacePlaylistAndPlay(tracks);
}

/// Plays a list of tracks starting from a specific track.
Future<void> playTracklistFrom(TrackPlayerProvider provider, List<Track> tracks, Track startTrack) async {
  if (tracks.isEmpty) {
    _logger.w("Attempted to play from an empty tracklist.");
    return;
  }
  final initialIndex = tracks.indexOf(startTrack);
  await provider.replacePlaylistAndPlay(
    tracks,
    initialIndex: initialIndex != -1 ? initialIndex : 0,
  );
}

/// Selects a random show and plays its primary tracklist.
void playRandomShow(TrackPlayerProvider provider, List<Show> shows) {
  if (shows.isEmpty) {
    _logger.w("No shows available to play randomly.");
    return;
  }
  final randomShow = shows[Random().nextInt(shows.length)];
  _logger.i("Playing random show: ${randomShow.name}");

  // Pass the provider along to the next helper.
  playTracklist(provider, randomShow.primaryTracks);
}