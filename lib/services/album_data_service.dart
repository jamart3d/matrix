// lib/services/album_data_service.dart

import 'package:matrix/models/album.dart';
import 'package:matrix/utils/load_json_data.dart' as loader;
import 'package:logger/logger.dart';

/// A singleton service to load and cache album data once from assets.
/// This prevents repeated file reads and parsing, providing a fast,
/// type-safe, and synchronous way to access data after initial loading.
class AlbumDataService {
  // --- Singleton Setup ---
  static final AlbumDataService _instance = AlbumDataService._internal();
  factory AlbumDataService() => _instance;
  AlbumDataService._internal();

  // --- Internal State ---
  final _logger = Logger();
  List<Album>? _albums;
  Map<String, int>? _albumNameToReleaseNumberMap;
  Future<void>? _initializationFuture;

  // --- Public Getters (Synchronous) ---

  /// Returns the cached list of albums.
  /// Throws a StateError if accessed before `init()` has completed successfully.
  List<Album> get albums {
    if (_albums == null) {
      throw StateError("AlbumDataService not initialized. Call init() first.");
    }
    return _albums!;
  }

  /// Gets the release number for a given album name from the cache.
  /// Returns null if the album isn't found. This can be called even before
  /// init() completes, but it will only return data after completion.
  int? getReleaseNumberForAlbum(String albumName) {
    return _albumNameToReleaseNumberMap?[albumName];
  }

  /// Loads data from the JSON file and populates the cache.
  ///
  /// This method is safe to call multiple times; the data will only be
  /// loaded from the file on the very first call. Subsequent calls will
  /// return the same completed Future.
  Future<void> init() {
    // If the initialization future already exists, just return it.
    // This prevents the data from being loaded more than once.
    _initializationFuture ??= _loadAndCacheAlbums();
    return _initializationFuture!;
  }

  /// The internal method that performs the actual data loading.
  Future<void> _loadAndCacheAlbums() async {
    _logger.i("Initializing AlbumDataService: loading albums for the first time...");
    try {
      // 1. Call the new, decoupled loader function.
      final loadedAlbums = await loader.loadAlbums();

      // 2. Cache the results in memory.
      _albums = loadedAlbums;
      _albumNameToReleaseNumberMap = {
        for (var album in loadedAlbums) album.name: album.releaseNumber
      };

      _logger.i("AlbumDataService initialized successfully with ${_albums!.length} albums.");
    } catch (e, stacktrace) {
      _logger.e(
        "Failed to initialize AlbumDataService.",
        error: e,
        stackTrace: stacktrace,
      );
      // Allow the caller to handle the error.
      rethrow;
    }
  }
}