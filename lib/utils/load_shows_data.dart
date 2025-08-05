import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:huntrix/models/show.dart';

Future<List<Show>> loadShowsData(BuildContext context) async {
  try {
    // 1. Load the raw JSON string from the asset bundle.
    final jsonString = await DefaultAssetBundle.of(context)
        .loadString('assets/archive_tracks_matrix_opt.json');

    // 2. Decode the JSON string into a standard Dart List of Maps.
    final List<dynamic> jsonData = jsonDecode(jsonString);

    // 3. Map over the decoded list, calling the `Show.fromJson` factory
    //    constructor for each item to create a list of Show objects.
    //    The complex parsing logic is handled by the Show and Track models.
    return jsonData.map((item) => Show.fromJson(item)).toList();
  } catch (e) {
    // If anything goes wrong, print a debug message and return an empty list
    // to prevent the app from crashing.
    debugPrint("Error loading or parsing shows data: $e");
    return [];
  }
}
