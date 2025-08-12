import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:matrix/pages/albums_list_wheel_page.dart';
import 'package:matrix/pages/albums_page.dart';
import 'package:matrix/pages/music_player_page.dart';
import 'package:matrix/pages/settings_page.dart';
import 'package:matrix/pages/shows_page.dart';
import 'package:matrix/pages/track_playlist_page.dart';
import 'package:matrix/providers/track_player_provider.dart';
import 'package:matrix/pages/albums_grid_page.dart';
import 'package:matrix/providers/album_settings_provider.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:provider/provider.dart';
import 'package:audio_session/audio_session.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:matrix/pages/shows_music_player_page.dart'; 


// Import the encapsulated NavigationService
import 'services/navigation_service.dart';

Future<void> main() async {
  // 1. Ensure Flutter binding is initialized.
  WidgetsFlutterBinding.ensureInitialized();

  // --- START: MODIFIED STARTUP LOGIC ---
  
  // 2. Load SharedPreferences to read the setting before the app starts.
  final prefs = await SharedPreferences.getInstance();
  // Read the 'skipShowsPage' setting, defaulting to 'false' if it doesn't exist.
  final bool skipShowsPage = prefs.getBool('skipShowsPage') ?? false;

  // 3. Determine the initial route based on the setting.
  final String initialRoute = skipShowsPage ? Routes.albumsPage : Routes.showsPage;

  // --- END: MODIFIED STARTUP LOGIC ---

  // 4. Set a reasonable image cache size.
  PaintingBinding.instance.imageCache.maximumSizeBytes = 1024 * 1024 * 150; // 150 MB
  PaintingBinding.instance.imageCache.maximumSize = 1000;

  // 5. Perform asynchronous initializations.
  if (kDebugMode) {
    final logger = Logger();
    final stopwatch = Stopwatch()..start();
    logger.i('Starting parallel initializations...');
    
    await Future.wait([
      _initializeAudioBackground(),
      _configureAudioSession(),
    ]);
    
    stopwatch.stop();
    logger.i('Finished all initializations in ${stopwatch.elapsedMilliseconds} ms');
  } else {
    await Future.wait([
      _initializeAudioBackground(),
      _configureAudioSession(),
    ]);
  }
  
  // 6. Run the app, passing in the determined initialRoute.
  runApp(Matrix(initialRoute: initialRoute));
}

/// Initializes just_audio_background for background audio controls.
Future<void> _initializeAudioBackground() async {
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.matrix.audio_channel',
    androidNotificationChannelName: 'HunTrix Audio Playback',
    androidNotificationOngoing: true,
    androidNotificationIcon: 'mipmap/ic_launcher',
    preloadArtwork: true,
  );
}

/// Configures the audio session for music playback.
Future<void> _configureAudioSession() async {
  final session = await AudioSession.instance;
  await session.configure(const AudioSessionConfiguration.music());
}

class Matrix extends StatelessWidget {
  // Accept the initialRoute as a constructor parameter.
  final String initialRoute;
  const Matrix({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => TrackPlayerProvider()),
        ChangeNotifierProvider(create: (context) => AlbumSettingsProvider()),
      ],
      child: MaterialApp(
        navigatorKey: NavigationService().navigatorKey, 
        debugShowCheckedModeBanner: false,
        title: 'Matrix',
        theme: _buildTheme(),
        // Use the initialRoute that was determined in main() and passed here.
        initialRoute: initialRoute,
        routes: _buildRoutes(),
      ),
    );
  }
}

/// A private top-level function to build the app's theme.
ThemeData _buildTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.deepPurple,
      brightness: Brightness.dark,
    ),
    visualDensity: VisualDensity.adaptivePlatformDensity,
    sliderTheme: const SliderThemeData(
      trackHeight: 3.0,
      thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6.0),
    ),
  );
}

/// A private top-level function to define all the app's routes.
Map<String, WidgetBuilder> _buildRoutes() {
  return {
    Routes.showsPage: (context) => const ShowsPage(),
    Routes.albumsPage: (context) => const AlbumsPage(),
    Routes.musicPlayerPage: (context) => const MusicPlayerPage(),
    Routes.showsMusicPlayerPage: (context) => const ShowsMusicPlayerPage(),
    Routes.trackPlaylistPage: (context) => const TrackPlaylistPage(),
    Routes.albumsListWheelPage: (context) => const AlbumListWheelPage(),
    Routes.albumsGridPage: (context) => const AlbumsGridPage(),
    Routes.settingsPage: (context) => const SettingsPage(),
  };
}

/// Route constants for clean and maintainable navigation.
class Routes {
  static const String showsPage = '/'; // ShowsPage is now the root.
  static const String albumsPage = '/albums_page';
  static const String musicPlayerPage = '/music_player_page';
  static const String showsMusicPlayerPage = '/shows_music_player_page';
  static const String trackPlaylistPage = '/song_playlist_page';
  static const String albumsListWheelPage = '/albums_list_wheel_page';
  static const String albumsGridPage = '/albums_grid_page';
  static const String settingsPage = '/settings_page';
}