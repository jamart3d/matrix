import 'package:flutter/material.dart';
import 'package:huntrix/utils/load_json_data.dart' as loader;

/// A singleton service to cache album data after it's loaded once.
/// This prevents repeated file reads and parsing.
class AlbumDataService {
  // Singleton setup
  static final AlbumDataService _instance = AlbumDataService._internal();
  factory AlbumDataService() => _instance;
  AlbumDataService._internal();

  List<Map<String, dynamic>>? _albumData;
  Map<String, int>? _albumNameToReleaseNumberMap;
  bool _isDataLoaded = false;

  /// Returns the cached list of album data.
  List<Map<String, dynamic>>? get albumData => _albumData;

  /// Gets the release number for a given album name from the cache.
  /// Returns null if the data isn't loaded or the album isn't found.
  int? getReleaseNumberForAlbum(String albumName) {
    return _albumNameToReleaseNumberMap?[albumName];
  }

  /// Loads the data from the JSON file and populates the cache.
  /// This should be called by the first page that needs the album data.
  Future<void> loadAndCacheAlbumData(
      BuildContext context, Function(List<Map<String, dynamic>>?) onDataLoaded) async {
    // Only load from the file if it hasn't been loaded before.
    if (_isDataLoaded) {
      onDataLoaded(_albumData);
      return;
    }

    // Use the existing loader function.
    await loader.loadData(context, (loadedData) {
      if (loadedData != null) {
        _albumData = loadedData;
        _albumNameToReleaseNumberMap = {
          for (var album in loadedData)
            album['album'] as String: album['releaseNumber'] as int
        };
        _isDataLoaded = true;
      }
      onDataLoaded(_albumData);
    });
  }
}