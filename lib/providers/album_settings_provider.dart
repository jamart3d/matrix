// lib/providers/album_settings_provider.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ShowSortOrder { dateDescending, dateAscending }

class AlbumSettingsProvider extends ChangeNotifier {
  // Define unique keys for storing all settings
  static const String _displayOrderKey = 'displayAlbumReleaseNumber';
  static const String _skipShowsPageKey = 'skipShowsPage';
  static const String _marqueeTitlesKey = 'marqueeTitles';
  static const String _showSortOrderKey = 'showSortOrder';
  // --- NEW KEY ---
  static const String _marqueePlayerTitleKey = 'marqueePlayerTitle';

  // --- Setting 1: Display Release Order (Albums) ---
  bool _displayAlbumReleaseNumber = false;
  bool get displayAlbumReleaseNumber => _displayAlbumReleaseNumber;

  // --- Setting 2: Skip Shows Page ---
  bool _skipShowsPage = false;
  bool get skipShowsPage => _skipShowsPage;

  // --- Setting 3: Marquee Titles (Shows Page List) ---
  // --- DEFAULT CHANGED ---
  bool _marqueeTitles = false; // Default to false
  bool get marqueeTitles => _marqueeTitles;

  // --- Setting 4: Show Sort Order ---
  // --- DEFAULT CHANGED ---
  ShowSortOrder _showSortOrder = ShowSortOrder.dateAscending; // Default to oldest first
  ShowSortOrder get showSortOrder => _showSortOrder;

  // --- NEW Setting 5: Marquee Player Title ---
  bool _marqueePlayerTitle = true; // Default to true
  bool get marqueePlayerTitle => _marqueePlayerTitle;

  AlbumSettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    _displayAlbumReleaseNumber = prefs.getBool(_displayOrderKey) ?? false;
    _skipShowsPage = prefs.getBool(_skipShowsPageKey) ?? false;
    // --- Use new default ---
    _marqueeTitles = prefs.getBool(_marqueeTitlesKey) ?? false; 
    // --- Use new default ---
    _marqueePlayerTitle = prefs.getBool(_marqueePlayerTitleKey) ?? true;

    // --- Use new default ---
    final savedSortOrder = prefs.getString(_showSortOrderKey);
    if (savedSortOrder == ShowSortOrder.dateDescending.toString()) {
      _showSortOrder = ShowSortOrder.dateDescending;
    } else {
      _showSortOrder = ShowSortOrder.dateAscending; // Default to ascending
    }
    
    notifyListeners();
  }

  // --- Setters for existing settings ---
  Future<void> setDisplayAlbumReleaseNumber(bool value) async {
    if (_displayAlbumReleaseNumber == value) return;
    _displayAlbumReleaseNumber = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_displayOrderKey, value);
    notifyListeners();
  }

  void toggleDisplayAlbumReleaseNumber() {
    setDisplayAlbumReleaseNumber(!_displayAlbumReleaseNumber);
  }
  
  Future<void> setSkipShowsPage(bool value) async {
    if (_skipShowsPage == value) return;
    _skipShowsPage = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_skipShowsPageKey, value);
    notifyListeners();
  }
  
  Future<void> setMarqueeTitles(bool value) async {
    if (_marqueeTitles == value) return;
    _marqueeTitles = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_marqueeTitlesKey, value);
    notifyListeners();
  }

  Future<void> setShowSortOrder(ShowSortOrder value) async {
    if (_showSortOrder == value) return;
    _showSortOrder = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_showSortOrderKey, value.toString());
    notifyListeners();
  }

  // --- Setter for NEW setting ---
  Future<void> setMarqueePlayerTitle(bool value) async {
    if (_marqueePlayerTitle == value) return;
    _marqueePlayerTitle = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_marqueePlayerTitleKey, value);
    notifyListeners();
  }
}