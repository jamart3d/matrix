import 'package:flutter/material.dart';
import 'package:myapp/isar_collections/album.dart';
import 'package:myapp/isar_collections/song.dart';
import '../services/isar_service.dart';

class AlbumsPage extends StatelessWidget {
  const AlbumsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var isarService = IsarService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Albums'),
      ),
      body: FutureBuilder(
          future: isarService.getAlbums(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              List<Album> albums = snapshot.data as List<Album>;
              if (albums.isNotEmpty) {
                return ListView.builder(
                  itemCount: albums.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(albums[index].title),
                      trailing: albums[index].imageUrl != null
                          ? Image.network(albums[index].imageUrl!)
                          : Image.asset("assets/images/trans_steal.png"),

                      subtitle:
                          Text('Artist: ${albums[index].artist.value?.name}'),
                      onTap: () async {
                        //print(albums[index].title);

                        // var aristF =
                        //     isarService.getArtistForAlbum(albums[index]);
                        // final aristF1 = await aristF;
                        //print(aristF1?.name);
                        //print(albums[index].artist.value?.name);
                        // Handle album tap
                        // final songsFuture =
                        //     isarService.getAllSongsFromAlbum(index);
                        // final songs = await songsFuture;

                        //print(songs);
                        print(albums[index].title);
                        print(albums[index].artist.value?.name);
                        print(albums);
                        print(index);
                        print(albums[index]);
                        print(albums[index].artist);
                        print(albums[index].artist.value);

                        // for (var song in albums[index].songs) {
                        //   print(song);
                        //   print("poop");
                        // }
                        // for (var song in albums[index].songs.value) {
                        //   print(song);
                        // }

                        // for (var song in songs) {
                        //   print(song);
                        // }
                        // Navigate to the album details screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AlbumDetailsPage(
                              album: albums[index],
                            ),
                          ),
                        );
                      },
                      // Add other album details here
                    );
                  },
                );
              } else {
                return const Center(child: Text('No albums found'));
              }
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else {
              return const Center(child: CircularProgressIndicator());
            }
          }),
    );
  }
}

class AlbumDetailsPage extends StatelessWidget {
  final Album album;

  AlbumDetailsPage({required this.album});

  @override
  Widget build(BuildContext context) {
    var isarService = IsarService();
    return Scaffold(
      appBar: AppBar(
        title: Text(album.title),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Artist: ${album.artist.value?.name}',
              style: const TextStyle(fontSize: 18),
            ),
          ),
          Expanded(
            child: FutureBuilder(
              future: isarService.getSongsFromAlbum(album),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  List<Song> songs = snapshot.data as List<Song>;
                  if (songs.isNotEmpty) {
                    return ListView.builder(
                      itemCount: songs.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(songs[index].title),
                          subtitle: Text('Duration: ${songs[index].duration}'),
                        );
                      },
                    );
                  } else {
                    return const Center(child: Text('No songs found'));
                  }
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else {
                  return const Center(child: CircularProgressIndicator());
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
