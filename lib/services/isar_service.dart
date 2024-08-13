import 'dart:math';

import 'package:isar/isar.dart';
import 'package:myapp/isar_collections/album.dart';
import 'package:myapp/isar_collections/artist.dart';
import 'package:myapp/isar_collections/song.dart';
import 'package:path_provider/path_provider.dart';

class IsarService {
  static final IsarService _instance = IsarService._internal();

  late Isar _isar;

  factory IsarService() {
    return _instance;
  }

  IsarService._internal();

  Future<void> initialize() async {
    final dir = await getApplicationDocumentsDirectory();

    _isar = await Isar.open(
      [ArtistSchema, AlbumSchema, SongSchema],
      directory: dir.path,
      inspector: true,
    );
  }

  Isar get isar => _isar;

  getAlbums() async {
    final isar = IsarService().isar;
    return await isar.albums.where().findAll();
  }

  Future<List<Artist>> getAllArtists() async {
    final isar = IsarService().isar;
    return await isar.artists.where().findAll();
  }

  Future<void> saveSong(Song song) async {
    final isar = IsarService().isar;
    isar.writeTxnSync<int>(() => isar.songs.putSync(song));
  }

  Future<void> saveAlbum(Album album) async {
    final isar = IsarService().isar;
    isar.writeTxnSync<int>(() => isar.albums.putSync(album));
  }

  Future<List<Song>> getAllSongs() async {
    final isar = IsarService().isar;
    return await isar.songs.where().findAll();
  }

  Future<List<Album>> getAllAlbums() async {
    final isar = IsarService().isar;
    return await isar.albums.where().findAll();
  }

  Future<void> saveSongWithAlbumAndArtist(
      Song song, String albumName, String artistName) async {
    await _isar.writeTxn(() async {
      // Check if the artist exists, if not, create it
      Artist? artist =
          await _isar.artists.filter().nameEqualTo(artistName).findFirst();
      if (artist == null) {
        artist = Artist()..name = artistName;
        await _isar.artists.put(artist);
      }

      // Check if the album exists, if not, create it
      Album? album = await _isar.albums
          .filter()
          .titleEqualTo(albumName)
          .and()
          .artist((q) => q.nameEqualTo(artistName))
          .findFirst();
      if (album == null) {
        album = Album()
          ..title = albumName
          ..artist.value = artist;
        await _isar.albums.put(album);
        artist.albums.add(album);
        await _isar.artists.put(artist);
      }

      // Link the song to the album and artist
      song.album.value = album;
      song.artist.value = artist;
      await _isar.songs.put(song);

      // Update the album's song list
      album.songs.add(song);
      await _isar.albums.put(album);

      // Update the artist's song list
      artist.songs.add(song);
      await _isar.artists.put(artist);
    });
  }

  Future<Artist?> getArtistByName(Isar isar, String artistName) async {
    return await isar.artists.filter().nameEqualTo(artistName).findFirst();
  }

  Future<Artist?> getArtistByName2(Isar isar, String artistName) async {
    return await isar.artists.filter().nameMatches(artistName).findFirst();
  }

  Future<void> saveSongWithAlbum(Song song, Album album) async {
    print(album.title);
    final isar = IsarService().isar;
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

  Future<void> saveArtist(Artist artist) async {
    final isar = IsarService().isar;
    isar.writeTxnSync<int>(() => isar.artists.putSync(artist));
  }

//add a get album by title
  Future<Album?> getAlbumByTitle(String albumTitle) async {
    final isar = IsarService().isar;
    return await isar.albums.filter().titleEqualTo(albumTitle).findFirst();
  }

  Future<Song?> getSongByAudioFileUrl(String audioFileUrl) async {
    final isar = IsarService().isar;

    final songs =
        await isar.songs.filter().audioFileUrlEqualTo(audioFileUrl).findFirst();
    return songs;
  }

  static clearAllData() {
    final isar = IsarService().isar;
    isar.writeTxn(() => isar.clear());
    print("whamo");
  }

  // Future<void> addAlbumFake() async {
  //   final album = Album(
  //     title: 'rando Album ${DateTime.now().millisecondsSinceEpoch}',
  //     artist: Artist(name: 'Grateful Dead'),
  //     songs: List.generate(
  //       Random().nextInt(15) + 1,
  //       (index) => Song(
  //         title: 'Song ${index + 1}',
  //       ),
  //     ),
  //   );
  //   await IsarService().isar.writeTxn(() async {
  //     await IsarService().isar.albums.put(album);
  //   });
  // }

  //   Future<void> addAlbumFoobar() async {
  //   final album = Album(title: 'foobar', artist: Artist(name: 'Grateful Dead'));
  //   await IsarService().isar.writeTxn(() async {
  //     await IsarService().isar.albums.put(album);
  //   });
  // }

  Future<void> addAlbumWithArtist1() async {
    final isar = IsarService().isar;

    String albumTitle = 'rando Album ${DateTime.now().millisecondsSinceEpoch}';
    String artistName = "Grateful Dead";

    List<String> songTitles =
        List.generate(Random().nextInt(3) + 7, (index) => "Song ${index + 1}")
            .toList();

    print(songTitles);

    await isar.writeTxn(() async {
      // Check if the artist exists, if not create a new one
      Artist? artist =
          await isar.artists.filter().nameEqualTo(artistName).findFirst();
      if (artist == null) {
        artist = Artist()..name = artistName;
        await isar.artists.put(artist);
      }

      // Create the new album and link it to the artist
      final album = Album()
        ..title = albumTitle
        ..date = DateTime.now()
        ..artist.value = artist;

      // Save the album
      await isar.albums.put(album);

      // Add the album to the artist's albums list
      artist.albums.add(album);
      await isar.artists.put(artist);

      //print(album.artist);
      print(album.artist.value);
      print(album.artist.value?.name);
      print(album.id);
      //print(album.artist.value?.name == artistName);
      //print(artist);

      // Create and save songs
      for (String title in songTitles) {
        final song = Song(title)
          ..album.value = album
          // ..audioFileUrl =
          //     "https://archive.org/download/gd1984-04-21.166581.mtx.seamons.ht166.flac16/gd84-04-21d1t01.mp3"
          ..audioFileUrl =
              "https://example.com/audio/${DateTime.now().millisecondsSinceEpoch}.mp3"
          ..artist.value = artist;

        await isar.songs.put(song);

        // Link the song to the album and artist
        album.songs.add(song);
        artist.songs.add(song);
        print(album.artist.value?.name);
      }

      // Save the updated album and artist with the linked songs
      await isar.albums.put(album);
      await isar.artists.put(artist);
    });

    var album = await isar.albums.filter().titleEqualTo(albumTitle).findFirst();
    print(album?.title);
    var temp;
    if (album?.title != null) {
      temp = album?.title;
    }

    print(album?.artist.value?.name);
    getAlbumDetails(temp);
  }

  Future<Map<String, dynamic>> getAlbumDetails(String albumTitle) async {
    final isar = IsarService().isar;
    final album =
        await isar.albums.filter().titleEqualTo(albumTitle).findFirst();
    if (album == null) {
      return {};
    }
    final artist = await getArtistForAlbum(album);
    final songs = await getSongsFromAlbum(album);
    return {
      'album': album,
      'artist': artist,
      'songs': songs,
    };
  }

  Future<Artist?> getArtistForAlbum(Album album) async {
    final isar = IsarService().isar;

    // final artist = await isar.artists
    //     .filter()
    //     .albums((q) => q.idEqualTo(album.id))
    //     .findFirst();

    //return await isar.artists.filter().idEqualTo(album.artist.id).findFirst();
    return await isar.artists
        .filter()
        .idEqualTo(album.artist.value!.id)
        .findFirst();

    // return artist;
  }

  getAllSongsFromAlbumInt(int index) {
    final isar = IsarService().isar;
    return isar.albums.where().idEqualTo(index).findFirst();
    //return isar.songs.where().albumIdEqualTo(index).findAll();
  }

  Future<List<Song>> getSongsFromAlbum(Album album) async {
    final isar = IsarService().isar;
    return await isar.songs.filter().albumIdEqualTo(album.id).findAll();
  }
}
