// lib/providers/track_player_provider.dart

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:matrix/helpers/album_helper.dart';
import 'package:matrix/models/track.dart';
import 'package:matrix/services/album_data_service.dart';
import 'package:matrix/utils/duration_formatter.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class TrackPlayerProvider extends ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final Logger _logger = Logger();

  // --- STATE ---
  List<Track> _playlist = [];
  int _currentIndex = 0;
  String? _cachedAlbumArt;
  bool _isLoading = false;
  bool _isPlaying = false;
  String? _lastError;
  bool _wasInitiatedByDeepLink = false;
  final Map<String, Future<Uri>> _tempFileUriCache = {};

  // ================== NEW STATE FOR TIMEOUT ==================
  Timer? _loadingTimer;
  bool _isLoadingTimeout = false; // Is the player in a timeout state?
  String? _loadingError; // A specific error message for loading failures
  // ==========================================================

  // --- PUBLIC GETTERS ---
  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;
  int get currentIndex => _currentIndex;
  bool get wasInitiatedByDeepLink => _wasInitiatedByDeepLink;
  // ================== NEW GETTERS FOR TIMEOUT =================
  bool get isLoadingTimeout => _isLoadingTimeout;
  String? get loadingError => _loadingError;
  // ===========================================================

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
    _loadingTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  void setInitiatedByDeepLink() {
    _wasInitiatedByDeepLink = true;
  }

  void consumeDeepLinkInitiation() {
    _wasInitiatedByDeepLink = false;
  }

  void _listenToAudioPlayerEvents() {
    _audioPlayer.playerStateStream.listen((state) {
      final newIsPlaying = state.playing;
      final newIsLoading = state.processingState == ProcessingState.loading ||
          state.processingState == ProcessingState.buffering;

      // When loading starts, start the timeout timer
      if (newIsLoading && !_isLoading) {
        _startLoadingTimer();
      }

      // If loading finishes or playback starts, cancel the timer
      if ((!newIsLoading && _isLoading) || newIsPlaying) {
        _resetLoadingState();
      }

      if (_isPlaying != newIsPlaying || _isLoading != newIsLoading) {
        _isPlaying = newIsPlaying;
        _isLoading = newIsLoading;
        notifyListeners();
      }
    });

    _audioPlayer.currentIndexStream.listen((index) {
      if (index != null && _currentIndex != index) {
        _currentIndex = index;
        notifyListeners();
      }
    });
  }

  // ================== NEW METHODS FOR TIMEOUT ==================
  void _startLoadingTimer() {
    _loadingTimer?.cancel(); // Cancel any existing timer
    _isLoadingTimeout = false;
    _loadingError = null;

    _loadingTimer = Timer(const Duration(seconds: 15), () {
      if (_isLoading) { // Only fire if we are still in a loading state
        _logger.w("Loading timed out after 15 seconds.");
        _isLoadingTimeout = true;
        _loadingError = "This is taking a while. The network may be slow or the track unavailable.";
        _isLoading = false; // Stop showing the generic spinner
        notifyListeners();
      }
    });
  }

  void _resetLoadingState() {
    _loadingTimer?.cancel();
    if (_isLoadingTimeout || _loadingError != null) {
      _isLoadingTimeout = false;
      _loadingError = null;
      // No need to notify here, will be handled by the state change that triggered the reset
    }
  }

  /// Retries loading the current track.
  Future<void> retryCurrentTrack() async {
    _resetLoadingState();
    _isLoading = true;
    notifyListeners();

    // Re-seek to the current index to trigger a reload.
    await seekToIndex(_currentIndex, forceReload: true);
  }
  // =============================================================

  void _loadPlaylistMetadata() {
    final track = currentTrack;
    if (track == null) {
      _cachedAlbumArt = null;
      return;
    }

    if (track.albumArt != null && track.albumArt!.isNotEmpty) {
      _cachedAlbumArt = track.albumArt;
    } else {
      final releaseNumber = AlbumDataService().getReleaseNumberForAlbum(track.albumName);
      if (releaseNumber != null) {
        _cachedAlbumArt = generateAlbumArt(releaseNumber);
      } else {
        _cachedAlbumArt = 'assets/images/t_steal.webp';
      }
    }
  }

  Future<void> replacePlaylistAndPlay(List<Track> tracks, {int initialIndex = 0}) async {
    _logger.i("Replacing playlist with ${tracks.length} tracks...");
    _resetLoadingState(); // Reset timeout state on new playlist

    try {
      await _audioPlayer.stop();
      _playlist = List.from(tracks);
      _currentIndex = initialIndex.clamp(0, _playlist.length - 1);

      _loadPlaylistMetadata();

      if (_playlist.isEmpty) {
        if (_isLoading) {
          _isLoading = false;
          notifyListeners();
        }
        return;
      }

      final artUri = await _getUriForAsset(currentAlbumArt);
      final audioSources = await Future.wait(_playlist.map((track) => _createAudioSource(track, artUri)));

      await _audioPlayer.setAudioSources(
        audioSources,
        initialIndex: _currentIndex,
        preload: true,
      );
      await play();
    } catch (e, s) {
      _logger.e("Error in replacePlaylistAndPlay", error: e, stackTrace: s);
      _lastError = "Failed to start playlist.";
      _isLoading = false;
      _isLoadingTimeout = true; // Use the timeout UI for general errors too
      _loadingError = "Could not play this track. It may be unavailable.";
      notifyListeners();
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

  Future<void> seekToIndex(int index, {bool forceReload = false}) async {
    if (index >= 0 && index < _playlist.length) {
      _logger.i("Seeking to playlist index: $index");
      _resetLoadingState(); // Reset timeout state on seek
      try {
        await _audioPlayer.seek(Duration.zero, index: index);
        // If we are forcing a reload (e.g. from a retry), ensure play is called.
        if (!_isPlaying || forceReload) {
          await play();
        }
      } catch (e, s) {
        _logger.e("Error seeking to index $index", error: e, stackTrace: s);
      }
    }
  }

  Future<void> next() async {
    _resetLoadingState(); // Reset timeout state on next
    if (_audioPlayer.hasNext) await _audioPlayer.seekToNext();
  }

  Future<void> previous() async {
    _resetLoadingState(); // Reset timeout state on previous
    if (_audioPlayer.position.inSeconds > 3) {
      await seekTo(Duration.zero);
    } else if (_audioPlayer.hasPrevious) {
      await _audioPlayer.seekToPrevious();
    }
  }

  Future<void> clearPlaylist() async {
    await _audioPlayer.stop();
    _resetLoadingState();
    _playlist = [];
    _currentIndex = 0;
    _cachedAlbumArt = null;
    _lastError = null;
    notifyListeners();
  }
}