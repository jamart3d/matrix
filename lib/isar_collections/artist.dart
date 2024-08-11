import 'package:isar/isar.dart';
import 'package:myapp/isar_collections/album.dart';

part 'artist.g.dart';

@collection
class Artist {
  Id id = Isar.autoIncrement;

  String name = '';

  final albums = IsarLinks<Album>();
}
