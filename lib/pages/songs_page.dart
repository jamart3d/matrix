
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:myapp/isar_collections/song.dart';
import 'package:myapp/providers/isar_provider.dart';
import 'package:myapp/isar_collections/artist.dart';

class SongsPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isar = ref.watch(isarProvider);

    // Fetch all songs from Isar
    final songs = isar.songs.where().findAllSync();

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Songs'),
      ),
      body: ListView.builder(
        itemCount: songs.length,
        itemBuilder: (context, index) {
          final song = songs[index];
          return ListTile(
            title: Text(song.title),
            subtitle: Text(song.artist?.name ?? 'Unknown Artist'),
            // Add more details like album, duration, etc. if available
          );
        },
      ),
    );
  }
}
