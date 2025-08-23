// lib/utils/seamless_rect_tween.dart

import 'package:flutter/material.dart';

/// A custom [RectTween] that allows specifying a [Curve] for the Hero animation.
/// This ensures the flight path uses the same easing as other animations on the
/// source and destination widgets, creating a perfectly seamless transition.
class SeamlessRectTween extends RectTween {
  final Curve curve;

  SeamlessRectTween({
    required this.curve,
    required Rect begin,
    required Rect end,
  }) : super(begin: begin, end: end);

  @override
  Rect lerp(double t) {
    // Apply the specified curve to the animation's progress value (t).
    final curvedT = curve.transform(t);
    // Use the curved progress value to interpolate between the begin and end Rects.
    return Rect.lerp(begin, end, curvedT)!;
  }
}