// lib/components/matrix_rain/matrix_rain_painter.dart

import 'package:flutter/material.dart';
import 'package:matrix/components/matrix_rain/matrix_rain_column.dart';
import 'package:matrix/providers/enums.dart';

class MatrixRainPainter extends CustomPainter {
  final List<MatrixRainColumn> columns;
  final MatrixTitleStyle titleStyle;
  final MatrixColorTheme colorTheme;
  final double feedbackIntensity;
  final MatrixFillerStyle fillerStyle;
  final MatrixFillerColor fillerColor;
  final MatrixLeadingColor leadingColor;
  final MatrixGlowIntensity glowIntensitySetting;
  final bool isSearching;
  final MatrixFontSize fontSizeSetting;
  final MatrixFontWeight fontWeightSetting;
  final _textPainter = TextPainter(textDirection: TextDirection.ltr);

  static const _palettes = {
    MatrixColorTheme.classicGreen: [ Color(0xFF001a00), Color(0xFF003300), Color(0xFF004d00), Color(0xFF006600), Color(0xFF008000), Color(0xFF009900), Color(0xFF00b300), Color(0xFF00cc00) ],
    MatrixColorTheme.cyanBlue: [ Color(0xFF001a1a), Color(0xFF003333), Color(0xFF004d4d), Color(0xFF006666), Color(0xFF008080), Color(0xFF009999), Color(0xFF00b3b3), Color(0xFF00cccc) ],
    MatrixColorTheme.purpleMatrix: [ Color(0xFF1a001a), Color(0xFF330033), Color(0xFF4d004d), Color(0xFF660066), Color(0xFF800080), Color(0xFF990099), Color(0xFFb300b3), Color(0xFFcc00cc) ],
    MatrixColorTheme.redAlert: [ Color(0xFF1a0000), Color(0xFF330000), Color(0xFF4d0000), Color(0xFF660000), Color(0xFF800000), Color(0xFF990000), Color(0xFFb30000), Color(0xFFcc0000) ],
    MatrixColorTheme.goldLux: [ Color(0xFF332200), Color(0xFF664400), Color(0xFF996600), Color(0xFFcc8800), Color(0xFFffaa00), Color(0xFFffbb33), Color(0xFFffcc66), Color(0xFFffdd99) ],
  };

  static final Map<MatrixFillerColor, Color> _fillerColorMap = {
    MatrixFillerColor.defaultGray: const Color(0xFF282828),
    MatrixFillerColor.green: Colors.green,
    MatrixFillerColor.cyan: Colors.cyan,
    MatrixFillerColor.purple: Colors.purple,
    MatrixFillerColor.red: Colors.red,
    MatrixFillerColor.gold: Colors.amber,
    MatrixFillerColor.white: Colors.grey.shade400,
  };

  static final Map<MatrixLeadingColor, Color> _leadingColorMap = {
    MatrixLeadingColor.white: Colors.white,
    MatrixLeadingColor.green: Colors.green,
    MatrixLeadingColor.cyan: Colors.cyan,
    MatrixLeadingColor.purple: Colors.purpleAccent,
    MatrixLeadingColor.red: Colors.redAccent,
    MatrixLeadingColor.gold: Colors.amber,
  };

  MatrixRainPainter({
    required this.columns,
    required this.titleStyle,
    required this.colorTheme,
    required this.feedbackIntensity,
    required this.fillerStyle,
    required this.fillerColor,
    required this.leadingColor,
    required this.glowIntensitySetting,
    required this.isSearching,
    required this.fontSizeSetting,
    required this.fontWeightSetting,
  });

  List<Color> _generateFillerShades(Color baseColor) {
    return List.generate(8, (i) {
      final t = (i / 7) * 0.5 + 0.2;
      return Color.lerp(Colors.black, baseColor, t)!;
    });
  }

  double _getIntensityMultiplier() {
    switch (glowIntensitySetting) {
      case MatrixGlowIntensity.half: return 0.5;
      case MatrixGlowIntensity.double: return 2.0;
      case MatrixGlowIntensity.normal:
      default: return 1.0;
    }
  }

  double _getFontSize() {
    switch (fontSizeSetting) {
      case MatrixFontSize.small: return 12.0;
      case MatrixFontSize.large: return 20.0;
      case MatrixFontSize.medium:
      default: return 16.0;
    }
  }

  FontWeight _getFontWeight() {
    return fontWeightSetting == MatrixFontWeight.bold ? FontWeight.bold : FontWeight.normal;
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final column in columns) {
      if (isSearching && !column.isHighlighted) {
        continue;
      }

      if (column.rippleEffect > 0) _drawRippleEffect(canvas, column);
      for (int i = 0; i < column.characters.length; i++) {
        final yOffset = column.yPosition + (i * column.textHeight);
        if (yOffset + column.textHeight < 0 || yOffset > size.height) continue;

        if (i == column.characters.length - 1) {
          _paintLeadingCharacter(canvas, column, yOffset, size);
        } else {
          _paintBodyCharacter(canvas, column, i, yOffset);
        }
      }
    }
  }

  void _paintLeadingCharacter(Canvas canvas, MatrixRainColumn column, double yOffset, Size size) {
    Color charColor;
    double fontSize;
    List<Shadow> shadows = [];
    final intensityMultiplier = _getIntensityMultiplier();
    final baseFontSize = _getFontSize();

    if (column.isCurrentlyPlaying) {
      charColor = Colors.yellow;
      fontSize = baseFontSize * 1.1;
      final glow = column.glowIntensity * feedbackIntensity;
      shadows = [
        Shadow(color: Colors.yellow.withOpacity(0.9 * glow), blurRadius: 25 * glow * intensityMultiplier),
        Shadow(color: Colors.orange.withOpacity(0.7 * glow), blurRadius: 40 * glow * intensityMultiplier)
      ];
    } else {
      charColor = _leadingColorMap[leadingColor]!;
      fontSize = baseFontSize;
      shadows = [
        Shadow(color: charColor.withOpacity(0.9), blurRadius: 12 * intensityMultiplier),
        Shadow(color: charColor.withOpacity(0.5), blurRadius: 20 * intensityMultiplier)
      ];
    }

    final screenThird = size.height / 3;
    final startDimY = screenThird * 2;
    if (column.yPosition > startDimY) {
      final dimProgress = (column.yPosition - startDimY) / screenThird;
      charColor = Color.lerp(charColor, Colors.grey.shade800, dimProgress.clamp(0.0, 1.0))!;
    }

    _paintChar(canvas, column.characters.last, column.xPosition, yOffset, charColor, fontSize, FontWeight.bold, shadows, column.rippleEffect);
  }

  void _paintBodyCharacter(Canvas canvas, MatrixRainColumn column, int index, double yOffset) {
    final isFiller = column.isRandomFiller(index);
    if (isFiller && fillerStyle == MatrixFillerStyle.invisible) return;

    List<Color> shades;
    if (isFiller) {
      shades = (fillerStyle == MatrixFillerStyle.dimmed) ? _generateFillerShades(_fillerColorMap[fillerColor]!) : _palettes[colorTheme]!;
    } else {
      shades = _palettes[colorTheme]!;
    }

    Color charColor;
    final intensityMultiplier = _getIntensityMultiplier();

    switch (titleStyle) {
      case MatrixTitleStyle.random:
        final cIndex = (shades.length - 1) - (index % shades.length);
        charColor = shades[cIndex];
        break;

      case MatrixTitleStyle.gradient:
        final gradPos = index / (column.characters.length - 2).clamp(1, double.infinity);
        final cIndex = (gradPos * (shades.length - 1)).round().clamp(0, shades.length - 1);
        charColor = shades[cIndex];
        break;

      case MatrixTitleStyle.solid:
        charColor = shades[(shades.length * 0.7).floor()];
        break;
    }

    List<Shadow> shadows = [];
    if (!isFiller) {
      if (column.isCurrentlyPlaying) {
        final glow = column.glowIntensity * feedbackIntensity;
        shadows = [Shadow(color: charColor.withOpacity(0.6 * glow), blurRadius: 10 * glow * intensityMultiplier)];
      }
      else {
        shadows = [
          Shadow(color: charColor.withOpacity(0.8), blurRadius: 8 * intensityMultiplier),
          Shadow(color: charColor.withOpacity(0.4), blurRadius: 16 * intensityMultiplier)
        ];
      }
    }
    _paintChar(canvas, column.characters[index], column.xPosition, yOffset, charColor, _getFontSize(), _getFontWeight(), shadows, column.rippleEffect);
  }

  void _paintChar(Canvas canvas, String char, double x, double y, Color color, double fontSize, FontWeight weight, List<Shadow> shadows, double rippleEffect) {
    if (rippleEffect > 0) color = Color.lerp(color, Colors.white, rippleEffect * 0.5 * feedbackIntensity) ?? color;
    _textPainter.text = TextSpan(
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: fontSize,
          color: color,
          fontWeight: weight,
          shadows: shadows,
        ),
        text: char);
    _textPainter.layout();
    _textPainter.paint(canvas, Offset(x, y));
  }

  void _drawRippleEffect(Canvas canvas, MatrixRainColumn column) {
    final baseRippleColor = _palettes[colorTheme]![(_palettes[colorTheme]!.length * 0.7).floor()];
    final paint = Paint()..color = baseRippleColor.withOpacity(0.3 * column.rippleEffect * feedbackIntensity)..style = PaintingStyle.stroke..strokeWidth = 2.0 * (1.0 - column.rippleEffect + 0.5);
    final center = Offset(column.xPosition + 8, column.yPosition + (column.characters.length * 10));
    final radius = 50 * (1 - column.rippleEffect);
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}