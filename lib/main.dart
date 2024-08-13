import 'dart:math';

import 'package:flutter/material.dart';
import 'package:myapp/services/isar_service.dart';
import 'package:myapp/isar_collections/album.dart';
import 'package:myapp/pages/albums_page.dart';
import 'package:myapp/isar_collections/song.dart';
import 'package:myapp/isar_collections/artist.dart';
import 'package:myapp/components/my_drawer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await IsarService().initialize();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Music App',
      debugShowCheckedModeBanner: false,
      // home: MyHomePage(albums: albums, songs: songs, artists: artists, isarService: isarService),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context)
{
    return Scaffold(
      appBar: AppBar(
        title: const Text('Music App'),
      ),
        drawer:MyDrawer(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
                onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AlbumsPage()),
                );
              },
              child: const Text('View Albums'),
            ),
          ],
        ),
      ),
    );
  }
}


