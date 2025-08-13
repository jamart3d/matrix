// lib/providers/track_player_provider.dart

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:matrix/helpers/album_helper.dart'; // Ensure this import exists
import 'package:matrix/models/track.dart';
import 'package:matrix/services/album_data_service.dart';
import 'package:matrix/utils/duration_formatter.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class TrackPlayerProvider extends ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final Logger _logger = Logger();

  List<Track> _playlist = [];
  int _currentIndex = 0;
  String? _cachedAlbumArt;
  bool _isLoading = false;
  bool _isPlaying = false;
  String? _lastError;

  final Map<String, Future<Uri>> _tempFileUriCache = {};

  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;
  int get currentIndex => _currentIndex;

  Track? get currentTrack =>
      _playlist.isNotEmpty && _currentIndex >= 0 && _currentIndex < _playlist.length
          ? _playlist[_currentIndex]
          : null;

  List<Track> get playlist => List.unmodifiable(_playlist);

  String get currentAlbumArt => _cachedAlbumArt ?? 'assets/images/t_steal.webp';
  String get currentArtistName => currentTrack?.artistName ?? 'Unknown Artist';
  String get currentAlbumTitle => currentTrack?.albumName ?? 'Unknown Album';

  Duration get currentDuration => _audioPlayer.position;
  Duration get totalDuration => _audioPlayer.duration ?? Duration.zero;
  String get formattedCurrentDuration => formatDuration(currentDuration);
  String get formattedTotalDuration => formatDuration(totalDuration);

  Stream<Duration> get positionStream => _audioPlayer.positionStream;
  Stream<Duration> get bufferedPositionStream => _audioPlayer.bufferedPositionStream;
  Stream<PlayerState> get playerStateStream => _audioPlayer.playerStateStream;
  Stream<ProcessingState> get processingStateStream => _audioPlayer.processingStateStream;
  Stream<Duration?> get durationStream => _audioPlayer.durationStream;

  // =======================================================================
  // === THIS METHOD IS NOW CORRECTLY RESTORED                           ===
  // =======================================================================
  double getCurrentBufferHealth() {
    final duration = _audioPlayer.duration;
    final position = _audioPlayer.position;
    final buffered = _audioPlayer.bufferedPosition;

    if (duration == null) return 0.0;

    final remainingDuration = duration - position;
    if (remainingDuration.inMilliseconds <= 0) return 100.0;

    final availableBuffer = buffered - position;
    if (availableBuffer.inMilliseconds <= 0) return 0.0;

    return (availableBuffer.inMilliseconds / remainingDuration.inMilliseconds * 100).clamp(0.0, 100.0);
  }

  Duration get currentBufferedPosition => _audioPlayer.bufferedPosition;

  bool get isBuffering => _audioPlayer.processingState == ProcessingState.buffering || _audioPlayer.processingState == ProcessingState.loading;

  TrackPlayerProvider() {
    _logger.i("TrackPlayerProvider initialized.");
    _listenToAudioPlayerEvents();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _listenToAudioPlayerEvents() {
    _audioPlayer.playerStateStream.listen((state) {
      final newIsPlaying = state.playing;
      final newIsLoading = state.processingState == ProcessingState.loading || state.processingState == ProcessingState.buffering;

      if (_isPlaying != newIsPlaying || _isLoading != newIsLoading) {
        _isPlaying = newIsPlaying;
        _isLoading = newIsLoading;
        notifyListeners();
      }
    });

    _audioPlayer.currentIndexStream.distinct().listen((index) {
      if (index != null && _currentIndex != index) {
        _currentIndex = index;
        notifyListeners();
      }
    });
  }

  void _loadPlaylistMetadata() {
    final track = currentTrack;
    if (track == null) {
      _cachedAlbumArt = null;
      return;
    };

    if (track.albumArt != null && track.albumArt!.isNotEmpty) {
      _cachedAlbumArt = track.albumArt;
    } else {
      final releaseNumber = AlbumDataService().getReleaseNumberForAlbum(track.albumName);
      if (releaseNumber != null) {
        // This call is now valid.
        _cachedAlbumArt = generateAlbumArt(releaseNumber);
      } else {
        _cachedAlbumArt = 'assets/images/t_steal.webp';
      }
    }
  }

  Future<void> replacePlaylistAndPlay(List<Track> tracks, {int initialIndex = 0}) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _audioPlayer.stop();
      _playlist = List.from(tracks);
      _currentIndex = initialIndex.clamp(0, _playlist.length - 1);

      _loadPlaylistMetadata();

      if (_playlist.isEmpty) return;

      final artUri = await _getUriForAsset(currentAlbumArt);
      final audioSources = await Future.wait(_playlist.map((track) => _createAudioSource(track, artUri)));

      await _audioPlayer.setAudioSource(
        ConcatenatingAudioSource(children: audioSources),
        initialIndex: _currentIndex,
        preload: true,
      );
      await play();
    } finally {
      if (_isLoading) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<Uri> _getUriForAsset(String assetPath) {
    return _tempFileUriCache.putIfAbsent(assetPath, () async {
      final byteData = await rootBundle.load(assetPath);
      final tempDir = await getTemporaryDirectory();
      final file = File(p.join(tempDir.path, p.basename(assetPath)));
      await file.writeAsBytes(byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
      return file.uri;
    });
  }

  Future<AudioSource> _createAudioSource(Track track, Uri artUri) async {
    final audioUri = track.url.startsWith('assets/')
        ? await _getUriForAsset(track.url)
        : Uri.parse(track.url);

    return AudioSource.uri(
      audioUri,
      tag: MediaItem(
        id: track.url,
        album: track.albumName,
        title: track.trackName,
        artist: track.artistName,
        artUri: artUri,
        duration: Duration(seconds: track.trackDuration),
      ),
    );
  }

  Future<void> play() async => _audioPlayer.play();
  Future<void> pause() async => _audioPlayer.pause();
  Future<void> seekTo(Duration position) async => _audioPlayer.seek(position);

  Future<void> next() async {
    if (_audioPlayer.hasNext) await _audioPlayer.seekToNext();
  }

  Future<void> previous() async {
    if (_audioPlayer.position.inSeconds > 3) {
      await seekTo(Duration.zero);
    } else if (_audioPlayer.hasPrevious) {
      await _audioPlayer.seekToPrevious();
    }
  }

  Future<void> clearPlaylist() async {
    await _audioPlayer.stop();
    _playlist = [];
    _currentIndex = 0;
    _cachedAlbumArt = null;
    _lastError = null;
    notifyListeners();
  }
}