import 'dart:ui';
import 'package:flutter/material.dart';

class ShowsPlayerBackground extends StatelessWidget {
  const ShowsPlayerBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Static background with a gradient and image.
        RepaintBoundary(
          child: Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/t_steal.webp'),
                fit: BoxFit.cover,
                opacity: 0.3,
              ),
              gradient: LinearGradient(
                colors: [Color(0xFF4A440D), Colors.black],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
        // Blur and tint overlay that sits on top of the background.
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
          child: Container(
            color: Colors.black.withOpacity(0.5),
          ),
        ),
      ],
    );
  }
}