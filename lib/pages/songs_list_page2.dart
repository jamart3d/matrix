import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import '../isar_collections/song.dart';
import 'package:myapp/services/isar_service.dart';

class SongsListPage extends StatefulWidget {
  @override
  _SongsListPageState createState() => _SongsListPageState();
}

class _SongsListPageState extends State<SongsListPage> {
  // late Isar _isar;
  //   final IsarService _isarService = IsarService();

  List<Song> _songs = [];
  bool _isLoading = false;
  List<bool> _selectedStrings = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initIsar();
    _selectedStrings = List.generate(_songs.length, (index) => false);
  }

  Future<void> _initIsar() async {
    setState(() {
      _isLoading = true;
    });
    try {
       _isar = await _isarService.openDB();
      await _loadSongs();
    } catch (e) {
      // Handle error, e.g., display a snackbar
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error loading songs: $e'),
      ));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadSongs() async {
    final songs = await _isar.songs.where().findAll();
    setState(() {
      _songs = songs;
      _selectedStrings = List.generate(_songs.length, (index) => false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Songs'),
        //backgroundColor: Colors.brown,
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            onSelected: (String item) {
              setState(() {
                if (item == 'Select All') {
                  _selectedStrings =
                      List.generate(_songs.length, (index) => true);
                } else if (item == 'Deselect All') {
                  _selectedStrings =
                      List.generate(_songs.length, (index) => false);
                }
              });
            },
            itemBuilder: (BuildContext context) {
              bool areAllSelected = _selectedStrings
                  .every((element) => element); // Check if all are selected

              return [
                PopupMenuItem<String>(
                  value: areAllSelected
                      ? 'Deselect All'
                      : 'Select All', // Toggle value
                  child: Row(
                    children: [
                      Checkbox(
                        value: areAllSelected,
                        onChanged: (bool? newValue) {
                          setState(() {
                            _selectedStrings = List.generate(
                                _songs.length, (index) => newValue!);
                          });
                        },
                      ),
                      Text(areAllSelected
                          ? 'Deselect All'
                          : 'Select All'), // Toggle text
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'Preference',
                  child: Row(
                    children: [
                      StatefulBuilder(
                        builder: (BuildContext context, StateSetter setState) {
                          return Checkbox(
                            //value: _buildXmls,
                            value: false,
                            onChanged: (bool? newValue) async {
                              if (newValue != null) {
                                //SharedPreferences prefs = await SharedPreferences.getInstance();
                                //await prefs.setBool('buildXmls', newValue);
                                setState(() {
                                  // Use the setState provided by StatefulBuilder
                                  //_buildXmls = newValue;
                                });
                              }
                            },
                          );
                        },
                      ),
                      const Text('null'),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'Total',
                  child: Text(
                      'Total Selected: ${_selectedStrings.where((element) => element).length}'),
                ),
                PopupMenuItem<String>(
                  value: 'Size',
                  child: Text('Total Urls: ${_songs.length}'),
                ),
              ];
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _songs.isEmpty
              ? Center(child: Text('No songs found.'))
              : CupertinoScrollbar(
                controller: _scrollController,
                  //interactive: true,
                  thickness: 20,
                  radius: Radius.circular(20),
                  radiusWhileDragging: Radius.circular(20),
                  thicknessWhileDragging: 20,
                  thumbVisibility: true,
                  child: ListView.builder(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    itemCount: _songs.length,
                    itemBuilder: (context, index) {
                      final song = _songs[index];
                      return ListTile(
                        leading: Checkbox(
                          value: _selectedStrings[index],
                          onChanged: (bool? newValue) {
                            setState(() {
                              _selectedStrings[index] = newValue!;
                            });
                          },
                        ),
                        title: Text(song.title),
                        trailing: Text(song.artist),
                        isThreeLine: true,
                        subtitle: Text("album: ${song.album.load()}"),
                        visualDensity: VisualDensity.compact,
                      );
                    },
                  ),
                ),
    );
  }
}
