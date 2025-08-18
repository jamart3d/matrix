// lib/pages/albums_page.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:matrix/components/my_drawer.dart';
import 'package:matrix/helpers/album_helper.dart';
import 'package:matrix/models/album.dart';
import 'package:matrix/pages/album_detail_page.dart';
import 'package:matrix/providers/track_player_provider.dart';
import 'package:provider/provider.dart';
import 'package:matrix/services/album_data_service.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:matrix/providers/album_settings_provider.dart';
import 'package:matrix/helpers/archive_alive_helper.dart';
import 'package:logger/logger.dart';

class AlbumsPage extends StatefulWidget {
  const AlbumsPage({super.key});

  @override
  State<AlbumsPage> createState() => _AlbumsPageState();
}

class _AlbumsPageState extends State<AlbumsPage> with AutomaticKeepAliveClientMixin {
  static final Logger _logger = Logger(printer: PrettyPrinter(methodCount: 1));

  late final Future<void> _initializationFuture;

  String _currentAlbumArt = 'assets/images/t_steal.webp';
  String? _currentAlbumName;
  bool _isPageOffline = false;
  Color _backdropColor = Colors.black.withOpacity(0.5);
  bool _connectionChecked = false;

  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializationFuture = AlbumDataService().init();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final trackPlayerProvider = context.watch<TrackPlayerProvider>();
    _updateCurrentAlbumFromProvider(trackPlayerProvider);
  }

  void _onDataLoaded() {
    if (!_connectionChecked) {
      _checkConnection();
      // This now correctly calls the function from album_helper.dart
      preloadAlbumImages(AlbumDataService().albums, context);
      _connectionChecked = true;
    }
  }

  void _updateCurrentAlbumFromProvider(TrackPlayerProvider trackPlayerProvider) {
    final currentlyPlayingSong = trackPlayerProvider.currentTrack;

    if (currentlyPlayingSong == null && _currentAlbumName != null) {
      setState(() {
        _currentAlbumName = null;
        _currentAlbumArt = 'assets/images/t_steal.webp';
      });
      return;
    }

    if (currentlyPlayingSong != null) {
      final newAlbumArt = trackPlayerProvider.currentAlbumArt;
      final newAlbumName = currentlyPlayingSong.albumName;

      if (newAlbumArt != _currentAlbumArt || newAlbumName != _currentAlbumName) {
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

  void _scrollToCurrentAlbum() {
    if (_currentAlbumName != null && _itemScrollController.isAttached) {
      final albums = AlbumDataService().albums;
      final index = albums.indexWhere((album) => album.name == _currentAlbumName);
      if (index != -1) {
        _itemScrollController.scrollTo(
          index: index,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          alignment: 0.5,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: _buildAppBar(),
      drawer: const MyDrawer(),
      body: FutureBuilder<void>(
        future: _initializationFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
          }

          final albums = AlbumDataService().albums;
          WidgetsBinding.instance.addPostFrameCallback((_) => _onDataLoaded());

          return _buildBodyContent(albums);
        },
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      centerTitle: true,
      backgroundColor: Colors.black,
      title: const Text("Select a random matrix -->"),
      actions: [
        IconButton(
          icon: const Icon(Icons.question_mark),
          onPressed: () {
            final albums = AlbumDataService().albums;
            if (albums.isEmpty) {
              _showErrorSnackBar('Please wait for albums to load.');
              return;
            }
            if (_isPageOffline) {
              _showErrorSnackBar('archive.org offline, only release 105 is available.');
              return;
            }
            playRandomAlbum(albums);
          },
          tooltip: 'Random Album',
        ),
      ],
    );
  }

  Widget _buildBodyContent(List<Album> albums) {
    final Color effectiveBackdropColor = _currentAlbumName == null ? Colors.black.withOpacity(0.7) : _backdropColor;

    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(_currentAlbumArt),
          fit: BoxFit.cover,
          onError: (exception, stackTrace) {
            if (mounted) setState(() => _currentAlbumArt = 'assets/images/t_steal.webp');
          },
        ),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          color: effectiveBackdropColor,
          child: _buildAlbumList(albums),
        ),
      ),
    );
  }

  Widget _buildAlbumList(List<Album> albums) {
    if (albums.isEmpty) {
      return const Center(child: Text("No albums available.", style: TextStyle(color: Colors.white)));
    }
    return Consumer<AlbumSettingsProvider>(
      builder: (context, albumSettings, child) {
        return ScrollablePositionedList.builder(
          itemScrollController: _itemScrollController,
          itemPositionsListener: _itemPositionsListener,
          itemCount: albums.length,
          itemBuilder: (context, index) {
            final album = albums[index];
            return _buildAlbumListItem(album, albumSettings);
          },
        );
      },
    );
  }

  Widget _buildAlbumListItem(Album album, AlbumSettingsProvider albumSettings) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AlbumDetailPage(
            tracks: album.tracks,
            albumArt: album.albumArt,
            albumName: album.name,
          ),
        ),
      ),
      onLongPress: () {
        if (_isPageOffline && album.releaseNumber != 105) {
          _showErrorSnackBar('archive.org offline, only release 105 is available.');
          return;
        }
        playAlbumFromTracks(album.tracks);
      },
      child: _buildAlbumCard(album, albumSettings),
    );
  }

  Widget _buildAlbumCard(Album album, AlbumSettingsProvider albumSettings) {
    final isCurrentAlbum = _currentAlbumName == album.name;
    return Card(
      elevation: 0,
      color: Colors.transparent,
      child: Row(
        children: [
          _buildAlbumArt(album, isCurrentAlbum),
          _buildAlbumInfo(album, albumSettings, isCurrentAlbum),
        ],
      ),
    );
  }

  Widget _buildAlbumArt(Album album, bool isCurrentAlbum) {
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
                image: AssetImage(album.albumArt),
                fit: BoxFit.cover,
              ),
            ),
          ),
          if (album.releaseNumber == 105)
            Positioned(
              bottom: 4,
              right: 4,
              child: Icon(Icons.album, color: Colors.green.shade400, size: 16),
            ),
        ],
      ),
    );
  }

  Widget _buildAlbumInfo(Album album, AlbumSettingsProvider albumSettings, bool isCurrentAlbum) {
    final shadowColor = Colors.redAccent;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(left: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              albumSettings.displayAlbumReleaseNumber
                  ? '${album.releaseNumber}. ${formatAlbumName(album.name)}'
                  : formatAlbumName(album.name),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: isCurrentAlbum ? Colors.yellow : Colors.white,
                shadows: isCurrentAlbum ? [Shadow(color: shadowColor, blurRadius: 4)] : null,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              extractDateFromAlbumName(album.name),
              style: TextStyle(fontSize: 12, color: isCurrentAlbum ? Colors.yellow.withOpacity(0.8) : Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _checkConnection() async {
    try {
      final result = await checkConnectionWithRetries(
        retryCount: 1,
        onPageOffline: (isOffline) {
          if (mounted) setState(() => _isPageOffline = isOffline);
        },
      );
      if (result != 'Connection Successful' && mounted) {
        _showSiteUnavailableDialog('Failed to connect to archive.org. Only release 105 is available.');
      }
    } catch (e, stackTrace) {
      _logger.e('Connection check failed', error: e, stackTrace: stackTrace);
      if (mounted) _showErrorSnackBar('Connection check failed.');
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
    final albums = AlbumDataService().albums;
    final offlineAlbumIndex = albums.indexWhere((album) => album.releaseNumber == 105);

    if (offlineAlbumIndex == -1) {
      _showErrorSnackBar('Offline album data (Release 105) not found.');
      return;
    }
    final offlineAlbum = albums[offlineAlbumIndex];

    setState(() => _backdropColor = Colors.red.withOpacity(0.5));
    context.read<AlbumSettingsProvider>().setDisplayAlbumReleaseNumber(true);
    await playAlbumFromTracks(offlineAlbum.tracks);
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Widget? _buildFloatingActionButton() {
    final playerProvider = context.watch<TrackPlayerProvider>();
    if (playerProvider.isLoading) {
      return FloatingActionButton(
        onPressed: null,
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const SizedBox(
          width: 50, height: 50,
          child: CircularProgressIndicator(strokeWidth: 3.0, valueColor: AlwaysStoppedAnimation<Color>(Colors.yellow)),
        ),
      );
    }
    if (playerProvider.currentTrack != null) {
      return FloatingActionButton(
        onPressed: () {
          _scrollToCurrentAlbum();
          Navigator.pushNamed(context, '/music_player_page');
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const Icon(Icons.play_circle_fill, color: Colors.yellow, shadows: [Shadow(color: Colors.redAccent, blurRadius: 4)], size: 50),
      );
    }
    return null;
  }
}