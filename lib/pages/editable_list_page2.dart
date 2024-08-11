import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
//import 'package:myapp/models/downloader.dart';
import 'package:myapp/services/isar_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myapp/components/my_drawer.dart';
import 'package:myapp/isar_collections/song.dart';
import 'package:myapp/isar_collections/album.dart';
import 'package:xml/xml.dart' as xml;

class EditableListPage extends StatefulWidget {
  const EditableListPage({super.key});

  @override
  State<EditableListPage> createState() => _EditableListPageState();
}

class _EditableListPageState extends State<EditableListPage> {
  final TextEditingController _textController = TextEditingController();
  Future<List<String>>? _futureUrls;
  List<String> _longStrings = [];
  List<bool> _selectedStrings = [];
  List<Color> _tileColors = [];
  bool _buildXmls = false;
  String? _htmlSource;
  String? _alternateLocation;
  List<String> _mp3Urls = [];
  // final IsarService _isarService = IsarService();

  @override
  void initState() {
    super.initState();
    _loadSettings();
    // _futureUrls = _loadUrls();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_futureUrls == null) {
      _futureUrls = _loadUrls();
    }
  }

  Future<void> _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? savedValue = prefs.getBool('buildXmls');

    if (savedValue != null) {
      setState(() {
        _buildXmls = savedValue;
      });
    }
  }

  Future<List<String>> _loadUrls() async {
    List<String> urls = await fetchLocalJson('assets/urls.json');
    setState(() {
      _longStrings = urls;
      _selectedStrings = List.generate(_longStrings.length, (index) => false);
      _tileColors = List.generate(_longStrings.length, (index) => Colors.white);
    });
    return urls;
  }

  Future<List<String>> fetchLocalJson(String path) async {
    final String response = await rootBundle.loadString(path);
    List<dynamic> jsonResponse = json.decode(response);
    List<String> urls =
        jsonResponse.map((item) => item['url'] as String).toList();
    return urls;
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Url List'),
        //backgroundColor: Colors.green,
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            onSelected: (String item) {
              setState(() {
                if (item == 'Select All') {
                  _selectedStrings =
                      List.generate(_longStrings.length, (index) => true);
                } else if (item == 'Deselect All') {
                  _selectedStrings =
                      List.generate(_longStrings.length, (index) => false);
                }
              });
            },
            itemBuilder: (BuildContext context) {
              bool areAllSelected =
                  _selectedStrings.every((element) => element);

              return [
                PopupMenuItem<String>(
                  value: areAllSelected ? 'Deselect All' : 'Select All',
                  child: Row(
                    children: [
                      Checkbox(
                        value: areAllSelected,
                        onChanged: (bool? newValue) {
                          setState(() {
                            _selectedStrings = List.generate(
                                _longStrings.length, (index) => newValue!);
                          });
                        },
                      ),
                      Text(areAllSelected ? 'Deselect All' : 'Select All'),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'XML Preference',
                  child: Row(
                    children: [
                      StatefulBuilder(
                        builder: (BuildContext context, StateSetter setState) {
                          return Checkbox(
                            value: _buildXmls,
                            onChanged: (bool? newValue) async {
                              if (newValue != null) {
                                SharedPreferences prefs =
                                    await SharedPreferences.getInstance();
                                await prefs.setBool('buildXmls', newValue);
                                setState(() {
                                  _buildXmls = newValue;
                                });
                              }
                            },
                          );
                        },
                      ),
                      const Text('build XMLs'),
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
                  child: Text('Total Urls: ${_longStrings.length}'),
                ),
              ];
            },
          ),
        ],
      ),
      drawer: MyDrawer(),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: _selectedStrings.any((element) => element)
                ? () async {
                    await _fetchHtmlSource(_longStrings
                        .where((element) =>
                            _selectedStrings[_longStrings.indexOf(element)] &&
                            _tileColors[_longStrings.indexOf(element)] ==
                                Colors.white)
                        .toList());
                  }
                : null,
            child: const Text('Parse Selected Items'),
          ),
          Expanded(
            child: FutureBuilder<List<String>>(
              future: _futureUrls,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No URLs found'));
                } else {
                  return ListView.builder(
                    itemCount: _longStrings.length,
                    shrinkWrap: true,
                    itemBuilder: (context, index) {
                      return AnimatedContainer(
                        duration: Duration(seconds: 1),
                        color: _tileColors[index],
                        child: CheckboxListTile(
                          value: _selectedStrings[index],
                          onChanged: (bool? value) {
                            setState(() {
                              _selectedStrings[index] = value!;
                            });
                          },
                          title: GestureDetector(
                            onLongPress: () {
                              setState(() {
                                _textController.text = _longStrings[index];
                              });
                            },
                            child: Text(
                              '${index + 1}. ${_longStrings[index]}',
                              softWrap: false,
                            ),
                          ),
                          dense: true,
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _textController,
              keyboardType: TextInputType.none,
              decoration: const InputDecoration(
                hintText: 'Paste xml here',
              ),
              onSubmitted: (String text) {
                if (text.isNotEmpty) {
                  setState(() {
                    _longStrings.add(text);
                    _selectedStrings.add(false);
                    _tileColors.add(Colors.white);
                  });
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchHtmlSource(List<String> urls) async {
    for (final url in urls) {
      int index = _longStrings.indexOf(url);
      if (index != -1) {
        _updateTileColor(index, Colors.yellow);
      }

      try {
        final response = await http.get(Uri.parse(url));

        if (response.statusCode == 200) {
          _htmlSource = response.body;

          String? xmlUrl = _findAlternateLocationToXml();
          if (xmlUrl != null && _buildXmls) {
            //print(xmlUrl);
            saveSongsFromXmlToIsar(xmlUrl);
            _updateTileColor(index, Colors.green);
          } else {
            _parseMp3Urls();
            _updateTileColor(index, Colors.orange);
          }
        } else {
          _updateTileColor(index, Colors.red);
          print("Failed to fetch data from: $url");
        }
      } catch (e) {
        _updateTileColor(index, Colors.red);
        print("Error fetching data from: $url");
      }
    }
  }

  void _updateTileColor(int index, Color color) {
    setState(() {
      _tileColors[index] = color;
    });
  }

  String? _findAlternateLocationToXml() {
    if (_htmlSource != null && _htmlSource!.contains('alternate_locations')) {
      final serverMatch =
          RegExp(r'"server"\s*:\s*"(.*?)"').firstMatch(_htmlSource!);
      final serverValue = serverMatch?.group(1) ?? '';

      final dirMatch = RegExp(r'"dir"\s*:\s*"(.*?)"').firstMatch(_htmlSource!);
      final dirValue = dirMatch?.group(1) ?? '';
      final filename = dirValue.split('/').last;

      const fileExtension = "_files.xml";
      _alternateLocation =
          'https://$serverValue$dirValue/$filename$fileExtension';

      print(_alternateLocation);
      return _alternateLocation;
    }

    return null;
  }

  void _parseMp3Urls() {
    List<String> mp3Urls = _htmlSource!
        .split('\n')
        .where((line) =>
            line.contains('href') &&
            line.contains('.mp3') &&
            line.contains('itemprop'))
        .map((line) => line.split('href="')[1].split('"')[0])
        .toList();

    _mp3Urls = mp3Urls;
    // print(mp3Urls.last);
    // print(mp3Urls.length);
    // for (var url in mp3Urls) {
    //   print(url);
    // }
    //feed the download page with the mp3 urls
    Provider.of<Mp3UrlsProvider>(context, listen: false).mp3Urls = _mp3Urls;
   
    _saveUrlSongsToIsar(mp3Urls);
  }

  void _saveUrlSongsToIsar(List<String> mp3Urls) async {
    int track = 0;
    for (var url in mp3Urls) {
      final songName = url.split('/').last.split('.mp3')[0];
      //print(songName);
      final regExp = RegExp(r'/(gd\d{4}-\d{2}-\d{2})\.');
      final match = regExp.firstMatch(url);
      final albumName = match?.group(1) ?? 'Unknown Album';

      final song = Song(songName)
        ..title = songName
        ..artist = "Grateful Dead"
        ..track = track++
        //..album = albumName
        ..audioFileUrl = url;

      final existingSong =
          await _isarService.getSongByAudioFileUrl(song.audioFileUrl);
      if (existingSong == null) {
        await _isarService.saveSong(song);

        // print(song.title);
        // print(song.artist);
        print(song.audioFileUrl);
        // //print(song.album);
        // //print(albumName);
        print("song: $songName $track album: $albumName");
        print("fuck1");
        //await _isarService.saveSongWithAlbum(song, albumName);
      } else {
        print("been there already");
      }

      // Check if album exists, if not create it
      final albums = await _isarService.getAllAlbums();
      if (!albums.any((album) => album.title == albumName)) {
        final album = Album(albumName)
          ..title = albumName
          ..artist = "Grateful Dead";
        print("album name: $albumName");
        print("fuck2");
        //await _isarService.saveAlbum(album);
        await _isarService.saveSongWithAlbum(song, album);
      }
    }
  }

  void saveSongsFromXmlToIsar(String xmlUrl) async {
    // debugPrint("from getSongsFromXml");
    // debugPrint(xmlUrl);
    // debugPrint("fuck0");

    String basePath = xmlUrl.substring(0, xmlUrl.lastIndexOf('/'));
    // print(basePath);
    final response = await http.get(Uri.parse(xmlUrl));
    if (response.statusCode == 200) {
      // print("fuck1");

      final document = xml.XmlDocument.parse(response.body);
      // Find all 'file' elements with an attribute containing '.mp3'
      final fileElements = document.findAllElements('file').where((element) {
        return element.attributes
            .any((attribute) => attribute.value.contains('.mp3'));
      });
      // Convert each qualifying element to a Song object
      for (var element in fileElements) {
        // Extract relevant information from the element
        final audioFilePath = '$basePath/${element.getAttribute('name')}';
        final songName = element.childElements
            .firstWhere((e) => e.name.local == 'title',
                orElse: () => xml.XmlElement(xml.XmlName('title'), [], []))
            .text;
        final artistName = element.childElements
            .firstWhere((e) => e.name.local == 'creator',
                orElse: () => xml.XmlElement(xml.XmlName('creator'), [], []))
            .text;
        final albumName = element.childElements
            .firstWhere((e) => e.name.local == 'album',
                orElse: () => xml.XmlElement(xml.XmlName('album'), [], []))
            .text;
        // final trackNumber = element.childElements
        //     .firstWhere((e) => e.name.local == 'track',
        //         orElse: () => xml.XmlElement(xml.XmlName('track'), [], []))
        //     .text;
        final track = int.tryParse(element.childElements
                .firstWhere((e) => e.name.local == 'track',
                    orElse: () => xml.XmlElement(xml.XmlName('track'), [], []))
                .text) ??
            0;

// Album logic first
        final existingAlbum = await _isarService.getAlbumByTitle(albumName);
        if (existingAlbum == null) {
          final album = Album(albumName)..artist = artistName;
          await _isarService.saveAlbum(album);
          print('saved album: $albumName - $artistName');
          // Or use saveSongWithAlbum here if preferred
        } else {
          // Handle case where song already exists (e.g., log or update)
          print('album already exists');
        }

// Then handle song creation
        final song = Song(songName)
          ..artist = artistName
          ..track = track
          ..audioFileUrl = audioFilePath;

        final existingSong =
            await _isarService.getSongByAudioFileUrl(song.audioFileUrl);

        if (existingSong == null) {
          final album = existingAlbum ??
              await _isarService.getAlbumByTitle(
                  albumName); // Get album if not already fetched
          // The ! is safe here since we know the album exists
          await _isarService.saveSongWithAlbum(song, album!);
          print('saved song: $track -Song: $songName $artistName $albumName');
        } else {
          // Handle case where song already exists (e.g., log or update)
          print('Song already exists');
        }
      }
      debugPrint("end of getSongsFromXml");
    }
  }
}
