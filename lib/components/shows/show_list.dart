import 'package:flutter/material.dart';
import 'package:matrix/components/shows/show_tile.dart';
import 'package:matrix/components/year_scrollbar.dart';
import 'package:matrix/models/show.dart';
import 'package:matrix/providers/album_settings_provider.dart';
import 'package:matrix/providers/enums.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class ShowList extends StatefulWidget {
  final List<Show> shows;
  final ItemScrollController itemScrollController;
  final ItemPositionsListener itemPositionsListener;

  const ShowList({
    super.key,
    required this.shows,
    required this.itemScrollController,
    required this.itemPositionsListener,
  });

  @override
  State<ShowList> createState() => _ShowListState();
}

class _ShowListState extends State<ShowList> {
  // This state now lives here, ensuring only one tile in the entire list is open.
  String? _currentlyExpandedId;

  // --- MODIFIED METHOD ---
  // This updated logic correctly handles collapsing nested ExpansionTiles.
  void _handleExpansion(bool isExpanding, String id) {
    setState(() {
      if (isExpanding) {
        // When expanding any tile, it becomes the currently expanded one.
        _currentlyExpandedId = id;
      } else {
        // This is the collapse logic.
        if (_currentlyExpandedId == id) {
          // Check if the collapsing tile is a nested SHNID tile.
          // We can identify it by the '_' separator in its ID.
          final int separatorIndex = id.lastIndexOf('_');

          if (separatorIndex != -1) {
            // It's a nested tile. Revert the expanded ID to its parent's ID,
            // which keeps the main show tile open.
            _currentlyExpandedId = id.substring(0, separatorIndex);
          } else {
            // It's a top-level show tile. Set to null to collapse it.
            _currentlyExpandedId = null;
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.shows.isEmpty) {
      return const Center(
        child: Text(
          'No shows found for this category.',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      );
    }

    final settings = context.watch<AlbumSettingsProvider>();
    final showYears = widget.shows
        .map((show) => int.tryParse(show.year) ?? 0)
        .where((year) => year > 0)
        .toList();

    Widget mainContent = ScrollablePositionedList.builder(
      itemScrollController: widget.itemScrollController,
      itemPositionsListener: widget.itemPositionsListener,
      itemCount: widget.shows.length,
      itemBuilder: (context, index) {
        final show = widget.shows[index];
        return ShowTile(
          show: show,
          currentlyExpandedId: _currentlyExpandedId,
          onExpansionChanged: _handleExpansion,
        );
      },
    );

    return SafeArea(
      child: settings.yearScrollbarBehavior != YearScrollbarBehavior.off
          ? YearScrollbar(
        years: showYears,
        itemPositionsListener: widget.itemPositionsListener,
        itemScrollController: widget.itemScrollController,
        alwaysShow: settings.yearScrollbarBehavior == YearScrollbarBehavior.always,
        child: mainContent,
      )
          : mainContent,
    );
  }
}