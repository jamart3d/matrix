// lib/pages/track_detail_page.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:matrix/utils/duration_formatter.dart';
import 'package:matrix/models/track.dart';
import 'package:marquee/marquee.dart'; // IMPORT ADDED

class TrackDetailPage extends StatelessWidget {
  final Track track;

  const TrackDetailPage({super.key, required this.track});

  // ================== NEW HELPER METHOD ADDED ==================
  String _formatDateHumanReadable(String? date) {
    if (date == null || date.isEmpty) return 'Unknown Date';
    try {
      final dateTime = DateTime.parse(date);
      const List<String> monthNames = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ];
      final month = monthNames[dateTime.month - 1];
      final day = dateTime.day;
      final year = dateTime.year;
      return '$month $day, $year';
    } catch (e) {
      return date; // Fallback to the original string if parsing fails
    }
  }
  // =============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, // Extend background to the app bar
      appBar: AppBar(
        centerTitle: true,
        forceMaterialTransparency: true,
        foregroundColor: Colors.white,
        backgroundColor: Colors.transparent,
        elevation: 0,
        // ================== WIDGET MODIFIED HERE ==================
        title: SizedBox(
          height: 30, // Give the marquee a constrained height
          child: Marquee(
            text: "Track Info",
            style: const TextStyle(fontWeight: FontWeight.bold),
            velocity: 40.0,
            blankSpace: 30.0,
          ),
        ),
        // ========================================================
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(track.albumArt ?? 'assets/images/t_steal.webp'),
            fit: BoxFit.cover,
          ),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(
              sigmaX: 10.0, sigmaY: 10.0), // Adjust blur intensity as needed
          child: Container(
            color: Colors.black.withOpacity(
                0.5),
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Card(
                // Make the card completely transparent
                color: Colors.transparent,
                elevation: 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Gap(100),
                    // Display album art if available, otherwise a placeholder
                    if (track.albumArt != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.asset(
                          track.albumArt!,
                          fit: BoxFit.cover,
                        ),
                      )
                    else
                    // Placeholder image or text if album art is not available
                      const SizedBox(
                        height: 200,
                        child: Center(
                          child: Text('No Album Art Available',
                              style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    const Gap(30),
                    // Track details with white text color
                    Center(
                      child: Column(
                        children: [
                          Text(
                            track.trackName,
                            style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          // ================== NEW WIDGET ADDED ==================
                          if(track.albumReleaseDate != null)
                            Text(
                              _formatDateHumanReadable(track.albumReleaseDate),
                              style: const TextStyle(fontSize: 16, color: Colors.white70),
                            ),
                          const SizedBox(height: 4),
                          // =====================================================
                          Text(
                            'Track Number: ${track.trackNumber}',
                            style:
                            const TextStyle(fontSize: 16, color: Colors.white),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Duration: ${formatDurationSeconds(track.trackDuration)}',
                            style:
                            const TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    // Add more track details as needed
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}