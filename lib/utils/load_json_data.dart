import 'dart:convert';
import 'package:flutter/material.dart'; // Add this import
import 'package:myapp/models/track.dart';

Future<List<Track>> loadJsonData(BuildContext context) async {
  String jsonString =
      await DefaultAssetBundle.of(context).loadString('assets/data.json');
  try {
    jsonString = jsonString.replaceAll('\u00A0', ' ');
    final List<dynamic> jsonData = jsonDecode(jsonString);
    return jsonData.map((item) => Track.fromJson(item)).toList();
  } catch (e) {
    print('Error loading JSON data: $e');
    throw Exception('Error loading data. Please try again later.');
  }
}
