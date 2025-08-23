// lib/components/matrix_rain/matrix_rain_column.dart

import 'dart:math';
import 'dart:ui';
import 'package:matrix/providers/enums.dart';

class MatrixRainColumn {
  final double textHeight;
  static const double hitBoxWidth = 40.0;

  // Performance constants
  static const double _fillerChangeRate = 0.35;
  static const double _rippleDecay = 0.05;
  static const double _glowDecay = 0.02;
  static const double _glowPulseSpeed = 0.05;
  static const double _baseGlow = 0.65;
  static const double _glowVariation = 0.35;

  static const String _matrixChars = 'ﾊﾐﾋｰｳｼﾅﾓﾆｻﾜﾂｵﾘｱﾎﾃﾏｹﾒｴｶｷﾑﾕﾗｾﾈｽﾀﾇﾍｦｧｨｩｪｫｬｭｮｯ0123456789';
  static final Random _charRandom = Random();

  final List<String> characters;
  final String showVenue;
  final String originalVenue;
  final String year;
  final int laneIndex;
  double xPosition, yPosition;
  final double speed;
  bool isFinished = false, isHighlighted = false, isCurrentlyPlaying = false;
  double rippleEffect = 0.0, glowIntensity = 0.0;
  int frames = 0;

  double _yPositionOfLastStepUpdate;

  List<int>? _cachedFillerIndices;
  final List<int> _workingIndices = <int>[];

  MatrixRainColumn({
    required this.characters,
    required this.showVenue,
    required this.originalVenue,
    required this.year,
    required this.laneIndex,
    required this.xPosition,
    required this.yPosition,
    required this.speed,
    required this.textHeight,
  }) : _yPositionOfLastStepUpdate = yPosition;

  static String _getRandomMatrixChar() {
    return _matrixChars[_charRandom.nextInt(_matrixChars.length)];
  }

  static String getRandomMatrixChar() => _getRandomMatrixChar();

  List<int> _getFillerIndices() {
    if (_cachedFillerIndices == null) {
      _cachedFillerIndices = <int>[];
      for (int i = 0; i < characters.length - 1; i++) {
        if (isRandomFiller(i)) {
          _cachedFillerIndices!.add(i);
        }
      }
    }
    return _cachedFillerIndices!;
  }

  void fall(double screenHeight, Random random, bool applyChaos, MatrixStepMode stepMode) {
    yPosition += speed;
    frames++;

    if ((yPosition - _yPositionOfLastStepUpdate) >= textHeight) {
      final steps = ((yPosition - _yPositionOfLastStepUpdate) / textHeight).floor();
      _yPositionOfLastStepUpdate += steps * textHeight;
      yPosition = _yPositionOfLastStepUpdate;

      if (applyChaos && characters.isNotEmpty) {
        characters[characters.length - 1] = _getRandomMatrixChar();
      }

      final fillerIndices = _getFillerIndices();
      if (fillerIndices.isNotEmpty) {
        _workingIndices.clear();
        _workingIndices.addAll(fillerIndices);
        _workingIndices.shuffle(random);

        final int numberToChange = (fillerIndices.length * _fillerChangeRate)
            .round()
            .clamp(1, fillerIndices.length);

        for (int i = 0; i < numberToChange; i++) {
          final int indexToChange = _workingIndices[i];
          final distanceFromLead = (characters.length - 1 - indexToChange).abs();
          final cascadeProbability = 1.0 - (distanceFromLead / characters.length * 0.6);
          if (random.nextDouble() < cascadeProbability) {
            characters[indexToChange] = _getRandomMatrixChar();
          }
        }
      }
    }

    if (rippleEffect > 0) {
      rippleEffect = (rippleEffect - _rippleDecay).clamp(0.0, 1.0);
    }

    if (isCurrentlyPlaying) {
      glowIntensity = _baseGlow + (sin(frames * _glowPulseSpeed) * _glowVariation);
    } else {
      glowIntensity = (glowIntensity - _glowDecay).clamp(0.0, 1.0);
    }

    if (yPosition > screenHeight) isFinished = true;
  }

  bool isVenueCharacter(int index) => index > 0 && index < characters.length - 1;

  bool isRandomFiller(int index) {
    if (index == 0 || index == characters.length - 1) return true;
    final venueIndex = index - 1;
    if (venueIndex >= 0 && venueIndex < originalVenue.length && originalVenue[venueIndex] == ' ') {
      return true;
    }
    return false;
  }

  void triggerRipple() => rippleEffect = 1.0;

  Rect getBounds() => Rect.fromLTWH(
      xPosition - (hitBoxWidth / 2),
      yPosition,
      hitBoxWidth,
      characters.length * textHeight
  );
}