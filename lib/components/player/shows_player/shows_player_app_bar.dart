import 'dart:ui'; // Import this for ImageFilter
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:marquee/marquee.dart';
import 'package:matrix/providers/track_player_provider.dart';
import 'package:matrix/utils/album_title_parser.dart';
import 'package:provider/provider.dart';

class ShowsPlayerSliverAppBar extends StatelessWidget {
  final VoidCallback onClearPlaylist;
  final Color themeColor;
  final Color themeAccentColor;
  final List<Shadow> glowShadows;

  const ShowsPlayerSliverAppBar({
    super.key,
    required this.onClearPlaylist,
    required this.themeColor,
    required this.themeAccentColor,
    required this.glowShadows,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      backgroundColor: Colors.transparent, // Important for blur to be visible
      pinned: true,
      floating: false,
      snap: false,
      expandedHeight: 120.0,
      actions: [
        IconButton(
          icon: const Icon(Icons.delete_sweep),
          tooltip: 'Clear Playlist',
          onPressed: onClearPlaylist,
        ),
      ],
      flexibleSpace: ClipRect(
        // Prevents the blur from bleeding outside the app bar
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
          child: FlexibleSpaceBar(
            // The background now sits inside the BackdropFilter
            background: Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding:
                const EdgeInsets.only(left: 56, bottom: 16, right: 16),
                child: _buildAlbumInfo(context),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlbumInfo(BuildContext context) {
    final provider = context.watch<TrackPlayerProvider>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 24,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final venueText =
              AlbumTitleParser.extractVenue(provider.currentAlbumTitle);
              final textStyle = TextStyle(
                color: themeColor,
                fontWeight: FontWeight.bold,
                fontSize: 22,
                shadows: glowShadows,
              );

              final textPainter = TextPainter(
                text: TextSpan(text: venueText, style: textStyle),
                maxLines: 1,
                textDirection: TextDirection.ltr,
              )..layout(minWidth: 0, maxWidth: double.infinity);

              if (textPainter.width > constraints.maxWidth) {
                return Marquee(
                  text: venueText,
                  style: textStyle,
                  velocity: 40.0,
                  blankSpace: 30.0,
                  startAfter: const Duration(seconds: 1),
                  pauseAfterRound: const Duration(seconds: 2),
                );
              }
              return Text(venueText, style: textStyle);
            },
          ),
        ),
        const Gap(2),
        Text(
          AlbumTitleParser.extractDate(provider.currentAlbumTitle),
          style:
          TextStyle(color: themeColor, fontSize: 16, shadows: glowShadows),
        ),
      ],
    );
  }
}
