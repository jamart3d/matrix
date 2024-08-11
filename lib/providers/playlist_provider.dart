// TODO Implement this library.
// providers/playlist_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../isar_collections/song.dart';

final playlistProvider = StateProvider<List<Song>>((ref) => []);
