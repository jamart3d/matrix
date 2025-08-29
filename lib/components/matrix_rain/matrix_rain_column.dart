// lib/components/matrix_rain/matrix_rain_column.dart

import 'dart:math';
import 'dart:ui';
import 'package:matrix/providers/enums.dart';

class MatrixRainColumn {
  final double textHeight;
  static const double hitBoxWidth = 40.0;

  static const double _fillerChangeRate = 0.35;
  static const double _rippleDecay = 0.05;
  static const double _glowDecay = 0.02;
  static const double _glowPulseSpeed = 0.05;
  static const double _baseGlow = 0.65;
  static const double _glowVariation = 0.35;

  static const String _matrixCharSet = 'ﾊﾐﾋｰｳｼﾅﾓﾆｻﾜﾂｵﾘｱﾎﾃﾏｹﾒｴｶｷﾑﾕﾗｾﾈｽﾀﾇﾍｦｧｨｩｪｫｬｭｮｯ0123456789';
  static final Random _charRandom = Random();

  final List<String> characters;
  final LeadingCharacterStyle style;
  final String showVenue;
  final String originalVenue;
  final String year;
  final int laneIndex;
  double xPosition, yPosition;
  final double speed;
  bool isFinished = false, isHighlighted = false, isCurrentlyPlaying = false;
  double rippleEffect = 0.0, glowIntensity = 0.0;
  int frames = 0;
  bool _hasRestoredYear = false; // Track if year digits have been restored

  double _yPositionOfLastStepUpdate;

  // --- Counters for timed randomization ---
  int _topCharCounter = 0;
  int _fillerCounter = 0;
  int _titleCascadeCounter = 0;

  // --- Thresholds for how often to update ---
  static const int _topCharUpdateRate = 15; // Slower: update every 15 steps
  static const int _fillerUpdateRate = 5;   // Faster: update every 5 steps
  static const int _titleCascadeRate = 20;  // Very slow: cascade title every 20 steps

  List<int>? _cachedFillerIndices;
  final List<int> _workingIndices = <int>[];

  MatrixRainColumn({
    required this.characters,
    required this.style,
    required this.showVenue,
    required this.originalVenue,
    required this.year,
    required this.laneIndex,
    required this.xPosition,
    required this.yPosition,
    required this.speed,
    required this.textHeight,
  }) : _yPositionOfLastStepUpdate = yPosition;

  int get numLeadingChars {
    switch (style) {
      case LeadingCharacterStyle.year: return 2;
      case LeadingCharacterStyle.chaotic: return 1; // MODIFIED: Set to a single character
      case LeadingCharacterStyle.none: return 0;
    }
  }

  bool isTopChar(int index) => index == 0;

  static String _getRandomMatrixChar() {
    return _matrixCharSet[_charRandom.nextInt(_matrixCharSet.length)];
  }

  static String getRandomMatrixChar() => _getRandomMatrixChar();

  List<int> _getFillerIndices() {
    if (_cachedFillerIndices == null) {
      _cachedFillerIndices = <int>[];
      for (int i = 1; i < characters.length - numLeadingChars; i++) {
        if (isRandomFiller(i)) {
          _cachedFillerIndices!.add(i);
        }
      }
    }
    return _cachedFillerIndices!;
  }

  bool _shouldStopRandomization(double screenHeight) {
    // Calculate the position of the leading characters (bottom of the column)
    final leadingCharPosition = yPosition + (characters.length * textHeight);
    return leadingCharPosition >= screenHeight / 2;
  }

  void fall({
    required double screenHeight,
    required Random random,
    required MatrixStepMode stepMode,
  }) {
    yPosition += speed;
    frames++;

    // Check if we should restore year digits (when leading part reaches halfway down screen)
    if (style == LeadingCharacterStyle.year && !_hasRestoredYear && _shouldStopRandomization(screenHeight)) {
      _hasRestoredYear = true;
      // Restore the correct year digits
      if (year.length >= 2 && characters.length >= 2) {
        final yearDigits = year.substring(year.length - 2).split('');
        characters[characters.length - 2] = yearDigits[0];
        characters[characters.length - 1] = yearDigits[1];
      }
    }

    if ((yPosition - _yPositionOfLastStepUpdate) >= textHeight) {
      final steps = ((yPosition - _yPositionOfLastStepUpdate) / textHeight).floor();
      _yPositionOfLastStepUpdate += steps * textHeight;
      yPosition = _yPositionOfLastStepUpdate;

      // MODIFIED: Handle "Chaotic" style (single character). This is always randomized on every step.
      if (style == LeadingCharacterStyle.chaotic && characters.isNotEmpty) {
        characters[characters.length - 1] = _getRandomMatrixChar();
      }

      // Only randomize other characters if the leading part hasn't reached halfway down screen
      if (!_shouldStopRandomization(screenHeight)) {
        // --- Use timed randomization logic ---
        _topCharCounter++;
        _fillerCounter++;
        _titleCascadeCounter++;

        // Randomize top character (slowly)
        if (_topCharCounter >= _topCharUpdateRate) {
          if (characters.isNotEmpty) {
            characters[0] = _getRandomMatrixChar();
          }
          _topCharCounter = 0; // Reset counter
        }

        // Title cascade effect (very slow, subtle)
        if (_titleCascadeCounter >= _titleCascadeRate) {
          _cascadeTitleCharacters(random);
          _titleCascadeCounter = 0; // Reset counter
        }

        // Handle "Year" style (two characters) while it's falling and not in stop zone.
        if (style == LeadingCharacterStyle.year && characters.length >= 2) {
          // Cascade: second char becomes what first char was, first char gets new random
          characters[characters.length - 2] = characters[characters.length - 1];
          characters[characters.length - 1] = _getRandomMatrixChar();
        }

        // Randomize filler characters (at a medium rate)
        if (_fillerCounter >= _fillerUpdateRate) {
          final fillerIndices = _getFillerIndices();
          if (fillerIndices.isNotEmpty) {
            _workingIndices.clear();
            _workingIndices.addAll(fillerIndices);
            _workingIndices.shuffle(random);
            final int numberToChange = (fillerIndices.length * _fillerChangeRate).round().clamp(1, fillerIndices.length);
            for (int i = 0; i < numberToChange; i++) {
              final int indexToChange = _workingIndices[i];
              characters[indexToChange] = _getRandomMatrixChar();
            }
          }
          _fillerCounter = 0; // Reset counter
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

  bool isVenueCharacter(int index) => index > 0 && index < characters.length - numLeadingChars;

  bool isRandomFiller(int index) {
    final venueIndex = index - 1;
    if (venueIndex >= 0 && venueIndex < originalVenue.length) {
      return originalVenue[venueIndex] == ' ';
    }
    return false;
  }

  void _cascadeTitleCharacters(Random random) {
    // Only cascade venue characters (between top char and leading chars)
    const venueStartIndex = 1;
    final venueEndIndex = characters.length - numLeadingChars - 1;

    if (venueEndIndex <= venueStartIndex) return;

    // Pick 1-2 random positions to cascade
    final numToCascade = random.nextInt(2) + 1;
    final availableIndices = List.generate(venueEndIndex - venueStartIndex + 1, (i) => i + venueStartIndex);
    availableIndices.shuffle(random);

    for (int i = 0; i < numToCascade && i < availableIndices.length; i++) {
      final index = availableIndices[i];
      final venueIndex = index - 1;

      // 70% chance to restore original character, 30% chance for random
      if (random.nextDouble() < 0.7 && venueIndex < originalVenue.length) {
        characters[index] = originalVenue[venueIndex];
      } else {
        characters[index] = _getRandomMatrixChar();
      }
    }
  }

  void triggerRipple() => rippleEffect = 1.0;

  Rect getBounds() => Rect.fromLTWH(
      xPosition - (hitBoxWidth / 2),
      yPosition,
      hitBoxWidth,
      characters.length * textHeight
  );
}