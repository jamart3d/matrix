import 'package:isar/isar.dart';
import 'package:myapp/isar_collections/artist.dart';
import 'package:myapp/isar_collections/song.dart';

part 'album.g.dart'; // Ensure code generation

@Collection() // Mark as an Isar Collection
class Album {
  Id id = Isar.autoIncrement; // Auto-incrementing ID

  @Index(type: IndexType.value, unique: true)
  late String title; // Title of the album (unique and indexed)

  //late String artist; // Artist of the album

  String? imageUrl; // Optional URL for the album cover image

  DateTime? date; // Optional release date of the album

  @Backlink(to: 'album')
  final songs = IsarLinks<Song>();

  //@Backlink(to: 'album')
  final artist = IsarLink<Artist>(); 


  Album();
}
