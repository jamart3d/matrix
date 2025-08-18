// lib/components/matrix_rain/matrix_rain_column.dart

import 'dart:math';
import 'dart:ui';

class MatrixRainColumn {
  static const double textHeight = 20.0;
  static const double hitBoxWidth = 40.0;
  final List<String> characters;
  final String showVenue;
  final String originalVenue;
  double xPosition, yPosition;
  final double speed;
  bool isFinished = false, isHighlighted = false, isCurrentlyPlaying = false;
  double rippleEffect = 0.0, glowIntensity = 0.0;
  int frames = 0;

  MatrixRainColumn({
    required this.characters,
    required this.showVenue,
    required this.originalVenue,
    required this.xPosition,
    required this.yPosition,
    required this.speed,
  });

  void fall(double screenHeight) {
    yPosition += speed;
    frames++;
    if (rippleEffect > 0) rippleEffect = (rippleEffect - 0.05).clamp(0.0, 1.0);
    if (isCurrentlyPlaying) glowIntensity = 0.65 + (sin(frames * 0.05) * 0.35);
    else glowIntensity = (glowIntensity - 0.02).clamp(0.0, 1.0);
    if (yPosition > screenHeight) isFinished = true;
  }

  bool isVenueCharacter(int index) => index > 0 && index < characters.length - 1;

  bool isRandomFiller(int index) {
    if (index == 0 || index == characters.length - 1) return true;
    if (originalVenue[index - 1] == ' ') return true;
    return false;
  }

  void triggerRipple() => rippleEffect = 1.0;
  Rect getBounds() => Rect.fromLTWH(xPosition - (hitBoxWidth / 2), yPosition, hitBoxWidth, characters.length * textHeight);
}