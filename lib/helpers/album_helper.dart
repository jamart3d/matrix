// lib/helpers/album_helper.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:matrix/models/album.dart';
import 'package:matrix/models/track.dart';
import 'package:matrix/providers/track_player_provider.dart';
import 'package:matrix/services/navigation_service.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';

final _logger = Logger();

// --- PROVIDER HELPER ---

TrackPlayerProvider? _getTrackPlayerProvider() {
  final context = NavigationService().navigatorKey.currentContext;
  if (context == null || !context.mounted) {
    _logger.e("Cannot get TrackPlayerProvider: context is not available");
    return null;
  }
  return Provider.of<TrackPlayerProvider>(context, listen: false);
}

// --- PLAYBACK HELPERS ---

Future<void> playAlbumFromTracks(List<Track> tracks, {int initialIndex = 0}) async {
  if (tracks.isEmpty) {
    _logger.w("Attempted to play album with empty track list");
    return;
  }
  final validInitialIndex = initialIndex.clamp(0, tracks.length - 1);
  final provider = _getTrackPlayerProvider();
  if (provider == null) return;
  await provider.replacePlaylistAndPlay(tracks, initialIndex: validInitialIndex);
}

// =======================================================================
// === VERIFY THIS FUNCTION EXISTS EXACTLY AS WRITTEN BELOW            ===
// =======================================================================
/// Plays a specific track from a list, loading the entire list into the playlist.
Future<void> playTrackFromAlbum(List<Track> albumTracks, Track specificTrack) async {
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


Future<void> playRandomAlbum(List<Album> allAlbums) async {
  final playableAlbums = allAlbums.where((album) => album.tracks.isNotEmpty).toList();
  if (playableAlbums.isEmpty) {
    return;
  }
  final randomAlbum = playableAlbums[Random().nextInt(playableAlbums.length)];
  _logger.d("Random album selected: '${randomAlbum.name}'.");
  await playAlbumFromTracks(randomAlbum.tracks);
}

// --- OTHER UTILITIES ---

String generateAlbumArt(int albumIndex) {
  const pathPrefix = 'assets/images/trix_album_art/trix';
  const extension = '.webp';
  return '$pathPrefix${albumIndex.toString().padLeft(2, '0')}$extension';
}

String formatAlbumName(String albumName) {
  final parts = albumName.split('-');
  if (parts.length > 3) {
    return parts.sublist(3).join('-').replaceAll(RegExp(r'^[^a-zA-Z0-9]'), '');
  }
  return albumName;
}

String extractDateFromAlbumName(String albumName) {
  final parts = albumName.split('-');
  if (parts.length >= 3) {
    return parts.sublist(0, 3).join('-');
  }
  return '';
}

void preloadAlbumImages(List<Album> albums, BuildContext context) {
  for (final album in albums) {
    if (album.albumArt.isNotEmpty) {
      precacheImage(AssetImage(album.albumArt), context);
    }
  }
}