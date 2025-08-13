// lib/providers/album_settings_provider.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';

enum ShowSortOrder { dateDescending, dateAscending }

class AlbumSettingsProvider with ChangeNotifier {
  final _logger = Logger();

  // --- KEYS for SharedPreferences ---
  static const String _skipShowsPageKey = 'skipShowsPage';
  static const String _marqueeTitlesKey = 'marqueeTitles';
  static const String _singleExpansionKey = 'singleExpansion';
  static const String _showYearScrollbarKey = 'showYearScrollbar';
  static const String _showSortOrderKey = 'showSortOrder';
  static const String _marqueePlayerTitleKey = 'marqueePlayerTitle';
  static const String _displayAlbumReleaseNumberKey = 'displayAlbumReleaseNumber';
  static const String _matrixRainSpeedKey = 'matrixRainSpeed';
  // --- KEY RESTORED ---
  static const String _showBufferInfoKey = 'showBufferInfo';

  // --- SETTINGS PROPERTIES ---
  bool _skipShowsPage = false;
  bool _marqueeTitles = true;
  bool _singleExpansion = true;
  bool _showYearScrollbar = true;
  ShowSortOrder _showSortOrder = ShowSortOrder.dateDescending;
  bool _marqueePlayerTitle = true;
  bool _displayAlbumReleaseNumber = false;
  double _matrixRainSpeed = 5.0;
  // --- PROPERTY RESTORED ---
  bool _showBufferInfo = false;

  // --- GETTERS ---
  bool get skipShowsPage => _skipShowsPage;
  bool get marqueeTitles => _marqueeTitles;
  bool get singleExpansion => _singleExpansion;
  bool get showYearScrollbar => _showYearScrollbar;
  ShowSortOrder get showSortOrder => _showSortOrder;
  bool get marqueePlayerTitle => _marqueePlayerTitle;
  bool get displayAlbumReleaseNumber => _displayAlbumReleaseNumber;
  double get matrixRainSpeed => _matrixRainSpeed;
  // --- GETTER RESTORED ---
  bool get showBufferInfo => _showBufferInfo;

  AlbumSettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _logger.i("Loading settings from SharedPreferences...");
    final prefs = await SharedPreferences.getInstance();
    _skipShowsPage = prefs.getBool(_skipShowsPageKey) ?? false;
    _marqueeTitles = prefs.getBool(_marqueeTitlesKey) ?? true;
    _singleExpansion = prefs.getBool(_singleExpansionKey) ?? true;
    _showYearScrollbar = prefs.getBool(_showYearScrollbarKey) ?? true;
    _showSortOrder = ShowSortOrder.values[prefs.getInt(_showSortOrderKey) ?? 0];
    _marqueePlayerTitle = prefs.getBool(_marqueePlayerTitleKey) ?? true;
    _displayAlbumReleaseNumber = prefs.getBool(_displayAlbumReleaseNumberKey) ?? false;
    _matrixRainSpeed = prefs.getDouble(_matrixRainSpeedKey) ?? 5.0;
    // --- LOADING LOGIC RESTORED ---
    _showBufferInfo = prefs.getBool(_showBufferInfoKey) ?? false;

    notifyListeners();
  }

  // --- SETTERS ---

  // ... (all other setters remain the same) ...
  Future<void> setSkipShowsPage(bool value) async {
    _skipShowsPage = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_skipShowsPageKey, value);
    notifyListeners();
  }

  Future<void> setDisplayAlbumReleaseNumber(bool value) async {
    _displayAlbumReleaseNumber = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_displayAlbumReleaseNumberKey, value);
    notifyListeners();
  }

  Future<void> setMatrixRainSpeed(double value) async {
    _matrixRainSpeed = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_matrixRainSpeedKey, value);
    notifyListeners();
  }

  // --- SETTER RESTORED ---
  Future<void> setShowBufferInfo(bool value) async {
    _showBufferInfo = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showBufferInfoKey, value);
    notifyListeners();
  }

  Future<void> setMarqueeTitles(bool value) async {
    _marqueeTitles = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_marqueeTitlesKey, value);
    notifyListeners();
  }

  Future<void> setSingleExpansion(bool value) async {
    _singleExpansion = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_singleExpansionKey, value);
    notifyListeners();
  }

  Future<void> setShowYearScrollbar(bool value) async {
    _showYearScrollbar = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showYearScrollbarKey, value);
    notifyListeners();
  }

  Future<void> setShowSortOrder(ShowSortOrder value) async {
    _showSortOrder = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_showSortOrderKey, value.index);
    notifyListeners();
  }

  Future<void> setMarqueePlayerTitle(bool value) async {
    _marqueePlayerTitle = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_marqueePlayerTitleKey, value);
    notifyListeners();
  }
}