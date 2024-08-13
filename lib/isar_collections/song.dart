import 'package:isar/isar.dart';
import 'package:myapp/isar_collections/album.dart';
import 'package:myapp/isar_collections/artist.dart';

part 'song.g.dart'; // Ensure code generation

@Collection()
class Song {
  Id id = Isar.autoIncrement;

  @Index(type: IndexType.value)
  late String title; 


  int? albumId; 

  int? track; 

  int? duration; 

  @Index(unique: true)
  late String audioFileUrl; 

  String? localFilePath; 
  String? localFileName; 
  
  final album = IsarLink<Album>(); 
  final artist = IsarLink<Artist>(); 

  // @Backlink(to: 'songs')
  // final artist = IsarLink<Artist>();

  // @Backlink(to: 'songs')
  // final album = IsarLink<Album>();

  Song(this.title); 
}

