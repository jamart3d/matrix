import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:huntrix/components/my_drawer.dart';
import 'package:huntrix/helpers/album_helper.dart';
import 'package:huntrix/models/track.dart';
import 'package:huntrix/pages/album_detail_page.dart';
import 'package:huntrix/pages/albums_grid_page.dart';
import 'package:huntrix/providers/track_player_provider.dart';
import 'package:provider/provider.dart';
import 'package:huntrix/utils/load_json_data.dart';
import 'package:huntrix/utils/album_utils.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:huntrix/providers/album_settings_provider.dart';
import 'package:huntrix/helpers/archive_alive_helper.dart';
import 'package:logger/logger.dart';

class AlbumsPage extends StatefulWidget {
  const AlbumsPage({super.key});

  @override
  State<AlbumsPage> createState() => _AlbumsPageState();
}

class _AlbumsPageState extends State<AlbumsPage>
    with AutomaticKeepAliveClientMixin {
  // Logger instance
  static final Logger _logger = Logger(
    printer: PrettyPrinter(methodCount: 1),
  );

  // Constants
  static const int _offlineAlbumIndex = 104;
  static const String _defaultAlbumArt = 'assets/images/t_steal.webp';
  static const Duration _scrollDuration = Duration(milliseconds: 500);
  static const int _connectionRetryCount = 1;

  // State variables
  List<Map<String, dynamic>>? _cachedAlbumData;
  String _currentAlbumArt = _defaultAlbumArt;
  String? _currentAlbumName;
  bool _isPageOffline = false;
  Color _backdropColor = Colors.black.withOpacity(0.5);

  // Controllers
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final trackPlayerProvider = context.watch<TrackPlayerProvider>();
    _updateCurrentAlbumFromProvider(trackPlayerProvider);
  }

  Future<void> _initializeData() async {
    await _loadData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkConnection();
    });
  }

  void _updateCurrentAlbumFromProvider(TrackPlayerProvider trackPlayerProvider) {
    final currentlyPlayingSong = trackPlayerProvider.currentlyPlayingSong;

    if (currentlyPlayingSong == null && _currentAlbumName != null) {
      setState(() {
        _currentAlbumName = null;
        _currentAlbumArt = _defaultAlbumArt;
      });
      return;
    }

    if (currentlyPlayingSong != null) {
      final newAlbumArt = currentlyPlayingSong.albumArt ?? _defaultAlbumArt;
      final newAlbumName = currentlyPlayingSong.albumName;

      if (newAlbumArt != _currentAlbumArt || newAlbumName != _currentAlbumName) {
        _logger.d('Player changed album. Updating UI for: $newAlbumName');
        setState(() {
          _currentAlbumArt = newAlbumArt;
          _currentAlbumName = newAlbumName;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _scrollToCurrentAlbum();
        });
      }
    }
  }

  Future<void> _loadData() async {
    try {
      _logger.i('Loading album data...');
      await loadData(context, (albumData) {
        if (mounted) {
          setState(() {
            _cachedAlbumData = albumData;
          });
          if (albumData != null) {
            preloadAlbumImages(albumData, context);
          }
        }
      });
    } catch (e, stackTrace) {
      _logger.e('Failed to load album data', error: e, stackTrace: stackTrace);
      _showErrorSnackBar('Failed to load album data.');
    }
  }

  Future<void> _checkConnection() async {
    try {
      final result = await checkConnectionWithRetries(
        retryCount: _connectionRetryCount,
        onPageOffline: (isOffline) {
          if (mounted) setState(() => _isPageOffline = isOffline);
        },
      );
      if (result != 'Connection Successful' && mounted) {
        _showSiteUnavailableDialog(
          '${_getConnectionErrorMessage(result)}\n\nRetry attempts: $_connectionRetryCount',
        );
      }
    } catch (e, stackTrace) {
      _logger.e('Connection check failed', error: e, stackTrace: stackTrace);
      if (mounted) _showErrorSnackBar('Connection check failed.');
    }
  }

  String _getConnectionErrorMessage(String result) {
    // ... (same as before)
    switch (result) {
      case 'Temporarily Offline.\nonly release 105 is available.':
        return 'The archive.org page is temporarily offline.\nOnly release 105 is available.';
      case 'No Internet Connection':
        return 'No internet connection.\nOnly release 105 is available.';
      default:
        return 'Failed to connect to archive.org.\nOnly release 105 is available.';
    }
  }

  void _showSiteUnavailableDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Connection Issue', style: TextStyle(color: Colors.red)),
          backgroundColor: Colors.black.withOpacity(0.8),
          content: Text(message, style: const TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              child: const Text('OK', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _handleConnectionError();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleConnectionError() async {
    if (_cachedAlbumData == null || _offlineAlbumIndex >= _cachedAlbumData!.length) {
      _showErrorSnackBar('Offline album data is not available.');
      return;
    }
    setState(() => _backdropColor = Colors.red.withOpacity(0.5));
    context.read<AlbumSettingsProvider>().setDisplayAlbumReleaseNumber(true);
    final offlineAlbum = _cachedAlbumData![_offlineAlbumIndex];
    final albumTracks = offlineAlbum['songs'] as List<Track>;
    await playAlbumFromTracks(albumTracks);
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (MediaQuery.of(context).size.width > 600) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AlbumsGridPage()),
        );
      });
      return const SizedBox.shrink();
    }
    return Scaffold(
      appBar: _buildAppBar(),
      drawer: const MyDrawer(),
      body: _buildBody(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      centerTitle: true,
      backgroundColor: Colors.black,
      title: const Text("Select a random trix -->"),
      actions: [
        IconButton(
          icon: const Icon(Icons.question_mark),
          onPressed: () {
            if (_cachedAlbumData == null || _cachedAlbumData!.isEmpty) {
              _showErrorSnackBar('Please wait for albums to load.');
              return;
            }
            if (_isPageOffline) {
              _showErrorSnackBar('archive.org offline, only release 105 is available.');
              return;
            }
            playRandomAlbum(_cachedAlbumData!);
          },
          tooltip: 'Random Album',
        ),
      ],
    );
  }

  void _scrollToCurrentAlbum() {
    if (_currentAlbumName != null && _cachedAlbumData != null) {
      final index = _cachedAlbumData!.indexWhere((album) => album['album'] == _currentAlbumName);
      if (index != -1 && _itemScrollController.isAttached) {
        _itemScrollController.scrollTo(
          index: index,
          duration: _scrollDuration,
          curve: Curves.easeInOut,
          alignment: 0.5,
        );
      }
    }
  }

  Widget _buildBody() {
    final Color effectiveBackdropColor = _currentAlbumName == null
        ? Colors.black.withOpacity(0.7)
        : _backdropColor;
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(_currentAlbumArt),
          fit: BoxFit.cover,
          onError: (exception, stackTrace) {
            _logger.e('Error loading background image.', error: exception);
            setState(() => _currentAlbumArt = _defaultAlbumArt);
          },
        ),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          color: effectiveBackdropColor,
          child: _buildAlbumContent(),
        ),
      ),
    );
  }

  Widget _buildAlbumContent() {
    if (_cachedAlbumData == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_cachedAlbumData!.isEmpty) {
      return const Center(child: Text("No albums available.", style: TextStyle(color: Colors.white)));
    }
    return Consumer<AlbumSettingsProvider>(
      builder: (context, albumSettings, child) {
        return ScrollablePositionedList.builder(
          itemScrollController: _itemScrollController,
          itemPositionsListener: _itemPositionsListener,
          itemCount: _cachedAlbumData!.length,
          itemBuilder: (context, index) => _buildAlbumListItem(index, albumSettings),
        );
      },
    );
  }

  Widget _buildAlbumListItem(int index, AlbumSettingsProvider albumSettings) {
    final album = _cachedAlbumData![index];
    final albumTracks = album['songs'] as List<Track>;
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AlbumDetailPage(
            tracks: albumTracks,
            albumArt: album['albumArt'] as String,
            albumName: album['album'] as String,
          ),
        ),
      ),
      onLongPress: () {
        if (_isPageOffline && index != _offlineAlbumIndex) {
          _showErrorSnackBar('archive.org offline, only release 105 is available.');
          return;
        }
        playAlbumFromTracks(albumTracks);
      },
      child: _buildAlbumCard(album, albumSettings),
    );
  }

  Widget _buildAlbumCard(Map<String, dynamic> album, AlbumSettingsProvider albumSettings) {
    // ... (same as before)
    final albumName = album['album'] as String;
    final albumArt = album['albumArt'] as String;
    final index = _cachedAlbumData!.indexOf(album);

    final isCurrentAlbum = _currentAlbumName == albumName;
    final shadowColor = Colors.redAccent;

    return Card(
      elevation: 0,
      color: Colors.transparent,
      child: Row(
        children: [
          _buildAlbumArt(albumArt, index, isCurrentAlbum),
          _buildAlbumInfo(albumName, index, albumSettings, isCurrentAlbum, shadowColor),
        ],
      ),
    );
  }

  Widget _buildAlbumArt(String albumArt, int index, bool isCurrentAlbum) {
    // ... (same as before)
    final screenWidth = MediaQuery.of(context).size.width;
    return ClipRRect(
      borderRadius: BorderRadius.circular(4.0),
      child: Stack(
        children: [
          Container(
            width: screenWidth * 0.28,
            height: screenWidth * 0.28,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4.0),
              border: Border.all(
                color: isCurrentAlbum ? Colors.yellow : Colors.white24,
                width: isCurrentAlbum ? 2.0 : 1.0,
              ),
              image: DecorationImage(
                image: AssetImage(albumArt),
                fit: BoxFit.cover,
              ),
            ),
          ),
          if (index == _offlineAlbumIndex)
            Positioned(
              bottom: 4,
              right: 4,
              child: Icon(Icons.album, color: Colors.green.shade400, size: 16),
            ),
        ],
      ),
    );
  }

  Widget _buildAlbumInfo(String albumName, int index, AlbumSettingsProvider albumSettings, bool isCurrentAlbum, Color shadowColor) {
    // ... (same as before)
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(left: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              albumSettings.displayAlbumReleaseNumber
                  ? '${index + 1}. ${formatAlbumName(albumName)}'
                  : formatAlbumName(albumName),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: isCurrentAlbum ? Colors.yellow : Colors.white,
                shadows: isCurrentAlbum
                    ? [Shadow(color: shadowColor, blurRadius: 4)] : null,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              extractDateFromAlbumName(albumName),
              style: TextStyle(
                fontSize: 12,
                color: isCurrentAlbum ? Colors.yellow.withOpacity(0.8) : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildFloatingActionButton() {
    final playerProvider = context.watch<TrackPlayerProvider>();

    if (playerProvider.isLoading) {
      return FloatingActionButton(
        onPressed: null,
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const SizedBox(
          width: 50,
          height: 50,
          child: CircularProgressIndicator(
            strokeWidth: 3.0,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.yellow),
          ),
        ),
      );
    }

    if (playerProvider.currentlyPlayingSong != null) {
      return FloatingActionButton(
        onPressed: () {
          _scrollToCurrentAlbum();
          Navigator.pushNamed(context, '/music_player_page');
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const Icon(
          Icons.play_circle_fill,
          color: Colors.yellow,
          shadows: [Shadow(color: Colors.redAccent, blurRadius: 4)],
          size: 50,
        ),
      );
    }

    return null;
  }
}
