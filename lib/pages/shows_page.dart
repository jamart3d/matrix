import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:huntrix/helpers/shows_helper.dart';
import 'package:huntrix/models/show.dart';
import 'package:huntrix/models/track.dart';
import 'package:huntrix/providers/track_player_provider.dart';
import 'package:huntrix/utils/load_shows_data.dart';
import 'package:huntrix/utils/duration_formatter.dart';
import 'package:provider/provider.dart';
import 'package:huntrix/components/my_drawer.dart'; // Import for the drawer

class ShowsPage extends StatefulWidget {
  const ShowsPage({super.key});

  @override
  State<ShowsPage> createState() => _ShowsPageState();
}

class _ShowsPageState extends State<ShowsPage> with AutomaticKeepAliveClientMixin {
  late final Future<List<Show>> _showsFuture;
  
  static const String _defaultAlbumArt = 'assets/images/t_steal.webp';
  String _currentAlbumArt = _defaultAlbumArt;
  String? _currentShowName;

  final ScrollController _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _showsFuture = loadShowsData(context);
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.watch<TrackPlayerProvider>();
    final newShowName = provider.currentAlbumTitle;
    final newAlbumArt = provider.currentAlbumArt;

    // If the show changes, update our local state to track it.
    if (_currentShowName != newShowName) {
      setState(() => _currentShowName = newShowName);
    }
    
    // Update background art, falling back to default if necessary.
    if (newAlbumArt.isNotEmpty && _currentAlbumArt != newAlbumArt) {
      setState(() => _currentAlbumArt = newAlbumArt);
    } else if (provider.currentTrack == null && _currentAlbumArt != _defaultAlbumArt) {
      setState(() => _currentAlbumArt = _defaultAlbumArt);
    }
  }

  /// **Refactored: Centralized scroll logic.**
  Future<void> _scrollToCurrentShow() async {
    if (_currentShowName == null || !_scrollController.hasClients) return;
    
    try {
      final shows = await _showsFuture;
      final index = shows.indexWhere((show) => show.name == _currentShowName);

      if (index != -1) {
        final itemHeight = 76.0; // Approximate height of a Card + margin
        final targetOffset = (index * itemHeight) - (MediaQuery.of(context).size.height / 4);
        
        await _scrollController.animateTo(
          targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    } catch (e) {
      debugPrint("Error scrolling to show: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      // **AppBar is now consistent with AlbumsPage**
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.black,
        title: const Text("Select a random show -->"),
        actions: [
          IconButton(
            icon: const Icon(Icons.question_mark),
            tooltip: 'Play Random Show',
            onPressed: () async {
              // Simpler random play logic
              final shows = await _showsFuture;
              playRandomShow(shows);
            },
          ),
        ],
      ),
      drawer: const MyDrawer(),
      floatingActionButton: _buildFloatingActionButton(),
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildBlurredBackground(),
          _buildShowsList(),
        ],
      ),
    );
  }

  Widget _buildBlurredBackground() {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(image: AssetImage(_currentAlbumArt), fit: BoxFit.cover),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(color: Colors.black.withOpacity(0.3)),
      ),
    );
  }

  Widget _buildShowsList() {
    return FutureBuilder<List<Show>>(
      future: _showsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || snapshot.data!.isEmpty) {
          return const Center(child: Text('Could not load shows.'));
        }

        final shows = snapshot.data!;
        return SafeArea(
          child: ListView.builder(
            controller: _scrollController,
            itemCount: shows.length,
            itemBuilder: (context, index) {
              final show = shows[index];
              final bool isCurrentShow = show.name == _currentShowName;

              return GestureDetector(
                onLongPress: () {
                  playShowFromTracks(show);
                  Navigator.pushNamed(context, '/shows_music_player_page');
                },
                child: Card(
                  color: isCurrentShow ? Colors.yellow.withOpacity(0.2) : Colors.black.withOpacity(0.4),
                  margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: ExpansionTile(
                    title: Text(
                      show.name,
                      style: TextStyle(
                        color: isCurrentShow ? Colors.yellow : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      show.artist,
                      style: TextStyle(color: isCurrentShow ? Colors.yellow.withOpacity(0.8) : Colors.grey.shade300),
                    ),
                    iconColor: isCurrentShow ? Colors.yellow : Colors.white,
                    collapsedIconColor: Colors.white70,
                    children: show.tracks.map((track) => _buildTrackTile(track, show)).toList(),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildTrackTile(Track track, Show parentShow) {
    final provider = context.watch<TrackPlayerProvider>();
    final bool isCurrentlyPlaying = provider.currentTrack == track;

    return Container(
      color: isCurrentlyPlaying ? Colors.yellow.withOpacity(0.2) : Colors.transparent,
      child: ListTile(
        leading: Text(
          track.trackNumber,
          style: TextStyle(color: isCurrentlyPlaying ? Colors.yellow : Colors.grey.shade300),
        ),
        title: Text(
          track.trackName,
          style: TextStyle(color: isCurrentlyPlaying ? Colors.yellow : Colors.white),
        ),
        trailing: Text(
          formatDurationSeconds(track.trackDuration),
          style: TextStyle(color: isCurrentlyPlaying ? Colors.yellow.withOpacity(0.8) : Colors.grey.shade400),
        ),
        onTap: () {
          playShowFromTrack(parentShow, track);
          Navigator.pushNamed(context, '/shows_music_player_page');
        },
        dense: true,
      ),
    );
  }
  
  /// **FAB is now consistent with AlbumsPage**
  Widget? _buildFloatingActionButton() {
    final playerProvider = context.watch<TrackPlayerProvider>();

    if (playerProvider.isLoading) {
      return const FloatingActionButton(
        onPressed: null,
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: SizedBox(
          width: 50, height: 50,
          child: CircularProgressIndicator(strokeWidth: 3.0, valueColor: AlwaysStoppedAnimation<Color>(Colors.yellow)),
        ),
      );
    }

    if (playerProvider.currentlyPlayingSong != null) {
      return FloatingActionButton(
        onPressed: () {
          // The new, unified action: scroll first, then navigate.
          _scrollToCurrentShow();
          Navigator.pushNamed(context, '/shows_music_player_page');
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const Icon(Icons.play_circle_fill, color: Colors.yellow, shadows: [Shadow(color: Colors.redAccent, blurRadius: 4)], size: 50),
      );
    }

    return null;
  }
}