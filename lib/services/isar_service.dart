import 'package:isar/isar.dart';
import 'package:myapp/isar_collections/album.dart';
import 'package:myapp/isar_collections/artist.dart';
import 'package:myapp/isar_collections/song.dart';
import 'package:path_provider/path_provider.dart';



class IsarService {
  late Future<Isar> db;

  IsarService() {
    db = openDB();
  }

Future<Isar> openDB() async {
  final dir = await getApplicationDocumentsDirectory();
  if (Isar.instanceNames.isEmpty) {
    return await Isar.open(
    [ArtistSchema, AlbumSchema, SongSchema],
      directory: dir.path,
      inspector: true,
    );
  }

  return Future.value(Isar.getInstance());
}

  Future<void> clearAllData() async {
    final isar = await db;
    // await isar.writeTxn(() async {
    //   await isar.songs.deleteAll();
    //   await isar.albums.deleteAll();
    // });
    await isar.writeTxn(() => isar.clear());
  }

  Future<void> saveSong(Song song) async {
    final isar = await db;
    isar.writeTxnSync<int>(() => isar.songs.putSync(song));
  }

  Future<void> saveAlbum(Album album) async {
    final isar = await db;
    isar.writeTxnSync<int>(() => isar.albums.putSync(album));
  }

  Future<List<Song>> getAllSongs() async {
    final isar = await db;
    return await isar.songs.where().findAll();
  }

  Future<List<Album>> getAllAlbums() async {
    final isar = await db;
    return await isar.albums.where().findAll();
  }

  Future<void> saveSongWithAlbum(Song song, Album album) async {
    print(album.title);
    final isar = await db;
    await isar.writeTxn(() async {
      // Save the album first (or get its ID if it exists)
      final existingAlbum =
          await isar.albums.where().titleEqualTo(album.title).findFirst();
      int albumId;
      if (existingAlbum != null) {
        albumId = existingAlbum.id;
        print("f $albumId");
      } else {
        print("NEWNEW");
        //album.id = await isar.albums.put(album);
        //album.songs.add(song);
        albumId = await isar.albums.put(album);
      }
      // Set the album ID in the song and save the song
      song.album.value = album;
      await isar.songs.put(song);
      //await song.album.save();
      //song.id = await isar.songs.put(song);
      //album.songs.add(song);
      //await isar.albums.put(album);
      //print(song.album.save());
      print(album.title);
      print(albumId);
      print(song.title);
      print(song.track);
    });
  }

  Future<List<Song>> getSongsForAlbum(String albumTitle) async {
    try {
      return (await db)
          .albums
          .filter()
          .titleEqualTo(albumTitle)
          .findFirst()
          .then((album) async {
        if (album != null) {
          await album.songs.load();
          return album.songs.toList();
        }
        return [];
      });
    } catch (e) {
      // Handle potential errors (e.g., print error or return empty list)
      print("Error fetching songs for album: $e");
      return [];
    }
  }

//add a get album by title
  Future<Album?> getAlbumByTitle(String albumTitle) async {
    final isar = await db;
    return await isar.albums.filter().titleEqualTo(albumTitle).findFirst();
  }

  Future<Song?> getSongByAudioFileUrl(String audioFileUrl) async {
    final isar = await db;

    final songs =
        await isar.songs.filter().audioFileUrlEqualTo(audioFileUrl).findFirst();
    return songs;
  }

  // Future<List<Song>> getSongsFor(Album album) async {
  //   final isar = await db;
  //   final album = await isar.songs
  //       .filter()
  //       .albums((q) => q.idEqualTo(album.id))
  //       .findall();
  //   if (album != null) {
  //     await album.songs.load();
  //     return album.songs.toList();
  //   }
  //   return [];
  // }

  // Add more methods as needed
}