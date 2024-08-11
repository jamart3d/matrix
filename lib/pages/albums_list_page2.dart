//from gemini pro
import 'package:flutter/material.dart'; // Import Flutter's core UI library.
import 'package:isar/isar.dart'; // Import the Isar library for local database interactions.
import '../isar_collections/song.dart'; // Import the Song entity representing song data.
import 'package:myapp/services/isar_service.dart'; // Import a service class for managing the Isar database connection.
import '../isar_collections/album.dart'; // Import the Album entity representing album data.

class AlbumsListPage extends StatefulWidget {
  // This class defines a stateful widget representing the Albums List page.

  @override
  _AlbumsListPageState createState() => _AlbumsListPageState(); // Creates the state object associated with this widget.
}

class _AlbumsListPageState extends State<AlbumsListPage> {
  // This class manages the state of the AlbumsListPage widget.

  // late Isar _isar; // Declare a variable to hold the Isar instance for database operations.
  // final IsarService _isarService = IsarService(); // Create an instance of the IsarService to handle database setup.

  List<Album> _albums = []; // A list to store the retrieved albums from the database.
  bool _isLoading = false; // A flag to indicate whether data is being loaded.
  bool _isGridview = true; // A flag to track whether the current view is a grid or a list.

  @override
  void initState() {
    // This method is called when the widget is first inserted into the widget tree.

    super.initState(); // Call the initState method of the parent class.
    _initIsar(); // Initialize the Isar database connection.
  }

  Future<void> _initIsar() async {
    // This asynchronous method initializes the Isar database and loads albums.

    setState(() {
      _isLoading = true; // Set the loading flag to true while data is being fetched.
    });

    try {
      _isar = await _isarService.openDB(); // Open the Isar database using the IsarService.
      await _loadAlbums(); // Load the albums from the database.
    } catch (e) {
      // Handle any errors that might occur during database setup or album loading.
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error loading albums: $e'), // Display an error message in a snackbar.
      ));
    } finally {
      setState(() {
        _isLoading = false; // Set the loading flag to false after data loading is complete (or if there's an error).
      });
    }
  }

  Future<void> _loadAlbums() async {
    // This asynchronous method loads albums from the database and retrieves associated songs.

    final albums = await _isar.albums.where().findAll(); // Fetch all albums from the Isar database.
    setState(() {
      _albums = albums; // Update the state with the retrieved albums.
    });

    if (_albums.isNotEmpty) {
      // If albums were found, print some debugging information.

      final firstAlbum = _albums.last; // Get the last album in the list (assuming it's the most recently added).

      print('last Album: ${firstAlbum.title} by ${firstAlbum.artist}'); // Print the album title and artist.

      final songs1 = await _isar.songs.filter().albumIdEqualTo(firstAlbum.id).findAll(); // Fetch songs associated with the album.

      if (songs1.isNotEmpty) {
        print('First song: ${songs1.first.title}'); // Print the title of the first song.
      }

      final songs = await _isar.songs.filter().albumIdEqualTo(firstAlbum.id).findAll(); // Fetch songs again (redundant, could be optimized).

      final firstSong = songs.isNotEmpty ? songs.first : null; // Get the first song or null if there are no songs.
      print("1st song $firstSong");

      print('Songs:');
      for (final song in songs) {
        print('- ${song.title}'); // Print the titles of all songs associated with the album.
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // This method builds the UI of the AlbumsListPage widget.

    return Scaffold(
      // Create the main structure of the screen.

      appBar: AppBar(
        // Create the app bar at the top.

        title: Text('Albums'), // Set the title of the app bar.

        actions: [
          // Add actions (buttons or icons) to the app bar.

          IconButton(
            // Create an icon button to toggle the view mode.

            icon: Icon(_isGridview ? Icons.list : Icons.grid_view), // Display the appropriate icon based on the current view mode.
            onPressed: () {
              // Define the action to perform when the button is pressed.

              setState(() {
                _isGridview = !_isGridview; // Toggle the view mode flag.
              });
            },
          ),
        ],
      ),

      body: _isLoading
          ? Center(child: CircularProgressIndicator()) // Display a loading indicator if data is being loaded.
          : _albums.isEmpty
              ? Center(child: Text('No albums found.')) // Display a message if no albums are found.
              : _isGridview
                  ? GridView.builder(
                      // If in grid view mode, build a GridView to display albums.

                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, // Number of columns in the grid.
                        childAspectRatio: 1.0, // Aspect ratio of each grid item.
                      ),
                      itemCount: _albums.length, // Number of albums to display.
                      itemBuilder: (context, index) {
                        // Build each grid item representing an album.

                        final album = _albums[index]; // Get the album data for the current index.

                        return ExpansionTile(
                          // Create an expandable tile for the album.

                          title: Text(album.title), // Set the album title as the main title.
                          subtitle: Text(album.artist), // Set the album artist as the subtitle.

                          children: [
                            // Content to be displayed when the tile is expanded (list of songs).

                            FutureBuilder<List<Song>>(
                              // Asynchronously fetch songs associated with the album.

                              future: _isar.songs.filter().albumIdEqualTo(album.id).findAll(), // Fetch songs from the database.

                              builder: (context, snapshot) {
                                // Build the UI based on the song fetching status.

                                if (snapshot.hasData) {
                                  // If song data is available, display a list of songs.

                                  return ListView.builder(
                                    // Build a ListView to display the songs.

                                    shrinkWrap: true, // Shrink the ListView to fit its content.
                                    physics: NeverScrollableScrollPhysics(), // Disable scrolling within the nested ListView.
                                    itemCount: snapshot.data!.length, // Number of songs to display.

                                    itemBuilder: (context, index) {
                                      // Build each list item representing a song.

                                      final song = snapshot.data![index]; // Get the song data for the current index.

                                      return InkWell(
                                        // Make the song item tappable.

                                        onTap: () {
                                          // When tapped, print all songs of the album.

                                          print('Songs of ${album.title}:');
                                          snapshot.data!.forEach((s) => print('- ${s.title}'));
                                        },

                                        child: ListTile(
                                          // Display the song title in a ListTile.

                                          title: Text(song.title),
                                        ),
                                      );
                                    },
                                  );
                                } else if (snapshot.hasError) {
                                  // If there's an error fetching songs, display an error message.

                                  return Text('Error: ${snapshot.error}');
                                } else {
                                  // While songs are being fetched, display a loading indicator.

                                  return CircularProgressIndicator();
                                }
                              },
                            ),
                          ],
                        );
                      },
                    )
                  : ListView.builder(
                      // If not in grid view mode (i.e., in list view mode), build a ListView to display albums.

                      itemCount: _albums.length, // Number of albums to display.

                      itemBuilder: (context, index) {
                        // Build each list item representing an album.

                        final album = _albums[index]; // Get the album data for the current index.
                        return ExpansionTile(
                          title: Text(album.title),
                          subtitle: Text(album.artist),
                          leading: Image.asset("assets/images/steal8.png"),
                          children: [
                            FutureBuilder<List<Song>>(
                              future: _isar.songs
                                  .filter()
                                  .albumIdEqualTo(album.id)
                                  .findAll(),
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  return ListView.builder(
                                    shrinkWrap: true, 
                                    physics: NeverScrollableScrollPhysics(),
                                    itemCount: snapshot.data!.length,
                                    itemBuilder: (context, index) {
                                      final song = snapshot.data![index];
                                      return InkWell(
                                        onTap: () {
                                          // Print all songs of the album
                                          print('Songs of ${album.title}:');
                                          snapshot.data!.forEach(
                                              (s) => print('- ${s.title}'));
                                        },
                                        child: ListTile(
                                          title: Text(song.title),
                                        ),
                                      );
                                    },
                                  );
                                } else if (snapshot.hasError) {
                                  return Text('Error: ${snapshot.error}');
                                } else {
                                  return CircularProgressIndicator();
                                }
                              },
                            ),
                          ],
                        );
                      },
                    ),
    ); 
  }
}
