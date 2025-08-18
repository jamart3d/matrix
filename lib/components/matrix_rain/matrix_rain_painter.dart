// lib/components/matrix_rain/matrix_rain_painter.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:matrix/components/matrix_rain/matrix_rain_column.dart';
import 'package:matrix/providers/album_settings_provider.dart';

class MatrixRainPainter extends CustomPainter {
  final List<MatrixRainColumn> columns;
  final MatrixTitleStyle titleStyle;
  final MatrixColorTheme colorTheme;
  final double feedbackIntensity;
  final MatrixFillerStyle fillerStyle;
  final MatrixFillerColor fillerColor;
  final MatrixGlowStyle glowStyle;
  final MatrixLeadingColor leadingColor;
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
    required this.glowStyle,
    required this.leadingColor,
  });

  List<Color> _generateFillerShades(Color baseColor) {
    return List.generate(8, (i) {
      final t = (i / 7) * 0.5 + 0.2;
      return Color.lerp(Colors.black, baseColor, t)!;
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final column in columns) {
      if (column.rippleEffect > 0) _drawRippleEffect(canvas, column);
      for (int i = 0; i < column.characters.length; i++) {
        final yOffset = column.yPosition + (i * MatrixRainColumn.textHeight);
        if (yOffset + MatrixRainColumn.textHeight < 0 || yOffset > size.height) continue;
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
    double fontSize = 16;
    List<Shadow> shadows = [];
    final baseHighlightColor = _palettes[colorTheme]![(_palettes[colorTheme]!.length * 0.8).floor()];

    if (column.isCurrentlyPlaying) {
      charColor = Colors.yellow;
      fontSize = 18;
      if (glowStyle != MatrixGlowStyle.none) {
        final glow = column.glowIntensity * feedbackIntensity;
        shadows = [Shadow(color: Colors.yellow.withOpacity(0.8 * glow), blurRadius: 15 * glow), Shadow(color: Colors.orange.withOpacity(0.6 * glow), blurRadius: 8 * glow)];
      }
    } else if (column.isHighlighted) {
      charColor = baseHighlightColor;
      fontSize = 17;
      if (glowStyle != MatrixGlowStyle.none) {
        final glow = feedbackIntensity;
        shadows = [Shadow(color: baseHighlightColor.withOpacity(0.8 * glow), blurRadius: 12 * glow), Shadow(color: Colors.white.withOpacity(0.2 * glow), blurRadius: 6 * glow)];
      }
    } else {
      charColor = _leadingColorMap[leadingColor]!;
      if (glowStyle == MatrixGlowStyle.all) {
        shadows = [Shadow(color: charColor.withOpacity(0.8), blurRadius: 8)];
      }
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

    if (isFiller) {
      final cIndex = (shades.length - 1) - (index % shades.length);
      charColor = shades[cIndex];
    } else {
      switch (titleStyle) {
        case MatrixTitleStyle.random:
          final cIndex = (shades.length - 1) - (index % shades.length);
          charColor = shades[cIndex];
          break;
        case MatrixTitleStyle.gradient:
          final gradPos = (index - 1) / (column.characters.length - 3).clamp(1, double.infinity);
          final cIndex = (gradPos * (shades.length - 1)).round().clamp(0, shades.length - 1);
          charColor = shades[cIndex];
          break;
        case MatrixTitleStyle.solid:
          charColor = shades[(shades.length * 0.7).floor()];
          break;
      }
    }

    List<Shadow> shadows = [];
    if (!isFiller) {
      if (glowStyle == MatrixGlowStyle.all) {
        shadows = [Shadow(color: charColor.withOpacity(0.6), blurRadius: 4)];
      } else if (glowStyle == MatrixGlowStyle.current) {
        if (column.isHighlighted) shadows = [Shadow(color: charColor.withOpacity(0.6 * feedbackIntensity), blurRadius: 4)];
        else if (column.isCurrentlyPlaying) {
          final glow = column.glowIntensity * feedbackIntensity;
          shadows = [Shadow(color: charColor.withOpacity(0.4 * glow), blurRadius: 6 * glow)];
        }
      }
    }
    _paintChar(canvas, column.characters[index], column.xPosition, yOffset, charColor, 16, FontWeight.normal, shadows, column.rippleEffect);
  }

  void _paintChar(Canvas canvas, String char, double x, double y, Color color, double fontSize, FontWeight weight, List<Shadow> shadows, double rippleEffect) {
    if (rippleEffect > 0) color = Color.lerp(color, Colors.white, rippleEffect * 0.5 * feedbackIntensity) ?? color;
    _textPainter.text = TextSpan(style: TextStyle(fontFamily: 'monospace', fontSize: fontSize, color: color, fontWeight: weight, shadows: shadows), text: char);
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