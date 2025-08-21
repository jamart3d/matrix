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
enum MatrixGlowIntensity { half, normal, double }
enum MatrixLeadingColor { white, green, cyan, purple, red, gold }
enum MatrixStepMode { smooth, stepped, chunky }
enum MatrixLaneSpacing { standard, tight, overlap }
enum FabSize { normal, large }
enum MatrixFontWeight { normal, bold }
enum MatrixFontSize { small, medium, large }

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
  static const String _matrixGlowIntensityKey = 'matrixGlowIntensity';
  static const String _matrixRippleEffectsKey = 'matrixRippleEffects';
  static const String _matrixTitleStyleKey = 'matrixTitleStyle';
  static const String _matrixColorThemeKey = 'matrixColorTheme';
  static const String _matrixColumnLimitKey = 'matrixColumnLimit';
  static const String _matrixFeedbackIntensityKey = 'matrixFeedbackIntensity';
  static const String _matrixFillerStyleKey = 'matrixFillerStyle';
  static const String _matrixFillerColorKey = 'matrixFillerColor';
  static const String _matrixLeadingColorKey = 'matrixLeadingColor';
  static const String _matrixChaoticLeadingKey = 'matrixChaoticLeading';
  static const String _matrixStepModeKey = 'matrixStepMode';
  static const String _matrixLaneSpacingKey = 'matrixLaneSpacing';
  static const String _matrixAllowOverlapKey = 'matrixAllowOverlap';
  static const String _fabSizeKey = 'fabSize';
  static const String _matrixFontWeightKey = 'matrixFontWeight';
  static const String _matrixFontSizeKey = 'matrixFontSize';
  static const String _isGeneralExpandedKey = 'isGeneralExpanded';
  static const String _isShowsExpandedKey = 'isShowsExpanded';
  static const String _isPlayerExpandedKey = 'isPlayerExpanded';
  static const String _isHunterExpandedKey = 'isHunterExpanded';
  static const String _isMatrixExpandedKey = 'isMatrixExpanded';
  static const String _matrixHalfSpeedKey = 'matrixHalfSpeed';

  // --- SETTINGS PROPERTIES with default values ---
  StartupPage _startupPage = StartupPage.shows;
  YearScrollbarBehavior _yearScrollbarBehavior = YearScrollbarBehavior.onScroll;
  ShowSortOrder _showSortOrder = ShowSortOrder.dateDescending;
  bool _marqueePlayerTitle = true;
  bool _displayAlbumReleaseNumber = false;
  double _matrixRainSpeed = 1.0;
  bool _showBufferInfo = false;
  MatrixGlowIntensity _matrixGlowIntensity = MatrixGlowIntensity.normal;
  bool _matrixRippleEffects = true;
  MatrixTitleStyle _matrixTitleStyle = MatrixTitleStyle.random;
  MatrixColorTheme _matrixColorTheme = MatrixColorTheme.classicGreen;
  int _matrixColumnLimit = 50;
  double _matrixFeedbackIntensity = 1.0;
  MatrixFillerStyle _matrixFillerStyle = MatrixFillerStyle.dimmed;
  MatrixFillerColor _matrixFillerColor = MatrixFillerColor.defaultGray;
  MatrixLeadingColor _matrixLeadingColor = MatrixLeadingColor.white;
  bool _matrixChaoticLeading = false;
  MatrixStepMode _matrixStepMode = MatrixStepMode.stepped;
  MatrixLaneSpacing _matrixLaneSpacing = MatrixLaneSpacing.standard;
  bool _matrixAllowOverlap = false;
  FabSize _fabSize = FabSize.normal;
  MatrixFontWeight _matrixFontWeight = MatrixFontWeight.normal;
  MatrixFontSize _matrixFontSize = MatrixFontSize.medium;
  bool _isGeneralExpanded = true;
  bool _isShowsExpanded = true;
  bool _isPlayerExpanded = true;
  bool _isHunterExpanded = true;
  bool _isMatrixExpanded = true;
  bool _matrixHalfSpeed = false;

  // --- PUBLIC GETTERS ---
  StartupPage get startupPage => _startupPage;
  YearScrollbarBehavior get yearScrollbarBehavior => _yearScrollbarBehavior;
  ShowSortOrder get showSortOrder => _showSortOrder;
  bool get marqueePlayerTitle => _marqueePlayerTitle;
  bool get displayAlbumReleaseNumber => _displayAlbumReleaseNumber;
  double get matrixRainSpeed => _matrixRainSpeed;
  bool get showBufferInfo => _showBufferInfo;
  MatrixGlowIntensity get matrixGlowIntensity => _matrixGlowIntensity;
  bool get matrixRippleEffects => _matrixRippleEffects;
  MatrixTitleStyle get matrixTitleStyle => _matrixTitleStyle;
  MatrixColorTheme get matrixColorTheme => _matrixColorTheme;
  int get matrixColumnLimit => _matrixColumnLimit;
  double get matrixFeedbackIntensity => _matrixFeedbackIntensity;
  MatrixFillerStyle get matrixFillerStyle => _matrixFillerStyle;
  MatrixFillerColor get matrixFillerColor => _matrixFillerColor;
  MatrixLeadingColor get matrixLeadingColor => _matrixLeadingColor;
  bool get matrixChaoticLeading => _matrixChaoticLeading;
  MatrixStepMode get matrixStepMode => _matrixStepMode;
  MatrixLaneSpacing get matrixLaneSpacing => _matrixLaneSpacing;
  bool get matrixAllowOverlap => _matrixAllowOverlap;
  FabSize get fabSize => _fabSize;
  MatrixFontWeight get matrixFontWeight => _matrixFontWeight;
  MatrixFontSize get matrixFontSize => _matrixFontSize;
  bool get isGeneralExpanded => _isGeneralExpanded;
  bool get isShowsExpanded => _isShowsExpanded;
  bool get isPlayerExpanded => _isPlayerExpanded;
  bool get isHunterExpanded => _isHunterExpanded;
  bool get isMatrixExpanded => _isMatrixExpanded;
  bool get matrixHalfSpeed => _matrixHalfSpeed;

  AlbumSettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _logger.i("Loading settings from SharedPreferences...");
    final prefs = await SharedPreferences.getInstance();

    _startupPage = StartupPage.values[prefs.getInt(_startupPageKey) ?? _startupPage.index];
    _yearScrollbarBehavior = YearScrollbarBehavior.values[prefs.getInt(_yearScrollbarBehaviorKey) ?? _yearScrollbarBehavior.index];
    _showSortOrder = ShowSortOrder.values[prefs.getInt(_showSortOrderKey) ?? _showSortOrder.index];
    _marqueePlayerTitle = prefs.getBool(_marqueePlayerTitleKey) ?? _marqueePlayerTitle;
    _displayAlbumReleaseNumber = prefs.getBool(_displayAlbumReleaseNumberKey) ?? _displayAlbumReleaseNumber;
    _matrixRainSpeed = prefs.getDouble(_matrixRainSpeedKey) ?? _matrixRainSpeed;
    _showBufferInfo = prefs.getBool(_showBufferInfoKey) ?? _showBufferInfo;
    _matrixGlowIntensity = MatrixGlowIntensity.values[prefs.getInt(_matrixGlowIntensityKey) ?? _matrixGlowIntensity.index];
    _matrixRippleEffects = prefs.getBool(_matrixRippleEffectsKey) ?? _matrixRippleEffects;
    _matrixTitleStyle = MatrixTitleStyle.values[prefs.getInt(_matrixTitleStyleKey) ?? _matrixTitleStyle.index];
    _matrixColorTheme = MatrixColorTheme.values[prefs.getInt(_matrixColorThemeKey) ?? _matrixColorTheme.index];
    _matrixColumnLimit = prefs.getInt(_matrixColumnLimitKey) ?? _matrixColumnLimit;
    _matrixFeedbackIntensity = prefs.getDouble(_matrixFeedbackIntensityKey) ?? _matrixFeedbackIntensity;
    _matrixFillerStyle = MatrixFillerStyle.values[prefs.getInt(_matrixFillerStyleKey) ?? _matrixFillerStyle.index];
    _matrixFillerColor = MatrixFillerColor.values[prefs.getInt(_matrixFillerColorKey) ?? _matrixFillerColor.index];
    _matrixLeadingColor = MatrixLeadingColor.values[prefs.getInt(_matrixLeadingColorKey) ?? _matrixLeadingColor.index];
    _matrixChaoticLeading = prefs.getBool(_matrixChaoticLeadingKey) ?? _matrixChaoticLeading;
    _matrixStepMode = MatrixStepMode.values[prefs.getInt(_matrixStepModeKey) ?? _matrixStepMode.index];
    _matrixLaneSpacing = MatrixLaneSpacing.values[prefs.getInt(_matrixLaneSpacingKey) ?? _matrixLaneSpacing.index];
    _matrixAllowOverlap = prefs.getBool(_matrixAllowOverlapKey) ?? _matrixAllowOverlap;
    _fabSize = FabSize.values[prefs.getInt(_fabSizeKey) ?? _fabSize.index];
    _matrixFontWeight = MatrixFontWeight.values[prefs.getInt(_matrixFontWeightKey) ?? _matrixFontWeight.index];
    _matrixFontSize = MatrixFontSize.values[prefs.getInt(_matrixFontSizeKey) ?? _matrixFontSize.index];
    _isGeneralExpanded = prefs.getBool(_isGeneralExpandedKey) ?? _isGeneralExpanded;
    _isShowsExpanded = prefs.getBool(_isShowsExpandedKey) ?? _isShowsExpanded;
    _isPlayerExpanded = prefs.getBool(_isPlayerExpandedKey) ?? _isPlayerExpanded;
    _isHunterExpanded = prefs.getBool(_isHunterExpandedKey) ?? _isHunterExpanded;
    _isMatrixExpanded = prefs.getBool(_isMatrixExpandedKey) ?? _isMatrixExpanded;
    _matrixHalfSpeed = prefs.getBool(_matrixHalfSpeedKey) ?? _matrixHalfSpeed;

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
    } catch (e) {
      _logger.e("Failed to save setting '$key': $e");
    }
  }

  void setStartupPage(StartupPage v) => _updateValue(_startupPageKey, v.index, () => _startupPage = v);
  void setYearScrollbarBehavior(YearScrollbarBehavior v) => _updateValue(_yearScrollbarBehaviorKey, v.index, () => _yearScrollbarBehavior = v);
  void setShowSortOrder(ShowSortOrder v) => _updateValue(_showSortOrderKey, v.index, () => _showSortOrder = v);
  void setMarqueePlayerTitle(bool v) => _updateValue(_marqueePlayerTitleKey, v, () => _marqueePlayerTitle = v);
  void setDisplayAlbumReleaseNumber(bool v) => _updateValue(_displayAlbumReleaseNumberKey, v, () => _displayAlbumReleaseNumber = v);
  void setMatrixRainSpeed(double v) => _updateValue(_matrixRainSpeedKey, v, () => _matrixRainSpeed = v);
  void setShowBufferInfo(bool v) => _updateValue(_showBufferInfoKey, v, () => _showBufferInfo = v);
  void setMatrixGlowIntensity(MatrixGlowIntensity v) => _updateValue(_matrixGlowIntensityKey, v.index, () => _matrixGlowIntensity = v);
  void setMatrixRippleEffects(bool v) => _updateValue(_matrixRippleEffectsKey, v, () => _matrixRippleEffects = v);
  void setMatrixTitleStyle(MatrixTitleStyle v) => _updateValue(_matrixTitleStyleKey, v.index, () => _matrixTitleStyle = v);
  void setMatrixColorTheme(MatrixColorTheme v) => _updateValue(_matrixColorThemeKey, v.index, () => _matrixColorTheme = v);
  void setMatrixColumnLimit(int v) => _updateValue(_matrixColumnLimitKey, v, () => _matrixColumnLimit = v);
  void setMatrixFeedbackIntensity(double v) => _updateValue(_matrixFeedbackIntensityKey, v, () => _matrixFeedbackIntensity = v);
  void setMatrixFillerStyle(MatrixFillerStyle v) => _updateValue(_matrixFillerStyleKey, v.index, () => _matrixFillerStyle = v);
  void setMatrixFillerColor(MatrixFillerColor v) => _updateValue(_matrixFillerColorKey, v.index, () => _matrixFillerColor = v);
  void setMatrixLeadingColor(MatrixLeadingColor v) => _updateValue(_matrixLeadingColorKey, v.index, () => _matrixLeadingColor = v);
  void setMatrixChaoticLeading(bool v) => _updateValue(_matrixChaoticLeadingKey, v, () => _matrixChaoticLeading = v);
  void setMatrixStepMode(MatrixStepMode v) => _updateValue(_matrixStepModeKey, v.index, () => _matrixStepMode = v);
  void setMatrixLaneSpacing(MatrixLaneSpacing v) => _updateValue(_matrixLaneSpacingKey, v.index, () => _matrixLaneSpacing = v);
  void setMatrixAllowOverlap(bool v) => _updateValue(_matrixAllowOverlapKey, v, () => _matrixAllowOverlap = v);
  void setFabSize(FabSize v) => _updateValue(_fabSizeKey, v.index, () => _fabSize = v);
  void setMatrixFontWeight(MatrixFontWeight v) => _updateValue(_matrixFontWeightKey, v.index, () => _matrixFontWeight = v);
  void setMatrixFontSize(MatrixFontSize v) => _updateValue(_matrixFontSizeKey, v.index, () => _matrixFontSize = v);
  void setGeneralExpanded(bool v) => _updateValue(_isGeneralExpandedKey, v, () => _isGeneralExpanded = v);
  void setShowsExpanded(bool v) => _updateValue(_isShowsExpandedKey, v, () => _isShowsExpanded = v);
  void setPlayerExpanded(bool v) => _updateValue(_isPlayerExpandedKey, v, () => _isPlayerExpanded = v);
  void setHunterExpanded(bool v) => _updateValue(_isHunterExpandedKey, v, () => _isHunterExpanded = v);
  void setMatrixExpanded(bool v) => _updateValue(_isMatrixExpandedKey, v, () => _isMatrixExpanded = v);
  void setMatrixHalfSpeed(bool v) => _updateValue(_matrixHalfSpeedKey, v, () => _matrixHalfSpeed = v);
}