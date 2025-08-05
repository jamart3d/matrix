import 'dart:math';
import 'package:flutter/material.dart';
import 'package:huntrix/models/show.dart';
import 'package:huntrix/models/track.dart';
import 'package:huntrix/providers/track_player_provider.dart';
import 'package:huntrix/services/navigation_service.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';

// A single logger instance for the entire file.
final _logger = Logger();

/// Safely gets the track player provider from the widget tree.
TrackPlayerProvider? _getTrackPlayerProvider() {
  final context = NavigationService().navigatorKey.currentContext;
  if (context == null || !context.mounted) {
    _logger.e("Cannot get TrackPlayerProvider: context is not available");
    return null;
  }
  
  try {
    return Provider.of<TrackPlayerProvider>(context, listen: false);
  } catch (e) {
    _logger.e("Error getting TrackPlayerProvider: $e");
    return null;
  }
}

/// Shows a simple SnackBar feedback message to the user.
void _showFeedbackMessage(String message) {
  final context = NavigationService().navigatorKey.currentContext;
  if (context == null || !context.mounted) return;
  
  ScaffoldMessenger.of(context).hideCurrentSnackBar(); 
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

// --- PUBLIC API for Shows ---

/// Clears the current playlist, adds all tracks from a Show, and starts playing.
///
/// [show]: The Show object containing the tracks to be played.
/// [initialTrack]: The specific track within the show to start playback from.
Future<void> playShowFromTrack(Show show, Track initialTrack) async {
  if (show.tracks.isEmpty) {
    _logger.w("Attempted to play a show with an empty track list: ${show.name}");
    return;
  }

  // Find the index of the selected track within the show's tracklist.
  final initialIndex = show.tracks.indexOf(initialTrack);

  if (initialIndex == -1) {
    _logger.w("Track '${initialTrack.trackName}' not found in show '${show.name}'. Playing from start.");
    // Fallback to playing from the beginning if the track isn't found
    await playShowFromTracks(show, initialIndex: 0);
    return;
  }

  _logger.i("Playing show '${show.name}' from track '${initialTrack.trackName}' at index $initialIndex.");
  
  // Delegate the core logic to the more generic playShowFromTracks function.
  await playShowFromTracks(show, initialIndex: initialIndex);
}

/// A more generic function to play a show from a specific index.
Future<void> playShowFromTracks(Show show, {int initialIndex = 0}) async {
  if (show.tracks.isEmpty) {
    _logger.w("Attempted to play a show with an empty track list: ${show.name}");
    return;
  }

  final provider = _getTrackPlayerProvider();
  if (provider == null) return;

  // The provider's method works perfectly with any list of tracks.
  await provider.replacePlaylistAndPlay(show.tracks, initialIndex: initialIndex);
  _logger.i("Playback initiated for show: ${show.name}");
}

/// Selects a random show from a list of shows and starts playing it.
Future<void> playRandomShow(List<Show> allShows) async {
  _logger.i("Attempting to select and play a random show.");
  
  if (allShows.isEmpty) {
    _logger.w("No shows available for random selection");
    _showFeedbackMessage("No shows available to play");
    return;
  }

  final randomIndex = Random().nextInt(allShows.length);
  final randomShow = allShows[randomIndex];

  _logger.d("Random show selected: '${randomShow.name}' at index $randomIndex.");

  await playShowFromTracks(randomShow);
}