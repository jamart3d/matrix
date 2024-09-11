import 'package:flash/flash.dart';
import 'package:flutter/material.dart';

// Display a flash message
void showFlashMessage(BuildContext context, String message) {
  showFlash(
    context: context,
    duration: const Duration(seconds: 2),
    builder: (context, controller) {
      return FlashBar(
        controller: controller,
        icon: const Icon(Icons.check_circle),
        indicatorColor: Colors.deepPurple,
        backgroundColor: const Color.fromARGB(221, 255, 255, 255),
        position: FlashPosition.top,
        margin: const EdgeInsets.all(8.0),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        content: Text(
          message,
          style: const TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
        ),
      );
    },
  ).then((_) {
    // This callback is called when the FlashBar is dismissed
  });
}
