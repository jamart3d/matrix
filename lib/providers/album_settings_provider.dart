// lib/providers/album_settings_provider.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';

// --- ENUMS for settings choices ---
enum ShowSortOrder { dateDescending, dateAscending }
enum YearScrollbarBehavior { onScroll, always, off }
enum MatrixColorTheme { classicGreen, cyanBlue, purpleMatrix, redAlert, goldLux }
enum MatrixTitleStyle { random, gradient, solid }
enum MatrixFillerStyle { dimmed, themed, invisible }
enum MatrixFillerColor { defaultGray, green, cyan, purple, red, gold, white }
enum StartupPage { shows, albums, matrix }
enum MatrixGlowStyle { all, current, none }
enum MatrixLeadingColor { white, green, cyan, purple, red, gold }

class AlbumSettingsProvider with ChangeNotifier {
  final _logger = Logger();

  // --- KEYS for SharedPreferences ---
  static const String _startupPageKey = 'startupPage';
  static const String _yearScrollbarBehaviorKey = 'yearScrollbarBehavior';
  static const String _showSortOrderKey = 'showSortOrder';
  static const String _marqueePlayerTitleKey = 'marqueePlayerTitle';
  static const String _displayAlbumReleaseNumberKey = 'displayAlbumReleaseNumber';
  static const String _matrixRainSpeedKey = 'matrixRainSpeed';
  static const String _showBufferInfoKey = 'showBufferInfo';
  static const String _matrixGlowStyleKey = 'matrixGlowStyle';
  static const String _matrixRippleEffectsKey = 'matrixRippleEffects';
  static const String _matrixTitleStyleKey = 'matrixTitleStyle';
  static const String _matrixColorThemeKey = 'matrixColorTheme';
  static const String _matrixColumnLimitKey = 'matrixColumnLimit';
  static const String _matrixFeedbackIntensityKey = 'matrixFeedbackIntensity';
  static const String _matrixFillerStyleKey = 'matrixFillerStyle';
  static const String _matrixFillerColorKey = 'matrixFillerColor';
  static const String _matrixLeadingColorKey = 'matrixLeadingColor';
  // Old keys for migration
  static const String _oldSkipShowsPageKey = 'skipShowsPage';
  static const String _oldMatrixGlowEffectsKey = 'matrixGlowEffects';

  // --- SETTINGS PROPERTIES with default values ---
  StartupPage _startupPage = StartupPage.shows;
  YearScrollbarBehavior _yearScrollbarBehavior = YearScrollbarBehavior.onScroll;
  ShowSortOrder _showSortOrder = ShowSortOrder.dateDescending;
  bool _marqueePlayerTitle = true;
  bool _displayAlbumReleaseNumber = false;
  double _matrixRainSpeed = 1.0;
  bool _showBufferInfo = false;
  MatrixGlowStyle _matrixGlowStyle = MatrixGlowStyle.current;
  bool _matrixRippleEffects = true;
  MatrixTitleStyle _matrixTitleStyle = MatrixTitleStyle.random;
  MatrixColorTheme _matrixColorTheme = MatrixColorTheme.classicGreen;
  int _matrixColumnLimit = 50;
  double _matrixFeedbackIntensity = 1.0;
  MatrixFillerStyle _matrixFillerStyle = MatrixFillerStyle.dimmed;
  MatrixFillerColor _matrixFillerColor = MatrixFillerColor.defaultGray;
  MatrixLeadingColor _matrixLeadingColor = MatrixLeadingColor.white;

  // --- PUBLIC GETTERS ---
  StartupPage get startupPage => _startupPage;
  YearScrollbarBehavior get yearScrollbarBehavior => _yearScrollbarBehavior;
  ShowSortOrder get showSortOrder => _showSortOrder;
  bool get marqueePlayerTitle => _marqueePlayerTitle;
  bool get displayAlbumReleaseNumber => _displayAlbumReleaseNumber;
  double get matrixRainSpeed => _matrixRainSpeed;
  bool get showBufferInfo => _showBufferInfo;
  MatrixGlowStyle get matrixGlowStyle => _matrixGlowStyle;
  bool get matrixRippleEffects => _matrixRippleEffects;
  MatrixTitleStyle get matrixTitleStyle => _matrixTitleStyle;
  MatrixColorTheme get matrixColorTheme => _matrixColorTheme;
  int get matrixColumnLimit => _matrixColumnLimit;
  double get matrixFeedbackIntensity => _matrixFeedbackIntensity;
  MatrixFillerStyle get matrixFillerStyle => _matrixFillerStyle;
  MatrixFillerColor get matrixFillerColor => _matrixFillerColor;
  MatrixLeadingColor get matrixLeadingColor => _matrixLeadingColor;

  AlbumSettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _logger.i("Loading settings from SharedPreferences...");
    final prefs = await SharedPreferences.getInstance();

    // --- MIGRATION LOGIC ---
    if (prefs.containsKey(_oldSkipShowsPageKey)) {
      final bool oldSkipShows = prefs.getBool(_oldSkipShowsPageKey) ?? false;
      _startupPage = oldSkipShows ? StartupPage.albums : StartupPage.shows;
      await prefs.setInt(_startupPageKey, _startupPage.index);
      await prefs.remove(_oldSkipShowsPageKey);
    }
    if (prefs.containsKey(_oldMatrixGlowEffectsKey)) {
      final bool oldGlow = prefs.getBool(_oldMatrixGlowEffectsKey) ?? true;
      _matrixGlowStyle = oldGlow ? MatrixGlowStyle.current : MatrixGlowStyle.none;
      await prefs.setInt(_matrixGlowStyleKey, _matrixGlowStyle.index);
      await prefs.remove(_oldMatrixGlowEffectsKey);
    }

    // --- LOAD ALL SETTINGS ---
    _startupPage = StartupPage.values[prefs.getInt(_startupPageKey) ?? _startupPage.index];
    _yearScrollbarBehavior = YearScrollbarBehavior.values[prefs.getInt(_yearScrollbarBehaviorKey) ?? _yearScrollbarBehavior.index];
    _showSortOrder = ShowSortOrder.values[prefs.getInt(_showSortOrderKey) ?? _showSortOrder.index];
    _marqueePlayerTitle = prefs.getBool(_marqueePlayerTitleKey) ?? _marqueePlayerTitle;
    _displayAlbumReleaseNumber = prefs.getBool(_displayAlbumReleaseNumberKey) ?? _displayAlbumReleaseNumber;
    _matrixRainSpeed = prefs.getDouble(_matrixRainSpeedKey) ?? _matrixRainSpeed;
    _showBufferInfo = prefs.getBool(_showBufferInfoKey) ?? _showBufferInfo;
    _matrixGlowStyle = MatrixGlowStyle.values[prefs.getInt(_matrixGlowStyleKey) ?? _matrixGlowStyle.index];
    _matrixRippleEffects = prefs.getBool(_matrixRippleEffectsKey) ?? _matrixRippleEffects;
    _matrixTitleStyle = MatrixTitleStyle.values[prefs.getInt(_matrixTitleStyleKey) ?? _matrixTitleStyle.index];
    _matrixColorTheme = MatrixColorTheme.values[prefs.getInt(_matrixColorThemeKey) ?? _matrixColorTheme.index];
    _matrixColumnLimit = prefs.getInt(_matrixColumnLimitKey) ?? _matrixColumnLimit;
    _matrixFeedbackIntensity = prefs.getDouble(_matrixFeedbackIntensityKey) ?? _matrixFeedbackIntensity;
    _matrixFillerStyle = MatrixFillerStyle.values[prefs.getInt(_matrixFillerStyleKey) ?? _matrixFillerStyle.index];
    _matrixFillerColor = MatrixFillerColor.values[prefs.getInt(_matrixFillerColorKey) ?? _matrixFillerColor.index];
    _matrixLeadingColor = MatrixLeadingColor.values[prefs.getInt(_matrixLeadingColorKey) ?? _matrixLeadingColor.index];

    notifyListeners();
  }

  Future<void> _updateValue<T>(String key, T value, void Function() updateState) async {
    updateState();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    try {
      if (value is bool) await prefs.setBool(key, value);
      else if (value is int) await prefs.setInt(key, value);
      else if (value is double) await prefs.setDouble(key, value);
      else if (value is String) await prefs.setString(key, value);
    } catch (e) {
      _logger.e("Failed to save setting '$key': $e");
    }
  }

  // --- PUBLIC SETTERS ---
  void setStartupPage(StartupPage v) => _updateValue(_startupPageKey, v.index, () => _startupPage = v);
  void setYearScrollbarBehavior(YearScrollbarBehavior v) => _updateValue(_yearScrollbarBehaviorKey, v.index, () => _yearScrollbarBehavior = v);
  void setShowSortOrder(ShowSortOrder v) => _updateValue(_showSortOrderKey, v.index, () => _showSortOrder = v);
  void setMarqueePlayerTitle(bool v) => _updateValue(_marqueePlayerTitleKey, v, () => _marqueePlayerTitle = v);
  void setDisplayAlbumReleaseNumber(bool v) => _updateValue(_displayAlbumReleaseNumberKey, v, () => _displayAlbumReleaseNumber = v);
  void setMatrixRainSpeed(double v) => _updateValue(_matrixRainSpeedKey, v, () => _matrixRainSpeed = v);
  void setShowBufferInfo(bool v) => _updateValue(_showBufferInfoKey, v, () => _showBufferInfo = v);
  void setMatrixGlowStyle(MatrixGlowStyle v) => _updateValue(_matrixGlowStyleKey, v.index, () => _matrixGlowStyle = v);
  void setMatrixRippleEffects(bool v) => _updateValue(_matrixRippleEffectsKey, v, () => _matrixRippleEffects = v);
  void setMatrixTitleStyle(MatrixTitleStyle v) => _updateValue(_matrixTitleStyleKey, v.index, () => _matrixTitleStyle = v);
  void setMatrixColorTheme(MatrixColorTheme v) => _updateValue(_matrixColorThemeKey, v.index, () => _matrixColorTheme = v);
  void setMatrixColumnLimit(int v) => _updateValue(_matrixColumnLimitKey, v, () => _matrixColumnLimit = v);
  void setMatrixFeedbackIntensity(double v) => _updateValue(_matrixFeedbackIntensityKey, v, () => _matrixFeedbackIntensity = v);
  void setMatrixFillerStyle(MatrixFillerStyle v) => _updateValue(_matrixFillerStyleKey, v.index, () => _matrixFillerStyle = v);
  void setMatrixFillerColor(MatrixFillerColor v) => _updateValue(_matrixFillerColorKey, v.index, () => _matrixFillerColor = v);
  void setMatrixLeadingColor(MatrixLeadingColor v) => _updateValue(_matrixLeadingColorKey, v.index, () => _matrixLeadingColor = v);
}