import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AlbumSettingsProvider extends ChangeNotifier {
  // Define unique keys for storing settings
  static const String _displayOrderKey = 'displayAlbumReleaseNumber';
  static const String _skipShowsPageKey = 'skipShowsPage';

  // --- Setting 1: Display Release Order ---
  bool _displayAlbumReleaseNumber = false;
  bool get displayAlbumReleaseNumber => _displayAlbumReleaseNumber;

  // --- Setting 2: Skip Shows Page ---
  bool _skipShowsPage = false;
  bool get skipShowsPage => _skipShowsPage;

  AlbumSettingsProvider() {
    // Load all settings when the provider is created
    _loadSettings();
  }

  /// Loads all settings from the device's local storage.
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    // Load the display order setting, defaulting to false if not found
    _displayAlbumReleaseNumber = prefs.getBool(_displayOrderKey) ?? false;
    // Load the skip shows page setting, defaulting to false if not found
    _skipShowsPage = prefs.getBool(_skipShowsPageKey) ?? false;
    // Notify any widgets listening to this provider that the values have been loaded
    notifyListeners();
  }

  /// Updates the 'display release order' setting and saves it.
  Future<void> setDisplayAlbumReleaseNumber(bool value) async {
    if (_displayAlbumReleaseNumber == value) return; // No change needed
    _displayAlbumReleaseNumber = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_displayOrderKey, value);
    notifyListeners();
  }

  /// Toggles the 'display release order' setting.
  void toggleDisplayAlbumReleaseNumber() {
    setDisplayAlbumReleaseNumber(!_displayAlbumReleaseNumber);
  }
  
  /// Updates the 'skip shows page' setting and saves it.
  Future<void> setSkipShowsPage(bool value) async {
    if (_skipShowsPage == value) return; // No change needed
    _skipShowsPage = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_skipShowsPageKey, value);
    notifyListeners();
  }
}