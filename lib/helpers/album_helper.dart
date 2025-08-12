import 'dart:math';
import 'package:flutter/material.dart';
import 'package:matrix/models/track.dart';
import 'package:matrix/providers/track_player_provider.dart';
import 'package:matrix/services/navigation_service.dart';
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

// --- PUBLIC API ---

/// Clears the current playlist, adds a new one, and immediately starts
/// playing from the specified track index.
Future<void> playAlbumFromTracks(
  List<Track> tracks, {
  int initialIndex = 0, // <-- The {} make this an optional named parameter.
}) async {
  if (tracks.isEmpty) {
    _logger.w("Attempted to play album with empty track list");
    return;
  }
  
  // Ensure the index is always valid.
  initialIndex = initialIndex.clamp(0, tracks.length - 1);

  _logger.i("Attempting to play album with ${tracks.length} tracks, starting at index $initialIndex.");
  
  final provider = _getTrackPlayerProvider();
  if (provider == null) return;

  await provider.replacePlaylistAndPlay(tracks, initialIndex: initialIndex);
  _logger.i("Playback initiated for album: ${tracks[initialIndex].albumName}");
}

/// Validates that an album map contains a valid list of tracks.
bool _isValidAlbumData(Map<String, dynamic> albumData) {
  return albumData.containsKey('songs') && 
         albumData['songs'] is List<Track> && 
         (albumData['songs'] as List<Track>).isNotEmpty;
}

/// Selects a random album from the provided list and immediately starts playing it.
Future<void> playRandomAlbum(List<Map<String, dynamic>> allAlbumData) async {
  _logger.i("Attempting to select and play a random album.");
  
  final validAlbums = allAlbumData.where(_isValidAlbumData).toList();
  if (validAlbums.isEmpty) {
    _logger.w("No valid albums available for random selection");
    _showFeedbackMessage("No albums available to play");
    return;
  }

  final randomIndex = Random().nextInt(validAlbums.length);
  final randomAlbum = validAlbums[randomIndex];
  final albumTracks = randomAlbum['songs'] as List<Track>;
  final albumName = randomAlbum['album'] as String? ?? 'Unknown Album';

  _logger.d("Random album selected: '$albumName' at index $randomIndex.");

  // This call is now correct because playAlbumFromTracks has an optional parameter.
  await playAlbumFromTracks(albumTracks);
}

/// Plays a specific track from a list, loading the entire list into the playlist.
Future<void> playTrackFromAlbum(
  List<Track> albumTracks,
  Track specificTrack,
) async {
  if (albumTracks.isEmpty) {
    _logger.w("Attempted to play track from empty album");
    return;
  }

  final trackIndex = albumTracks.indexOf(specificTrack);

  if (trackIndex == -1) {
    _logger.w("Specific track not found in album tracks. Playing first track instead.");
    await playAlbumFromTracks(albumTracks, initialIndex: 0);
    return;
  }

  _logger.i("Playing specific track '${specificTrack.trackName}' from album at index $trackIndex");
  await playAlbumFromTracks(albumTracks, initialIndex: trackIndex);
}

/// Shuffles and plays an album.
Future<void> playAlbumShuffled(List<Track> tracks) async {
  if (tracks.isEmpty) {
    _logger.w("Attempted to shuffle empty track list");
    return;
  }

  _logger.i("Shuffling and playing album with ${tracks.length} tracks");
  
  final shuffledTracks = List<Track>.from(tracks)..shuffle();
  
  await playAlbumFromTracks(shuffledTracks);
}

/// Convenience method to quickly play a single track.
Future<void> playSingleTrack(Track track) async {
  await playAlbumFromTracks([track]);
}