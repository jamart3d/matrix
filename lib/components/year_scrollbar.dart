// lib/components/year_scrollbar.dart

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class YearScrollbar extends StatefulWidget {
  final Widget child;
  final List<int> years;
  final ItemPositionsListener itemPositionsListener;
  final bool alwaysShow;
  final ItemScrollController? itemScrollController; // Added this parameter

  const YearScrollbar({
    super.key,
    required this.child,
    required this.years,
    required this.itemPositionsListener,
    this.alwaysShow = false,
    this.itemScrollController, // Added optional parameter
  });

  @override
  State<YearScrollbar> createState() => _YearScrollbarState();
}

class _YearScrollbarState extends State<YearScrollbar> {
  final Logger _logger = Logger();
  String _currentYear = '';
  bool _isScrolling = false;
  bool _isDragging = false;
  int _currentYearIndex = 0;

  @override
  void initState() {
    super.initState();
    widget.itemPositionsListener.itemPositions.addListener(_onScroll);
    if (widget.years.isNotEmpty) {
      _currentYear = (widget.years.first % 100).toString().padLeft(2, '0');
    }
  }

  void _onScroll() {
    if (widget.years.isEmpty) return;
    final positions = widget.itemPositionsListener.itemPositions.value;
    if (positions.isEmpty) return;

    final firstVisibleIndex = positions
        .where((position) => position.itemLeadingEdge < 1)
        .reduce((min, position) => position.itemLeadingEdge > min.itemLeadingEdge ? position : min)
        .index;

    final safeIndex = firstVisibleIndex.clamp(0, widget.years.length - 1);
    final year = widget.years[safeIndex];
    final yearStr = (year % 100).toString().padLeft(2, '0');

    if (_currentYear != yearStr || _currentYearIndex != safeIndex) {
      setState(() {
        _currentYear = yearStr;
        _currentYearIndex = safeIndex;
      });
    }
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _logger.d("Drag started at: ${details.localPosition}");
      _isDragging = true;
      _isScrolling = true;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (widget.itemScrollController == null || widget.years.isEmpty) return;

    // Get the render box to calculate positions
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final scrollbarHeight = renderBox.size.height - 40; // Account for padding

    // Use global position and convert to local
    final globalPosition = details.globalPosition;
    final localPosition = renderBox.globalToLocal(globalPosition);

    // Calculate relative position (0.0 to 1.0)
    final relativeY = ((localPosition.dy - 20) / scrollbarHeight).clamp(0.0, 1.0);

    // Map to year index
    final targetIndex = (relativeY * (widget.years.length - 1)).round();
    final clampedIndex = targetIndex.clamp(0, widget.years.length - 1);

    // Update UI immediately
    final year = widget.years[clampedIndex];
    final yearStr = (year % 100).toString().padLeft(2, '0');

    if (_currentYear != yearStr || _currentYearIndex != clampedIndex) {
      setState(() {
        _currentYear = yearStr;
        _currentYearIndex = clampedIndex;
      });
    }

    // Scroll to the position
    widget.itemScrollController!.jumpTo(index: clampedIndex);
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
    });

    // Hide scrollbar after delay if not always shown
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && !widget.alwaysShow) {
        setState(() {
          _isScrolling = false;
        });
      }
    });
  }

  void _onTap(TapUpDetails details) {
    if (widget.itemScrollController == null || widget.years.isEmpty) return;

    // Get the render box to calculate positions
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final scrollbarHeight = renderBox.size.height - 40; // Account for padding

    // Use global position and convert to local
    final globalPosition = details.globalPosition;
    final localPosition = renderBox.globalToLocal(globalPosition);

    // Calculate relative position (0.0 to 1.0)
    final relativeY = ((localPosition.dy - 20) / scrollbarHeight).clamp(0.0, 1.0);

    // Map to year index
    final targetIndex = (relativeY * (widget.years.length - 1)).round();
    final clampedIndex = targetIndex.clamp(0, widget.years.length - 1);

    // Smooth scroll to the position
    widget.itemScrollController!.scrollTo(
      index: clampedIndex,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    widget.itemPositionsListener.itemPositions.removeListener(_onScroll);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Determine if the scrollbar should be visible based on the new logic.
    final bool shouldBeVisible = _isScrolling || widget.alwaysShow;

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification notification) {
        if (notification is ScrollStartNotification && !_isDragging) {
          setState(() => _isScrolling = true);
        } else if (notification is ScrollEndNotification && !_isDragging) {
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted && !widget.alwaysShow && !_isDragging) {
              setState(() => _isScrolling = false);
            }
          });
        }
        return false;
      },
      child: Stack(
        children: [
          widget.child,

          // Interactive scrollbar area
          if (shouldBeVisible)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: SizedBox(
                width: 60, // Wider touch area
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent, // Important for detecting touches
                  onPanStart: _onPanStart,
                  onPanUpdate: _onPanUpdate,
                  onPanEnd: _onPanEnd,
                  onTapUp: _onTap,
                  child: CustomPaint(
                    painter: YearScrollbarPainter(
                      currentYear: _currentYear,
                      isDragging: _isDragging,
                      progress: widget.years.isEmpty ? 0.0 : _currentYearIndex / (widget.years.length - 1),
                    ),
                    size: const Size(60, double.infinity),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class YearScrollbarPainter extends CustomPainter {
  final String currentYear;
  final bool isDragging;
  final double progress;

  YearScrollbarPainter({
    required this.currentYear,
    this.isDragging = false,
    this.progress = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final trackHeight = size.height - 40;
    final trackTop = 20.0;
    final trackBottom = size.height - 20;

    // Draw track
    final trackPaint = Paint()
      ..color = Colors.white.withOpacity(isDragging ? 0.2 : 0.1)
      ..strokeWidth = 6;
    canvas.drawLine(
        Offset(size.width - 20, trackTop),
        Offset(size.width - 20, trackBottom),
        trackPaint
    );

    // Calculate thumb position based on progress
    final thumbHeight = 40.0;
    final thumbTop = trackTop + (trackHeight - thumbHeight) * progress;

    final thumbRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width - 35, thumbTop, 30, thumbHeight),
      const Radius.circular(15),
    );

    // Thumb color changes when dragging
    final thumbPaint = Paint()
      ..color = isDragging
          ? Colors.yellow
          : Colors.yellow.withOpacity(0.9);
    canvas.drawRRect(thumbRect, thumbPaint);

    // Add a subtle shadow when dragging
    if (isDragging) {
      final shadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawRRect(thumbRect.shift(const Offset(2, 2)), shadowPaint);
    }

    // Draw year text
    final textPainter = TextPainter(
      text: TextSpan(
        text: currentYear,
        style: TextStyle(
            color: Colors.black,
            fontSize: isDragging ? 13 : 12,
            fontWeight: FontWeight.bold
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    final textOffset = Offset(
      thumbRect.center.dx - textPainter.width / 2,
      thumbRect.center.dy - textPainter.height / 2,
    );
    textPainter.paint(canvas, textOffset);
  }

  @override
  bool shouldRepaint(YearScrollbarPainter oldDelegate) {
    return oldDelegate.currentYear != currentYear ||
        oldDelegate.isDragging != isDragging ||
        oldDelegate.progress != progress;
  }
}