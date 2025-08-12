import 'dart:math';
import 'package:flutter/material.dart';
import 'package:matrix/models/show.dart';
import 'package:matrix/models/track.dart';
import 'package:matrix/providers/track_player_provider.dart';
import 'package:matrix/services/navigation_service.dart'; // Corrected this import as well, it should be a .dart file
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';

// A single logger instance for the entire file.
final _logger = Logger();

/// Safely gets the track player provider from the widget tree using a NavigationService.
TrackPlayerProvider? _getTrackPlayerProvider() {
  final context = NavigationService().navigatorKey.currentContext;
  if (context == null || !context.mounted) {
    _logger.e("Cannot get TrackPlayerProvider: context is not available");
    return null;
  }
  
  try {
    // Use listen: false because we are calling a method, not rebuilding a widget.
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

// --- PUBLIC API for Playing Tracks ---

/// The new core function. Plays a specific list of tracks from a given starting index.
///
/// This is the central workhorse that communicates with the provider.
///
/// [tracks]: The specific list of tracks to play (e.g., from one shnid).
/// [initialIndex]: The index in the list to start playback from.
Future<void> playTracklist(List<Track> tracks, {int initialIndex = 0}) async {
  if (tracks.isEmpty) {
    _logger.w("Attempted to play an empty track list.");
    _showFeedbackMessage("This source has no tracks to play.");
    return;
  }

  final provider = _getTrackPlayerProvider();
  if (provider == null) return;

  // The provider's method works perfectly with any list of tracks.
  await provider.replacePlaylistAndPlay(tracks, initialIndex: initialIndex);
  
  _logger.i("Playback initiated for tracklist with ${tracks.length} tracks, starting at index $initialIndex.");
}

/// Plays a tracklist starting from a specific `Track` object.
///
/// This is perfect for when a user taps on a single track in the UI.
///
/// [tracks]: The list of tracks that the `initialTrack` belongs to.
/// [initialTrack]: The specific track to start playing.
Future<void> playTracklistFrom(List<Track> tracks, Track initialTrack) async {
  // Find the index of the selected track within its source's tracklist.
  final initialIndex = tracks.indexOf(initialTrack);

  if (initialIndex == -1) {
    _logger.w("Track '${initialTrack.trackName}' not found in the provided tracklist. Playing from start.");
    // Fallback to playing from the beginning if the track isn't found for some reason.
    await playTracklist(tracks, initialIndex: 0);
    return;
  }

  _logger.i("Request to play tracklist from track '${initialTrack.trackName}' at index $initialIndex.");
  
  // Delegate the core logic to the more generic playTracklist function.
  await playTracklist(tracks, initialIndex: initialIndex);
}


/// Selects a random show, picks its primary source, and starts playing it.
///
/// This function is used for the "Play Random Show" button.
Future<void> playRandomShow(List<Show> allShows) async {
  _logger.i("Attempting to select and play a random show.");
  
  if (allShows.isEmpty) {
    _logger.w("No shows available for random selection");
    _showFeedbackMessage("No shows available to play");
    return;
  }

  final randomIndex = Random().nextInt(allShows.length);
  final randomShow = allShows[randomIndex];

  _logger.d("Random show selected: '${randomShow.displayName}' at index $randomIndex.");

  // Get the tracks from the show's primary source using the new helper getter.
  final tracksToPlay = randomShow.primaryTracks;

  if (tracksToPlay.isEmpty) {
    _logger.w("Selected random show '${randomShow.displayName}' has no tracks in its primary source.");
    _showFeedbackMessage("Selected random show has no tracks.");
    return;
  }

  // Use the core function to play the selected tracklist from the beginning.
  await playTracklist(tracksToPlay);
}