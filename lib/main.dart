// lib/main.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:matrix/pages/about_page.dart';
import 'package:matrix/pages/albums_list_wheel_page.dart';
import 'package:matrix/pages/albums_page.dart';
import 'package:matrix/pages/matrix_rain_page.dart';
import 'package:matrix/pages/matrix_music_player_page.dart';
import 'package:matrix/pages/music_player_page.dart';
import 'package:matrix/pages/settings_page.dart';
import 'package:matrix/pages/shows_page.dart';
import 'package:matrix/pages/track_playlist_page.dart';
import 'package:matrix/providers/track_player_provider.dart';
import 'package:matrix/providers/album_settings_provider.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:matrix/utils/load_shows_data.dart';
import 'package:provider/provider.dart';
import 'package:audio_session/audio_session.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:matrix/pages/shows_music_player_page.dart';
import 'package:app_links/app_links.dart';
import 'helpers/shows_helper.dart';
import 'services/navigation_service.dart';
import 'package:matrix/routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  PaintingBinding.instance.imageCache.maximumSizeBytes = 1024 * 1024 * 150; // 150 MB
  PaintingBinding.instance.imageCache.maximumSize = 1000;

  if (kDebugMode) {
    final logger = Logger();
    final stopwatch = Stopwatch()..start();
    logger.i('Starting parallel initializations...');
    await Future.wait([_initializeAudioBackground(), _configureAudioSession()]);
    stopwatch.stop();
    logger.i('Finished all initializations in ${stopwatch.elapsedMilliseconds} ms');
  } else {
    await Future.wait([_initializeAudioBackground(), _configureAudioSession()]);
  }

  runApp(const Matrix());
}

Future<void> _initializeAudioBackground() async {
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.matrix.audio_channel',
    androidNotificationChannelName: 'HunTrix Audio Playback',
    androidNotificationOngoing: true,
    androidNotificationIcon: 'mipmap/ic_launcher',
    preloadArtwork: true,
  );
}

Future<void> _configureAudioSession() async {
  final session = await AudioSession.instance;
  await session.configure(const AudioSessionConfiguration.music());
}

class Matrix extends StatefulWidget {
  const Matrix({super.key});
  @override
  State<Matrix> createState() => _MatrixState();
}

class _MatrixState extends State<Matrix> {
  final AppLinks _appLinks = AppLinks();
  String _initialRoute = Routes.showsPage; // Default route
  bool _isInitialized = false;
  final Logger _logger = Logger();

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final prefs = await SharedPreferences.getInstance();

    const String startupPageKey = 'startupPage';
    const String oldSkipShowsPageKey = 'skipShowsPage';
    String route = Routes.showsPage;

    if (prefs.containsKey(oldSkipShowsPageKey)) {
      final bool oldSkipShows = prefs.getBool(oldSkipShowsPageKey) ?? false;
      final int newIndex = oldSkipShows ? 1 : 0;
      await prefs.setInt(startupPageKey, newIndex);
      await prefs.remove(oldSkipShowsPageKey);
    }

    final startupPageIndex = prefs.getInt(startupPageKey) ?? 0;

    switch (startupPageIndex) {
      case 0: route = Routes.showsPage; break;
      case 1: route = Routes.albumsPage; break;
      case 2: route = Routes.matrixRainPage; break;
    }

    setState(() {
      _initialRoute = route;
      _isInitialized = true;
    });

    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    try {
      final initialUri = await _appLinks.getInitialAppLink();
      if (initialUri != null) _handleDeepLink(initialUri);
    } catch (e) {
      _logger.e('Failed to get initial app link: $e');
    }
    _appLinks.uriLinkStream.listen((Uri uri) => _handleDeepLink(uri),
      onError: (err) => _logger.e('Deep link stream error: $err'),
    );
  }

  Future<void> _handleDeepLink(Uri uri) async {
    _logger.i("Deep Link Received: ${uri.toString()}");
    if (uri.path == '/playRandomShow') {
      _logger.i("Handling Play Random Show command!");
      await Future.delayed(const Duration(seconds: 2));
      try {
        final shows = await loadShowsData();
        if (shows.isNotEmpty) {
          final context = NavigationService().navigatorKey.currentContext;
          if (context != null && context.mounted) {
            final playerProvider = Provider.of<TrackPlayerProvider>(context, listen: false);
            playerProvider.setInitiatedByDeepLink();
            playRandomShow(playerProvider, shows);
            Navigator.pushNamed(context, Routes.showsMusicPlayerPage);
          }
        }
      } catch (e) {
        _logger.e("Error handling deep link: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.black,
          body: Center(child: CircularProgressIndicator(color: Colors.deepPurple)),
        ),
      );
    }
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
        initialRoute: _initialRoute,
        routes: _buildRoutes(),
      ),
    );
  }
}

ThemeData _buildTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple, brightness: Brightness.dark),
    visualDensity: VisualDensity.adaptivePlatformDensity,
    sliderTheme: const SliderThemeData(trackHeight: 3.0, thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6.0)),
  );
}

Map<String, WidgetBuilder> _buildRoutes() {
  return {
    Routes.showsPage: (context) => const ShowsPage(),
    Routes.albumsPage: (context) => const AlbumsPage(),
    Routes.musicPlayerPage: (context) => const MusicPlayerPage(),
    Routes.showsMusicPlayerPage: (context) => const ShowsMusicPlayerPage(),
    Routes.trackPlaylistPage: (context) => const TrackPlaylistPage(),
    Routes.albumsListWheelPage: (context) => const AlbumListWheelPage(),
    Routes.matrixRainPage: (context) => const MatrixRainPage(),
    Routes.settingsPage: (context) => const SettingsPage(),
    Routes.matrixMusicPlayerPage: (context) => const MatrixMusicPlayerPage(),
    Routes.aboutPage: (context) => const AboutPage(),
  };
}