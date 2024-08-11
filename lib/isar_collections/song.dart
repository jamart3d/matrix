import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:myapp/isar_collections/album.dart';

part 'song.g.dart'; // Ensure code generation

@Collection()
class Song {
  Id id = Isar.autoIncrement;

  @Index(type: IndexType.value)
  late String title; // Song title (indexed for faster queries)

  late String artist; // Artist name

  int? albumId; // ID of the album this song belongs to (optional)

  int? track; // Track number (optional)

  int? duration; // Song duration in seconds (optional)

  @Index(unique: true)
  late String audioFileUrl; // URL of the audio file (unique and indexed)

  String? localFilePath; // Local file path (if downloaded) - optional
  String? localFileName; // Local file name (if downloaded) - optional
  //late String album;
  
  @required
   final album = IsarLink<Album>(); // Link to the album

  Song(this.title); 
}
