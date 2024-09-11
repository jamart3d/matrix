import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:huntrix/models/track.dart';
import 'package:provider/provider.dart'; // Import Provider
import 'package:logger/logger.dart';

Future<List<Track>> loadJsonData(BuildContext context) async {
  final logger = Provider.of<Logger>(context); // Access global logger

  String jsonString =
      await DefaultAssetBundle.of(context).loadString('assets/data.json');
  try {
    jsonString = jsonString.replaceAll('\u00A0', ' ');
    final List<dynamic> jsonData = jsonDecode(jsonString);
    return jsonData.map((item) => Track.fromJson(item)).toList();
  } catch (e) {
    logger.e('Error loading JSON data: $e'); // Use global logger
    throw Exception('Error loading data. Please try again later.');
  }
}