// lib/components/player/album_art_view.dart

import 'package:flutter/material.dart';

class AlbumArtView extends StatelessWidget {
  final String albumArt;
  final String heroTag;

  const AlbumArtView({
    super.key,
    required this.albumArt,
    required this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: heroTag,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.yellow.withOpacity(0.3),
              blurRadius: 30,
              spreadRadius: 5,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: AspectRatio(
          aspectRatio: 1,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Image.asset(
              albumArt,
              gaplessPlayback: true,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.grey.shade800, Colors.grey.shade900],
                    ),
                  ),
                  child: const Center(
                    child: Icon(Icons.music_note_rounded, color: Colors.white54, size: 60),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}