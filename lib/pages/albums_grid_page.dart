import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:huntrix/components/my_drawer.dart';
import 'package:huntrix/helpers/album_helper.dart'; // <-- Import the refactored helper
import 'package:huntrix/models/track.dart';
import 'package:huntrix/pages/tv_album_detail_page.dart';
import 'package:huntrix/providers/track_player_provider.dart';
import 'package:provider/provider.dart';
import 'package:huntrix/utils/load_json_data.dart';
import 'package:huntrix/utils/album_utils.dart';
import 'package:huntrix/providers/album_settings_provider.dart';
import 'package:logger/logger.dart';

class AlbumsGridPage extends StatefulWidget {
  const AlbumsGridPage({super.key});

  @override
  State<AlbumsGridPage> createState() => _AlbumsGridPageState();
}

class _AlbumsGridPageState extends State<AlbumsGridPage> with AutomaticKeepAliveClientMixin {
  final _logger = Logger(printer: PrettyPrinter(methodCount: 1));

  // State variables
  List<Map<String, dynamic>>? _cachedAlbumData;
  String _currentAlbumArt = 'assets/images/t_steal.webp';
  String? _currentAlbumName;
  bool _isDataLoading = true;
  
  // Focus Management
  final FocusNode _gridFocusNode = FocusNode();
  int _focusedIndex = -1; // -1 means nothing in the grid is focused
  bool _isAppBarFocused = true; // Start with AppBar focused
  final ScrollController _scrollController = ScrollController();

  // Settings Provider Getter
  bool get _displayAlbumReleaseNumber => context.read<AlbumSettingsProvider>().displayAlbumReleaseNumber;

  @override
  void initState() {
    super.initState();
    _gridFocusNode.addListener(_onGridFocusChange);
    _initializePage();
  }

  @override
  void dispose() {
    _gridFocusNode.removeListener(_onGridFocusChange);
    _gridFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  // Keep state alive when switching tabs/pages
  @override
  bool get wantKeepAlive => true;
  
  /// Refactored: Central initialization method called only once.
  Future<void> _initializePage() async {
    await _loadAlbumData();
  }

  /// Refactored: Loads data only once.
  Future<void> _loadAlbumData() async {
    try {
      _logger.i("Loading album data for grid view...");
      await loadData(context, (albumData) {
        if (mounted) {
          setState(() {
            _cachedAlbumData = albumData;
            _isDataLoading = false;
          });
          if (albumData != null) {
            preloadAlbumImages(albumData, context);
          }
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isDataLoading = false);
        _showErrorSnackBar("Failed to load album data.");
      }
    }
  }

  /// Refactored: This method now *only* handles provider updates.
  void _updateStateFromProvider(TrackPlayerProvider provider) {
    final currentlyPlaying = provider.currentTrack ;
    if (currentlyPlaying == null) return;
    
    final newAlbumArt = currentlyPlaying.albumArt ?? 'assets/images/t_steal.webp';
    final newAlbumName = currentlyPlaying.albumName;
    
    if (newAlbumArt != _currentAlbumArt || newAlbumName != _currentAlbumName) {
      if (mounted) {
        setState(() {
          _currentAlbumArt = newAlbumArt;
          _currentAlbumName = newAlbumName;
        });
        _focusOnCurrentAlbum();
      }
    }
  }
  
  void _onGridFocusChange() {
    // When the grid itself gains focus, ensure the first item is focused.
    if (_gridFocusNode.hasFocus && _focusedIndex == -1) {
      setState(() {
        _focusedIndex = 0;
        _isAppBarFocused = false;
      });
      _scrollToFocusedItem();
    }
  }

  void _scrollToFocusedItem() {
    if (_focusedIndex < 0 || _cachedAlbumData == null || !_scrollController.hasClients) return;
    
    const crossAxisCount = 4;
    final itemHeight = (MediaQuery.of(context).size.width - (crossAxisCount + 1) * 10) / crossAxisCount;
    final targetRow = (_focusedIndex / crossAxisCount).floor();
    final scrollOffset = targetRow * (itemHeight + 10.0);

    _scrollController.animateTo(
      scrollOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _focusOnCurrentAlbum() {
    if (_cachedAlbumData == null || _currentAlbumName == null) return;
    
    final index = _cachedAlbumData!.indexWhere((album) => album['album'] == _currentAlbumName);
    if (index != -1) {
      setState(() {
        _focusedIndex = index;
        _isAppBarFocused = false;
      });
      _scrollToFocusedItem();
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    super.build(context);
    // Watch provider for real-time updates to background art and focus
    final provider = context.watch<TrackPlayerProvider>();
    _updateStateFromProvider(provider);

    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: _handleBackButton,
      child: Scaffold(
        appBar: _buildAppBar(),
        drawer: const MyDrawer(),
        body: Container(
          decoration: BoxDecoration(image: DecorationImage(image: AssetImage(_currentAlbumArt), fit: BoxFit.cover)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color: Colors.black.withOpacity(0.5),
              child: KeyboardListener(
                focusNode: _gridFocusNode,
                onKeyEvent: _handleKeyEvent,
                child: _buildContent(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget? _buildAppBar() {
    // Only show AppBar if it's focused or if nothing is focused yet.
    return _isAppBarFocused ? AppBar(
      foregroundColor: Colors.white,
      backgroundColor: Colors.black.withOpacity(0.7),
      centerTitle: true,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_currentAlbumName ?? 'Select an Album', style: const TextStyle(color: Colors.white)),
          IconButton(
            icon: Icon(Icons.album, color: _currentAlbumName != null ? Colors.yellow : Colors.transparent),
            onPressed: _focusOnCurrentAlbum,
            tooltip: 'Focus on Current Album',
          ),
        ],
      ),
      actions: [
        const Text("Random Trix -->"),
        IconButton(
          icon: const Icon(Icons.question_mark, color: Colors.white),
          onPressed: () { // Refactored: Use new helper
            if (_cachedAlbumData != null) {
              playRandomAlbum(_cachedAlbumData!);
            }
          },
          tooltip: 'Play Random Album',
        ),
      ],
    ) : null;
  }

  Widget _buildContent() {
    if (_isDataLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_cachedAlbumData == null || _cachedAlbumData!.isEmpty) {
      return const Center(child: Text("No albums available."));
    }
    return _buildGridView();
  }

  Future<bool> _handleBackButton() async {
    // If something in the grid is focused, move focus to the AppBar. Don't pop.
    if (!_isAppBarFocused) {
      setState(() {
        _isAppBarFocused = true;
        _focusedIndex = -1; // Un-focus the grid
      });
      return false; // Prevent app from closing
    }
    // If AppBar is already focused, allow the pop (close app/go back).
    return true;
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      _moveFocus(4);
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      _moveFocus(-4);
    } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      _moveFocus(1);
    } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _moveFocus(-1);
    } else if (event.logicalKey == LogicalKeyboardKey.select ||
        event.logicalKey == LogicalKeyboardKey.enter) {
      _handleSelectPress();
    }
  }

  void _moveFocus(int delta) {
    if (_cachedAlbumData == null) return;
    
    setState(() {
      if (_isAppBarFocused) {
        // If coming from AppBar, move focus to the first grid item.
        _isAppBarFocused = false;
        _focusedIndex = 0;
      } else {
        final newIndex = _focusedIndex + delta;
        // If moving up from the top row, focus the AppBar.
        if (newIndex < 0 && _focusedIndex < 4) {
          _isAppBarFocused = true;
          _focusedIndex = -1;
        } else {
          // Clamp the index within the valid range.
          _focusedIndex = newIndex.clamp(0, _cachedAlbumData!.length - 1);
        }
      }
    });
    _scrollToFocusedItem();
  }

  void _handleSelectPress() {
    if (_focusedIndex < 0 || _cachedAlbumData == null) return;
    
    final album = _cachedAlbumData![_focusedIndex];
    final tracks = album['songs'] as List<Track>;
    final albumArt = album['albumArt'] as String;
    final albumName = album['album'] as String;

    Navigator.push(context, MaterialPageRoute(
      builder: (_) => TvAlbumDetailPage(
        tracks: tracks,
        albumArt: albumArt,
        albumName: albumName,
      ),
    ));
  }

  Widget _buildGridView() {
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 16.0,
        crossAxisSpacing: 16.0,
        childAspectRatio: 1.0,
      ),
      itemCount: _cachedAlbumData!.length,
      itemBuilder: (context, index) {
        final album = _cachedAlbumData![index];
        final albumName = album['album'] as String;
        final albumArt = album['albumArt'] as String;
        final isFocused = index == _focusedIndex;
        
        return GestureDetector(
          onTap: () { // For mouse/touch interaction
            setState(() {
              _focusedIndex = index;
              _isAppBarFocused = false;
            });
            _handleSelectPress();
          },
          child: AnimatedScale(
            scale: isFocused ? 1.05 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: Card(
              elevation: isFocused ? 12 : 4,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(albumArt, fit: BoxFit.cover),
                  // Focus and selection highlight
                  if (isFocused || _currentAlbumName == albumName)
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isFocused ? Colors.yellow : Colors.red,
                          width: isFocused ? 4 : 2,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  // Title overlay
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8.0),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Colors.black, Colors.transparent],
                        ),
                      ),
                      child: Text(
                        _displayAlbumReleaseNumber ? '${index + 1}. ${formatAlbumName(albumName)}' : formatAlbumName(albumName),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: const [Shadow(color: Colors.black, blurRadius: 2)],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}