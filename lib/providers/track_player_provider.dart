// lib/providers/track_player_provider.dart

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:matrix/models/track.dart';
import 'package:matrix/services/album_data_service.dart';
import 'package:matrix/utils/album_utils.dart';
import 'package:matrix/utils/duration_formatter.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class TrackPlayerProvider extends ChangeNotifier {
  final AudioPlayer audioPlayer = AudioPlayer();
  final Logger logger = Logger();

  ConcatenatingAudioSource? _concatenatingAudioSource;
  int _currentIndex = 0;

  String? _cachedAlbumArt;
  String? _cachedArtistName;
  String? _cachedAlbumTitle;

  String? _lastError;
  bool _isLoading = false;
  bool _isPlaying = false;
  
  String get formattedCurrentDuration => formatDuration(audioPlayer.position);
  String get formattedTotalDuration =>
      formatDuration(audioPlayer.duration ?? Duration.zero);
  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;
  int get currentIndex => _currentIndex;
  Duration get currentDuration => audioPlayer.position;
  Duration get totalDuration => audioPlayer.duration ?? Duration.zero;
  List<Track> get playlist => List.unmodifiable(_playlist);
  Track? get currentTrack =>
      _currentIndex >= 0 && _currentIndex < _playlist.length
          ? _playlist[_currentIndex]
          : null;
  String get currentAlbumArt => _cachedAlbumArt ?? 'assets/images/t_steal.webp';
  String get currentArtistName => _cachedArtistName ?? 'Unknown Artist';
  String get currentAlbumTitle => _cachedAlbumTitle ?? 'Unknown Album';
  Stream<Duration> get positionStream => audioPlayer.positionStream;
  Stream<Duration?> get durationStream => audioPlayer.durationStream;
  Stream<PlayerState> get playerStateStream => audioPlayer.playerStateStream;
  
  final List<Track> _playlist = [];

  TrackPlayerProvider() {
    logger.i("TrackPlayerProvider initialized.");
    _listenToAudioPlayerEvents();
  }

  @override
  void dispose() {
    logger.w("Disposing TrackPlayerProvider and AudioPlayer.");
    audioPlayer.dispose();
    super.dispose();
  }
  
  void _setError(String error) {
    _lastError = error;
    _isLoading = false;
    notifyListeners();
  }

  void _clearError() {
    if (_lastError != null) {
      _lastError = null;
      notifyListeners();
    }
  }

  void _listenToAudioPlayerEvents() {
    audioPlayer.playerStateStream.listen((state) {
      bool needsUpdate = false;
      final wasLoading = _isLoading;
      _isLoading = state.processingState == ProcessingState.loading ||
          state.processingState == ProcessingState.buffering;
      if (wasLoading != _isLoading) needsUpdate = true;
      if (_isPlaying != state.playing) {
        _isPlaying = state.playing;
        needsUpdate = true;
      }
      if (needsUpdate) notifyListeners();
    });

    audioPlayer.currentIndexStream.distinct().listen((index) {
      if (index != null && index >= 0 && index < _playlist.length) {
        _currentIndex = index;
        _loadAlbumAndArtistData();
        notifyListeners();
      }
    });
  }

  void _loadAlbumAndArtistData() {
    if (currentTrack == null) return;
    logger.i("Loading metadata for: ${currentTrack!.trackName}");

    _cachedArtistName = currentTrack!.trackArtistName;
    _cachedAlbumTitle = currentTrack!.albumName;

    if (currentTrack!.albumArt != null && currentTrack!.albumArt!.isNotEmpty) {
      _cachedAlbumArt = currentTrack!.albumArt;
    } else {
      logger.d("Track has no art. Getting release number from AlbumDataService...");
      final releaseNumber = AlbumDataService().getReleaseNumberForAlbum(currentTrack!.albumName);

      if (releaseNumber != null) {
        _cachedAlbumArt = generateAlbumArt(releaseNumber);
        logger.i("Generated art path for '${currentTrack!.albumName}': $_cachedAlbumArt");
      } else {
        logger.w("Could not find release number for '${currentTrack!.albumName}' in cache.");
        _cachedAlbumArt = 'assets/images/t_steal.webp';
      }
    }
  }

  Future<void> replacePlaylistAndPlay(
    List<Track> tracks, {
    int initialIndex = 0,
  }) async {
    logger.i(
        "Replacing playlist with ${tracks.length} new tracks, starting from index $initialIndex.");
    _clearError();

    try {
      await audioPlayer.stop();
      _playlist.clear();
      _concatenatingAudioSource = null;

      _playlist.addAll(tracks);
      _currentIndex = initialIndex.clamp(0, tracks.length - 1);

      _loadAlbumAndArtistData();

      if (_playlist.isEmpty) {
        logger.w("Cannot play an empty playlist.");
        return;
      }

      final sources =
          await Future.wait(_playlist.map(_createAudioSourceFromTrack));
      _concatenatingAudioSource = ConcatenatingAudioSource(children: sources);

      await audioPlayer.setAudioSource(
        _concatenatingAudioSource!,
        initialIndex: _currentIndex,
      );

      await audioPlayer.play();
    } catch (e, stacktrace) {
      logger.e("Error replacing playlist", error: e, stackTrace: stacktrace);
      _setError("Failed to start new playlist.");
    }
  }

  Future<Uri> _saveAssetToTempFile(String assetPath) async {
    try {
      final byteData = await rootBundle.load(assetPath);
      final buffer = byteData.buffer;
      final tempDir = await getTemporaryDirectory();
      final fileName = p.basename(assetPath);
      final filePath = p.join(tempDir.path, fileName);
      final file = await File(filePath).writeAsBytes(buffer.asUint8List());
      return file.uri;
    } catch (e) {
      logger.e("Error saving asset '$assetPath' to temp file", error: e);
      rethrow;
    }
  }
  
  Future<AudioSource> _createAudioSourceFromTrack(Track track) async {
    final audioUri = track.url.startsWith('assets/')
        ? await _saveAssetToTempFile(track.url)
        : Uri.parse(track.url);

    final artUri = await _saveAssetToTempFile(
        _cachedAlbumArt ?? 'assets/images/t_steal.webp');

    final uniqueId =
        '${track.trackName}_${track.trackArtistName}_${track.albumName}'
            .replaceAll(RegExp(r'[^\w\-_]'), '');

    return AudioSource.uri(
      audioUri,
      tag: MediaItem(
        id: uniqueId,
        album: track.albumName,
        title: track.trackName,
        artist: track.trackArtistName,
        artUri: artUri,
      ),
    );
  }

  Future<void> play() async {
    logger.i("play() called.");
    try {
      await audioPlayer.play();
    } catch (e) {
      _setError('Error resuming playback.');
    }
  }

  Future<void> pause() async {
    logger.i("pause() called.");
    try {
      await audioPlayer.pause();
    } catch (e) {
      _setError("Failed to pause playback.");
    }
  }

  Future<void> next() async {
    logger.i("next() called.");
    if (audioPlayer.hasNext) {
      await audioPlayer.seekToNext();
    }
  }

  Future<void> previous() async {
    logger.i("previous() called.");
    if (audioPlayer.position.inSeconds > 2) {
      await audioPlayer.seek(Duration.zero);
    } else if (audioPlayer.hasPrevious) {
      await audioPlayer.seekToPrevious();
    } else {
      await audioPlayer.seek(Duration.zero);
    }
  }

  Future<void> seekTo(Duration position) async {
    logger.i("Seeking to position: $position");
    try {
      await audioPlayer.seek(position);
    } catch (e) {
      _setError("Failed to seek to position.");
    }
  }

  Future<void> clearPlaylist() async {
    logger.w("Clearing playlist and stopping audio.");
    try {
      await audioPlayer.stop();
      _playlist.clear();
      _currentIndex = 0;
      _cachedAlbumArt = null;
      _cachedAlbumTitle = null;
      _cachedArtistName = null;
      _concatenatingAudioSource = null;
      _clearError();
      notifyListeners();
    } catch (e) {
      _setError("Failed to clear playlist.");
    }
  }
}