// lib/utils/theme_helper.dart

import 'package:flutter/material.dart';
import 'package:matrix/providers/enums.dart';

/// Gets the primary color for a given Matrix theme.
Color getThemeColor(MatrixColorTheme theme) {
  switch (theme) {
    case MatrixColorTheme.cyanBlue:
      return Colors.cyan;
    case MatrixColorTheme.purpleMatrix:
      return Colors.purpleAccent;
    case MatrixColorTheme.redAlert:
      return Colors.redAccent;
    case MatrixColorTheme.goldLux:
      return Colors.amber;
    case MatrixColorTheme.classicGreen:
    default:
      return Colors.green;
  }
}

/// Gets the dark, deep background color for a given Matrix theme.
Color getDarkThemeColor(MatrixColorTheme theme) {
  switch (theme) {
    case MatrixColorTheme.cyanBlue:
      return const Color(0xFF001a1a);
    case MatrixColorTheme.purpleMatrix:
      return const Color(0xFF1a001a);
    case MatrixColorTheme.redAlert:
      return const Color(0xFF1a0000);
    case MatrixColorTheme.goldLux:
      return const Color(0xFF332200);
    case MatrixColorTheme.classicGreen:
    default:
      return const Color(0xFF001a00);
  }
}

/// Gets a brighter accent color for shadows and highlights for a given Matrix theme.
Color getThemeAccentColor(MatrixColorTheme theme) {
  switch (theme) {
    case MatrixColorTheme.cyanBlue:
      return Colors.cyanAccent;
    case MatrixColorTheme.purpleMatrix:
      return Colors.pinkAccent;
    case MatrixColorTheme.redAlert:
      return Colors.red;
    case MatrixColorTheme.goldLux:
      return Colors.yellow;
    case MatrixColorTheme.classicGreen:
    default:
      return Colors.greenAccent;
  }
}