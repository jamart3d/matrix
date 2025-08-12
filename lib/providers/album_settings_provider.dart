// lib/providers/album_settings_provider.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Preference Keys
const String PREF_SKIP_SHOWS_PAGE = 'skipShowsPage';
const String PREF_MARQUEE_TITLES = 'marqueeTitles';
const String PREF_SHOW_SORT_ORDER = 'showSortOrder';
const String PREF_MARQUEE_PLAYER_TITLE = 'marqueePlayerTitle';
const String PREF_DISPLAY_ALBUM_RELEASE_NUMBER = 'displayAlbumReleaseNumber';
const String PREF_SINGLE_EXPANSION = 'singleExpansion';
const String PREF_SHOW_BUFFER_INFO = 'showBufferInfo'; // NEW KEY

enum ShowSortOrder { dateDescending, dateAscending }

class AlbumSettingsProvider with ChangeNotifier {
  // Private backing fields
  bool _skipShowsPage = false;
  bool _marqueeTitles = true;
  ShowSortOrder _showSortOrder = ShowSortOrder.dateDescending;
  bool _marqueePlayerTitle = true;
  bool _displayAlbumReleaseNumber = true;
  bool _singleExpansion = false;
  bool _showBufferInfo = false; // NEW PROPERTY

  // Public getters
  bool get skipShowsPage => _skipShowsPage;
  bool get marqueeTitles => _marqueeTitles;
  ShowSortOrder get showSortOrder => _showSortOrder;
  bool get marqueePlayerTitle => _marqueePlayerTitle;
  bool get displayAlbumReleaseNumber => _displayAlbumReleaseNumber;
  bool get singleExpansion => _singleExpansion;
  bool get showBufferInfo => _showBufferInfo; // NEW GETTER

  AlbumSettingsProvider() {
    _loadSettings();
  }

  // Load all settings from SharedPreferences
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    _skipShowsPage = prefs.getBool(PREF_SKIP_SHOWS_PAGE) ?? false;
    _marqueeTitles = prefs.getBool(PREF_MARQUEE_TITLES) ?? true;
    _showSortOrder = ShowSortOrder.values[prefs.getInt(PREF_SHOW_SORT_ORDER) ?? 0];
    _marqueePlayerTitle = prefs.getBool(PREF_MARQUEE_PLAYER_TITLE) ?? true;
    _displayAlbumReleaseNumber = prefs.getBool(PREF_DISPLAY_ALBUM_RELEASE_NUMBER) ?? true;
    _singleExpansion = prefs.getBool(PREF_SINGLE_EXPANSION) ?? false;
    _showBufferInfo = prefs.getBool(PREF_SHOW_BUFFER_INFO) ?? false; // LOAD NEW SETTING

    notifyListeners();
  }

  // Setters that update state and persist to SharedPreferences
  Future<void> setSkipShowsPage(bool value) async {
    _skipShowsPage = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PREF_SKIP_SHOWS_PAGE, value);
    notifyListeners();
  }

  Future<void> setMarqueeTitles(bool value) async {
    _marqueeTitles = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PREF_MARQUEE_TITLES, value);
    notifyListeners();
  }

  Future<void> setShowSortOrder(ShowSortOrder value) async {
    _showSortOrder = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(PREF_SHOW_SORT_ORDER, value.index);
    notifyListeners();
  }

  Future<void> setMarqueePlayerTitle(bool value) async {
    _marqueePlayerTitle = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PREF_MARQUEE_PLAYER_TITLE, value);
    notifyListeners();
  }

  Future<void> setDisplayAlbumReleaseNumber(bool value) async {
    _displayAlbumReleaseNumber = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PREF_DISPLAY_ALBUM_RELEASE_NUMBER, value);
    notifyListeners();
  }

  Future<void> setSingleExpansion(bool value) async {
    _singleExpansion = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PREF_SINGLE_EXPANSION, value);
    notifyListeners();
  }

  // NEW SETTER
  Future<void> setShowBufferInfo(bool value) async {
    _showBufferInfo = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PREF_SHOW_BUFFER_INFO, value);
    notifyListeners();
  }
}