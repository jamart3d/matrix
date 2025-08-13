// // lib/pages/albums_grid_page.dart
//
// import 'dart:ui';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:matrix/components/my_drawer.dart';
// import 'package:matrix/helpers/album_helper.dart';
// import 'package:matrix/models/album.dart';
// import 'package:matrix/providers/album_settings_provider.dart';
// import 'package:matrix/providers/track_player_provider.dart';
// import 'package:matrix/services/album_data_service.dart';
// import 'package:matrix/pages/tv_album_detail_page.dart';
// import 'package:provider/provider.dart';
// import 'package:logger/logger.dart';
//
// class AlbumsGridPage extends StatefulWidget {
//   const AlbumsGridPage({super.key});
//
//   @override
//   State<AlbumsGridPage> createState() => _AlbumsGridPageState();
// }
//
// class _AlbumsGridPageState extends State<AlbumsGridPage> with AutomaticKeepAliveClientMixin {
//   final _logger = Logger(printer: PrettyPrinter(methodCount: 1));
//
//   // --- State ---
//   late final Future<void> _initializationFuture;
//   String _currentAlbumArt = 'assets/images/t_steal.webp';
//   String? _currentAlbumName;
//
//   // --- Focus Management ---
//   final FocusNode _gridFocusNode = FocusNode();
//   int _focusedIndex = -1;
//   bool _isAppBarFocused = true;
//   final ScrollController _scrollController = ScrollController();
//
//   // --- IMPROVEMENT: Define spacing as a constant for reuse ---
//   static const double _gridSpacing = 16.0;
//
//   // --- Helper Getter ---
//   bool get _displayAlbumReleaseNumber => context.read<AlbumSettingsProvider>().displayAlbumReleaseNumber;
//
//   @override
//   bool get wantKeepAlive => true;
//
//   @override
//   void initState() {
//     super.initState();
//     _gridFocusNode.addListener(_onGridFocusChange);
//     _initializationFuture = AlbumDataService().init();
//   }
//
//   @override
//   void dispose() {
//     _gridFocusNode.removeListener(_onGridFocusChange);
//     _gridFocusNode.dispose();
//     _scrollController.dispose();
//     super.dispose();
//   }
//
//   void _updateStateFromProvider(TrackPlayerProvider provider) {
//     final currentlyPlaying = provider.currentTrack;
//     if (currentlyPlaying != null && currentlyPlaying.albumName != _currentAlbumName) {
//       if (mounted) {
//         setState(() {
//           _currentAlbumArt = provider.currentAlbumArt;
//           _currentAlbumName = currentlyPlaying.albumName;
//         });
//         _focusOnCurrentAlbum();
//       }
//     }
//   }
//
//   void _onGridFocusChange() {
//     if (_gridFocusNode.hasFocus && _focusedIndex == -1) {
//       setState(() {
//         _focusedIndex = 0;
//         _isAppBarFocused = false;
//       });
//       _scrollToFocusedItem();
//     }
//   }
//
//   void _scrollToFocusedItem() {
//     if (_focusedIndex < 0 || !_scrollController.hasClients || !mounted) return;
//
//     final albums = AlbumDataService().albums;
//     if (albums.isEmpty) return;
//
//     const crossAxisCount = 4;
//     final itemWidth = (MediaQuery.of(context).size.width - (crossAxisCount + 1) * _gridSpacing) / crossAxisCount;
//     final itemHeight = itemWidth + _gridSpacing;
//     final targetRow = (_focusedIndex / crossAxisCount).floor();
//     final scrollOffset = targetRow * itemHeight;
//
//     _scrollController.animateTo(scrollOffset, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
//   }
//
//   void _focusOnCurrentAlbum() {
//     if (_currentAlbumName == null) return;
//     final albums = AlbumDataService().albums;
//     final index = albums.indexWhere((album) => album.name == _currentAlbumName);
//     if (index != -1) {
//       setState(() {
//         _focusedIndex = index;
//         _isAppBarFocused = false;
//       });
//       _scrollToFocusedItem();
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     super.build(context);
//     final provider = context.watch<TrackPlayerProvider>();
//     _updateStateFromProvider(provider);
//
//     // ignore: deprecated_member_use
//     return WillPopScope(
//       onWillPop: _handleBackButton,
//       child: Scaffold(
//         appBar: _buildAppBar(),
//         drawer: const MyDrawer(),
//         body: Container(
//           decoration: BoxDecoration(image: DecorationImage(image: AssetImage(_currentAlbumArt), fit: BoxFit.cover)),
//           child: BackdropFilter(
//             filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
//             child: Container(
//               color: Colors.black.withOpacity(0.5),
//               child: FutureBuilder<void>(
//                 future: _initializationFuture,
//                 builder: (context, snapshot) {
//                   if (snapshot.connectionState == ConnectionState.waiting) {
//                     return const Center(child: CircularProgressIndicator());
//                   }
//                   if (snapshot.hasError) {
//                     return Center(child: Text("Error: ${snapshot.error}"));
//                   }
//
//                   final albums = AlbumDataService().albums;
//                   if (albums.isEmpty) {
//                     return const Center(child: Text("No albums available."));
//                   }
//
//                   return KeyboardListener(
//                     focusNode: _gridFocusNode,
//                     onKeyEvent: (event) => _handleKeyEvent(event, albums),
//                     child: _buildGridView(albums),
//                   );
//                 },
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   PreferredSizeWidget? _buildAppBar() {
//     return _isAppBarFocused ? AppBar(
//       foregroundColor: Colors.white,
//       backgroundColor: Colors.black.withOpacity(0.7),
//       centerTitle: true,
//       title: Row(mainAxisSize: MainAxisSize.min, children: [
//         Text(_currentAlbumName ?? 'Select an Album', style: const TextStyle(color: Colors.white)),
//         IconButton(
//           icon: Icon(Icons.album, color: _currentAlbumName != null ? Colors.yellow : Colors.transparent),
//           onPressed: _focusOnCurrentAlbum,
//           tooltip: 'Focus on Current Album',
//         ),
//       ]),
//       actions: [
//         const Text("Random Trix -->"),
//         IconButton(
//           icon: const Icon(Icons.question_mark, color: Colors.white),
//           onPressed: () => playRandomAlbum(AlbumDataService().albums),
//           tooltip: 'Play Random Album',
//         ),
//       ],
//     ) : null;
//   }
//
//   Future<bool> _handleBackButton() async {
//     if (!_isAppBarFocused) {
//       setState(() {
//         _isAppBarFocused = true;
//         _focusedIndex = -1;
//       });
//       return false;
//     }
//     return true;
//   }
//
//   void _handleKeyEvent(KeyEvent event, List<Album> albums) {
//     if (event is! KeyDownEvent) return;
//     if (event.logicalKey == LogicalKeyboardKey.arrowDown) _moveFocus(4, albums.length);
//     else if (event.logicalKey == LogicalKeyboardKey.arrowUp) _moveFocus(-4, albums.length);
//     else if (event.logicalKey == LogicalKeyboardKey.arrowRight) _moveFocus(1, albums.length);
//     else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) _moveFocus(-1, albums.length);
//     else if (event.logicalKey == LogicalKeyboardKey.select || event.logicalKey == LogicalKeyboardKey.enter) {
//       _handleSelectPress(albums);
//     }
//   }
//
//   void _moveFocus(int delta, int totalItems) {
//     setState(() {
//       if (_isAppBarFocused) {
//         _isAppBarFocused = false;
//         _focusedIndex = 0;
//       } else {
//         final newIndex = _focusedIndex + delta;
//         if (newIndex < 0 && _focusedIndex < 4) {
//           _isAppBarFocused = true;
//           _focusedIndex = -1;
//         } else {
//           _focusedIndex = newIndex.clamp(0, totalItems - 1);
//         }
//       }
//     });
//     _scrollToFocusedItem();
//   }
//
//   void _handleSelectPress(List<Album> albums) {
//     if (_focusedIndex < 0) return;
//     final album = albums[_focusedIndex];
//     Navigator.push(context, MaterialPageRoute(
//       builder: (_) => TvAlbumDetailPage(tracks: album.tracks, albumArt: album.albumArt, albumName: album.name),
//     ));
//   }
//
//   Widget _buildGridView(List<Album> albums) {
//     return GridView.builder(
//       controller: _scrollController,
//       padding: const EdgeInsets.all(_gridSpacing),
//       gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//         crossAxisCount: 4,
//         mainAxisSpacing: _gridSpacing,
//         crossAxisSpacing: _gridSpacing,
//         childAspectRatio: 1.0,
//       ),
//       itemCount: albums.length,
//       itemBuilder: (context, index) {
//         final album = albums[index];
//         final isFocused = index == _focusedIndex;
//
//         return GestureDetector(
//           onTap: () {
//             setState(() { _focusedIndex = index; _isAppBarFocused = false; });
//             _handleSelectPress(albums);
//           },
//           child: AnimatedScale(
//             scale: isFocused ? 1.05 : 1.0,
//             duration: const Duration(milliseconds: 200),
//             child: Card(
//               elevation: isFocused ? 12 : 4,
//               clipBehavior: Clip.antiAlias,
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//               child: Stack(fit: StackFit.expand, children: [
//                 Image.asset(
//                   album.albumArt,
//                   fit: BoxFit.cover,
//                   // --- IMPROVEMENT: Added error builder for robustness ---
//                   errorBuilder: (context, error, stackTrace) {
//                     _logger.w("Failed to load grid image: ${album.albumArt}", error: error);
//                     return const Icon(Icons.broken_image, color: Colors.grey);
//                   },
//                 ),
//                 if (isFocused || _currentAlbumName == album.name)
//                   Container(
//                     decoration: BoxDecoration(
//                       border: Border.all(color: isFocused ? Colors.yellow : Colors.red, width: isFocused ? 4 : 2),
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                   ),
//                 Align(
//                   alignment: Alignment.bottomLeft,
//                   child: Container(
//                     width: double.infinity,
//                     padding: const EdgeInsets.all(8.0),
//                     decoration: const BoxDecoration(
//                       gradient: LinearGradient(
//                         begin: Alignment.bottomCenter, end: Alignment.topCenter,
//                         colors: [Colors.black, Colors.transparent],
//                       ),
//                     ),
//                     child: Text(
//                       _displayAlbumReleaseNumber ? '${album.releaseNumber}. ${formatAlbumName(album.name)}' : formatAlbumName(album.name),
//                       style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, shadows: [Shadow(color: Colors.black, blurRadius: 2)]),
//                       maxLines: 2,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ),
//                 ),
//               ]),
//             ),
//           ),
//         );
//       },
//     );
//   }
// }