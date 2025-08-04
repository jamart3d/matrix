import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:huntrix/pages/albums_list_wheel_page.dart';
import 'package:huntrix/pages/albums_page.dart';
import 'package:huntrix/pages/music_player_page.dart';
import 'package:huntrix/pages/track_playlist_page.dart';
import 'package:huntrix/providers/track_player_provider.dart';
import 'package:huntrix/pages/albums_grid_page.dart';
import 'package:huntrix/providers/album_settings_provider.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:provider/provider.dart';
import 'package:audio_session/audio_session.dart';
import 'package:logger/logger.dart';

// Import the encapsulated NavigationService
import 'services/navigation_service.dart'; // Make sure this path is correct

Future<void> main() async {
  // 1. Ensure Flutter binding is initialized.
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Set a reasonable image cache size.
  // This is a good practice for apps with many images.
  PaintingBinding.instance.imageCache.maximumSizeBytes = 1024 * 1024 * 150; // 150 MB
  PaintingBinding.instance.imageCache.maximumSize = 1000;

  // 3. Perform asynchronous initializations.
  // Use logging in debug mode to monitor startup time without impacting release performance.
  if (kDebugMode) {
    final logger = Logger();
    final stopwatch = Stopwatch()..start();
    logger.i('Starting parallel initializations...');
    
    // Run independent tasks in parallel to speed up app launch.
    await Future.wait([
      _initializeAudioBackground(),
      _configureAudioSession(),
    ]);
    
    stopwatch.stop();
    logger.i('Finished all initializations in ${stopwatch.elapsedMilliseconds} ms');
  } else {
    // In release mode, just run the initializations.
    await Future.wait([
      _initializeAudioBackground(),
      _configureAudioSession(),
    ]);
  }
  
  // 4. Run the app.
  runApp(const HunTrix());
}

/// Initializes just_audio_background for background audio controls.
Future<void> _initializeAudioBackground() async {
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.huntrix.audio_channel',
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

class HunTrix extends StatelessWidget {
  const HunTrix({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => TrackPlayerProvider()),
        ChangeNotifierProvider(create: (context) => AlbumSettingsProvider()),
      ],
      child: MaterialApp(
        // Use the navigatorKey from the singleton NavigationService instance.
        // This is the crucial step to link the service to the app's navigator.
        navigatorKey: NavigationService().navigatorKey, 
        debugShowCheckedModeBanner: false,
        title: 'HunTrix',
        theme: _buildTheme(),
        initialRoute: Routes.albumsPage,
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

/// A private top-level function to define the app's routes.
Map<String, WidgetBuilder> _buildRoutes() {
  return {
    Routes.albumsPage: (context) => const AlbumsPage(),
    Routes.musicPlayerPage: (context) => const MusicPlayerPage(),
    Routes.trackPlaylistPage: (context) => const TrackPlaylistPage(),
    Routes.albumsListWheelPage: (context) => const AlbumListWheelPage(),
    Routes.albumsGridPage: (context) => const AlbumsGridPage(),
  };
}

/// Route constants for clean and maintainable navigation.
class Routes {
  static const String albumsPage = '/albums_page';
  static const String musicPlayerPage = '/music_player_page';
  static const String trackPlaylistPage = '/song_playlist_page';
  static const String albumsListWheelPage = '/albums_list_wheel_page';
  static const String albumsGridPage = '/albums_grid_page';
}