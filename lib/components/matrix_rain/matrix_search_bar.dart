// lib/components/matrix_rain/matrix_search_bar.dart

import 'package:flutter/material.dart';

class MatrixSearchBar extends StatelessWidget {
  final Animation<double> animation;
  final TextEditingController controller;
  final FocusNode focusNode;

  const MatrixSearchBar({
    super.key,
    required this.animation,
    required this.controller,
    required this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 16,
      right: 16,
      child: SafeArea(
        bottom: false,
        child: SizeTransition(
          sizeFactor: animation,
          axisAlignment: -1.0,
          child: Container(
            margin: const EdgeInsets.only(top: 16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.green.withOpacity(0.5)),
            ),
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                // --- UPDATED: Hint text is more helpful ---
                hintText: 'Search venues or year (e.g., 77)...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                prefixIcon: const Icon(Icons.search, color: Colors.green),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              ),
            ),
          ),
        ),
      ),
    );
  }
}