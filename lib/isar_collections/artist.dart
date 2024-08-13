import 'package:isar/isar.dart';
import 'package:myapp/isar_collections/album.dart';
import 'package:myapp/isar_collections/song.dart';

part 'artist.g.dart';

@collection
class Artist {
  Id id = Isar.autoIncrement;

  late String? name;
  
  final songs = IsarLinks<Song>();
  final albums = IsarLinks<Album>();
  
  Artist();
}
