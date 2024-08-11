
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:myapp/services/isar_service.dart';
import 'isar_collections/album.dart';
import 'isar_collections/artist.dart';
import 'isar_collections/song.dart';
import 'providers/playlist_provider.dart';
import '../providers/isar_provider.dart';







void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final isar = await IsarService().openDB(); 



  runApp(
    ProviderScope(
      overrides: [
        isarProvider.overrideWithValue(isar),
      ],
      child: MyApp(),
    ),
  );
}


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Music App',
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlist = ref.watch(playlistProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Music App'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('Playlist: ${playlist.length} songs'),
            // Artist section (show empty if no artists)
            Text('Artists: ${ref.watch(artistCountProvider) == 0 ? "No Artists" : ""}'),
            // Empty album page
            Text('Albums:'),
            ElevatedButton(
              onPressed: () {
                // Navigate to empty album page
              },
              child: Text('View Albums'),
            ),
          ],
        ),
      ),
    );
  }
}

final artistCountProvider = Provider((ref) {
  final isar = ref.watch(isarProvider);
  return isar.artists.countSync();
});
