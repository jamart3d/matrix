// lib/components/matrix_rain/crt_screen_effect.dart

import 'dart:math';
import 'package:flutter/material.dart';

class CRTScreenEffect extends StatefulWidget {
  final Widget child;
  final double intensity;
  final bool enableFlicker;
  final bool enableCurvature;
  final bool enableScanlines;
  final bool enableVignette;
  final bool enableGlow;

  const CRTScreenEffect({
    super.key,
    required this.child,
    this.intensity = 1.0,
    this.enableFlicker = true,
    this.enableCurvature = false, // Disabled by default as it's complex
    this.enableScanlines = true,
    this.enableVignette = true,
    this.enableGlow = true,
  });

  @override
  State<CRTScreenEffect> createState() => _CRTScreenEffectState();
}

class _CRTScreenEffectState extends State<CRTScreenEffect>
    with TickerProviderStateMixin {
  late AnimationController _flickerController;
  late Animation<double> _flickerAnimation;

  @override
  void initState() {
    super.initState();

    if (widget.enableFlicker) {
      _flickerController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 100),
      );

      _flickerAnimation = Tween<double>(
        begin: 0.95,
        end: 1.0,
      ).animate(_flickerController);

      _startFlicker();
    }
  }

  void _startFlicker() {
    final random = Random();

    void flicker() {
      if (!mounted) return;

      // Random flicker intervals (mostly stable with occasional flickers)
      final delay = random.nextInt(3000) + 1000; // 1-4 seconds

      Future.delayed(Duration(milliseconds: delay), () {
        if (!mounted) return;

        _flickerController.forward().then((_) {
          if (mounted) {
            _flickerController.reverse().then((_) {
              if (mounted) flicker();
            });
          }
        });
      });
    }

    flicker();
  }

  @override
  void dispose() {
    if (widget.enableFlicker) {
      _flickerController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget result = widget.child;

    // Apply glow effect
    if (widget.enableGlow) {
      result = Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.cyan.withOpacity(0.1 * widget.intensity),
              blurRadius: 20,
              spreadRadius: 5,
            ),
            BoxShadow(
              color: Colors.green.withOpacity(0.05 * widget.intensity),
              blurRadius: 40,
              spreadRadius: 10,
            ),
          ],
        ),
        child: result,
      );
    }

    // Apply CRT overlay effects
    result = Stack(
      children: [
        result,

        // Scanlines overlay
        if (widget.enableScanlines)
          Positioned.fill(
            child: CustomPaint(
              painter: ScanlinesPainter(intensity: widget.intensity),
            ),
          ),

        // Vignette overlay
        if (widget.enableVignette)
          Positioned.fill(
            child: CustomPaint(
              painter: VignettePainter(intensity: widget.intensity),
            ),
          ),

        // Screen reflection/glare
        Positioned.fill(
          child: CustomPaint(
            painter: ScreenReflectionPainter(intensity: widget.intensity),
          ),
        ),
      ],
    );

    // Apply flicker effect
    if (widget.enableFlicker) {
      result = AnimatedBuilder(
        animation: _flickerAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _flickerAnimation.value,
            child: result,
          );
        },
      );
    }

    return result;
  }
}

class ScanlinesPainter extends CustomPainter {
  final double intensity;

  ScanlinesPainter({required this.intensity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.03 * intensity)
      ..strokeWidth = 0.5;

    // Draw horizontal scanlines
    for (double y = 0; y < size.height; y += 2) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }

    // Add occasional brighter scanlines for authenticity
    paint.color = Colors.black.withOpacity(0.08 * intensity);
    for (double y = 0; y < size.height; y += 6) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class VignettePainter extends CustomPainter {
  final double intensity;

  VignettePainter({required this.intensity});

  @override
  void paint(Canvas canvas, Size size) {
    final gradient = RadialGradient(
      center: Alignment.center,
      radius: 1.0,
      colors: [
        Colors.transparent,
        Colors.black.withOpacity(0.4 * intensity),
      ],
      stops: const [0.5, 1.0],
    );

    final paint = Paint()
      ..shader = gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ScreenReflectionPainter extends CustomPainter {
  final double intensity;

  ScreenReflectionPainter({required this.intensity});

  @override
  void paint(Canvas canvas, Size size) {
    // Subtle screen reflection gradient
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.white.withOpacity(0.02 * intensity),
        Colors.transparent,
        Colors.white.withOpacity(0.01 * intensity),
        Colors.transparent,
      ],
      stops: const [0.0, 0.3, 0.7, 1.0],
    );

    final paint = Paint()
      ..shader = gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Add corner reflections
    final cornerGradient = RadialGradient(
      center: const Alignment(-0.8, -0.8),
      radius: 0.3,
      colors: [
        Colors.white.withOpacity(0.08 * intensity),
        Colors.transparent,
      ],
    );

    final cornerPaint = Paint()
      ..shader = cornerGradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), cornerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}