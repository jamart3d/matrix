// lib/widgets/year_scrollbar.dart

import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class YearScrollbar extends StatefulWidget {
  final Widget child;
  final List<int> years; // List of years corresponding to your list items
  final ItemPositionsListener itemPositionsListener;

  const YearScrollbar({
    Key? key,
    required this.child,
    required this.years,
    required this.itemPositionsListener,
  }) : super(key: key);

  @override
  State<YearScrollbar> createState() => _YearScrollbarState();
}

class _YearScrollbarState extends State<YearScrollbar> {
  String _currentYear = '';
  bool _isScrolling = false;

  @override
  void initState() {
    super.initState();
    widget.itemPositionsListener.itemPositions.addListener(_onScroll);
    // Set initial year if years list is not empty
    if (widget.years.isNotEmpty) {
      _currentYear = (widget.years.first % 100).toString().padLeft(2, '0');
    }
  }

  void _onScroll() {
    if (widget.years.isEmpty) return;

    final positions = widget.itemPositionsListener.itemPositions.value;
    if (positions.isEmpty) return;

    // Get the first visible item index
    final firstVisibleIndex = positions
        .where((position) => position.itemLeadingEdge < 1)
        .reduce((min, position) => position.itemLeadingEdge > min.itemLeadingEdge ? position : min)
        .index;

    // Ensure we don't go out of bounds
    final safeIndex = firstVisibleIndex.clamp(0, widget.years.length - 1);
    final year = widget.years[safeIndex];
    final yearStr = (year % 100).toString().padLeft(2, '0');

    if (_currentYear != yearStr) {
      setState(() {
        _currentYear = yearStr;
      });
    }
  }

  @override
  void dispose() {
    widget.itemPositionsListener.itemPositions.removeListener(_onScroll);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification notification) {
        setState(() {
          _isScrolling = notification is ScrollStartNotification ||
              (notification is ScrollUpdateNotification && notification.dragDetails != null);
        });
        return false;
      },
      child: Stack(
        children: [
          // Your scrollable content
          widget.child,

          // Custom scrollbar with year display
          if (_isScrolling)
            Positioned(
              right: 4,
              top: 0,
              bottom: 0,
              child: CustomPaint(
                painter: YearScrollbarPainter(
                  currentYear: _currentYear,
                  isVisible: _isScrolling,
                ),
                size: const Size(40, double.infinity),
              ),
            ),
        ],
      ),
    );
  }
}

class YearScrollbarPainter extends CustomPainter {
  final String currentYear;
  final bool isVisible;

  YearScrollbarPainter({
    required this.currentYear,
    required this.isVisible,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!isVisible) return;

    final thumbHeight = 40.0;
    final thumbTop = (size.height - thumbHeight) / 2; // Center the thumb

    // Draw scrollbar track
    final trackPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 6;

    canvas.drawLine(
      Offset(size.width - 20, 20),
      Offset(size.width - 20, size.height - 20),
      trackPaint,
    );

    // Draw thumb with year
    final thumbRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width - 35, thumbTop, 30, thumbHeight),
      const Radius.circular(15),
    );

    // Thumb background
    final thumbPaint = Paint()..color = Colors.yellow.withOpacity(0.9);
    canvas.drawRRect(thumbRect, thumbPaint);

    // Year text
    final textPainter = TextPainter(
      text: TextSpan(
        text: currentYear,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    // Center the text in the thumb
    final textOffset = Offset(
      thumbRect.center.dx - textPainter.width / 2,
      thumbRect.center.dy - textPainter.height / 2,
    );

    textPainter.paint(canvas, textOffset);
  }

  @override
  bool shouldRepaint(YearScrollbarPainter oldDelegate) {
    return oldDelegate.currentYear != currentYear ||
        oldDelegate.isVisible != isVisible;
  }
}

// Usage in your settings page:
// Replace your existing ListView with:

/*
YearScrollbar(
  years: [2020, 2021, 2022, 2023, 2024], // Your actual years data
  child: ListView(
    children: <Widget>[
      // Your existing ListTile widgets...
    ],
  ),
)
*/