// lib/components/year_scrollbar.dart

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class YearScrollbar extends StatefulWidget {
  final Widget child;
  final List<int> years;
  final ItemPositionsListener itemPositionsListener;
  final bool alwaysShow;
  final ItemScrollController? itemScrollController;

  const YearScrollbar({
    super.key,
    required this.child,
    required this.years,
    required this.itemPositionsListener,
    this.alwaysShow = false,
    this.itemScrollController,
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

  // Add these for debouncing
  bool _isUserScrolling = false;
  DateTime _lastScrollTime = DateTime.now();

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

    // Only update if values actually changed
    if (_currentYear != yearStr || _currentYearIndex != safeIndex) {
      setState(() {
        _currentYear = yearStr;
        _currentYearIndex = safeIndex;
      });
    }

    // If not dragging and not always shown, detect user scrolling with debounce
    if (!_isDragging && !widget.alwaysShow) {
      final now = DateTime.now();
      final timeSinceLastScroll = now.difference(_lastScrollTime).inMilliseconds;

      // Only show scrollbar if this seems like actual user scrolling
      // (rapid position changes suggest user interaction)
      if (timeSinceLastScroll < 100) {
        if (!_isUserScrolling) {
          setState(() {
            _isUserScrolling = true;
            _isScrolling = true;
          });
        }

        // Reset hide timer
        _scheduleHideScrollbar();
      }

      _lastScrollTime = now;
    }
  }

  void _scheduleHideScrollbar() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && !widget.alwaysShow && !_isDragging) {
        setState(() {
          _isUserScrolling = false;
          _isScrolling = false;
        });
      }
    });
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _logger.d("Drag started at: ${details.localPosition}");
      _isDragging = true;
      _isScrolling = true;
      _isUserScrolling = true;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (widget.itemScrollController == null || widget.years.isEmpty) return;

    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final scrollbarHeight = renderBox.size.height - 40;
    final globalPosition = details.globalPosition;
    final localPosition = renderBox.globalToLocal(globalPosition);
    final relativeY = ((localPosition.dy - 20) / scrollbarHeight).clamp(0.0, 1.0);
    final targetIndex = (relativeY * (widget.years.length - 1)).round();
    final clampedIndex = targetIndex.clamp(0, widget.years.length - 1);

    final year = widget.years[clampedIndex];
    final yearStr = (year % 100).toString().padLeft(2, '0');

    if (_currentYear != yearStr || _currentYearIndex != clampedIndex) {
      setState(() {
        _currentYear = yearStr;
        _currentYearIndex = clampedIndex;
      });
    }

    widget.itemScrollController!.jumpTo(index: clampedIndex);
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
    });

    if (!widget.alwaysShow) {
      _scheduleHideScrollbar();
    }
  }

  void _onTap(TapUpDetails details) {
    if (widget.itemScrollController == null || widget.years.isEmpty) return;

    // Show scrollbar for tap interaction
    setState(() {
      _isScrolling = true;
      _isUserScrolling = true;
    });

    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final scrollbarHeight = renderBox.size.height - 40;
    final globalPosition = details.globalPosition;
    final localPosition = renderBox.globalToLocal(globalPosition);
    final relativeY = ((localPosition.dy - 20) / scrollbarHeight).clamp(0.0, 1.0);
    final targetIndex = (relativeY * (widget.years.length - 1)).round();
    final clampedIndex = targetIndex.clamp(0, widget.years.length - 1);

    widget.itemScrollController!.scrollTo(
      index: clampedIndex,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
    );

    if (!widget.alwaysShow) {
      _scheduleHideScrollbar();
    }
  }

  @override
  void dispose() {
    widget.itemPositionsListener.itemPositions.removeListener(_onScroll);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool shouldBeVisible = _isScrolling || widget.alwaysShow;

    return Stack(
      children: [
        widget.child,

        // Interactive scrollbar area
        if (shouldBeVisible)
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: SizedBox(
              width: 60,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
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
    const trackTop = 20.0;
    final trackBottom = size.height - 20;

    // Draw track
    final trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: isDragging ? 0.2 : 0.1)
      ..strokeWidth = 6;
    canvas.drawLine(
        Offset(size.width - 20, trackTop),
        Offset(size.width - 20, trackBottom),
        trackPaint
    );

    // Calculate thumb position based on progress
    const thumbHeight = 40.0;
    final thumbTop = trackTop + (trackHeight - thumbHeight) * progress;

    final thumbRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width - 35, thumbTop, 30, thumbHeight),
      const Radius.circular(15),
    );

    // Thumb color changes when dragging
    final thumbPaint = Paint()
      ..color = isDragging
          ? Colors.yellow
          : Colors.yellow.withValues(alpha: 0.9);
    canvas.drawRRect(thumbRect, thumbPaint);

    // Add a subtle shadow when dragging
    if (isDragging) {
      final shadowPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.3)
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