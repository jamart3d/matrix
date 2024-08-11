import 'package:flutter/material.dart';
import 'package:myapp/pages/albums_list_page2.dart';
//import 'package:myapp/pages/alternate_xml_page.dart';
//import 'package:myapp/pages/backgroud_downloader_page.dart';
import 'package:myapp/pages/editable_list_page2.dart';
//import 'package:myapp/pages/music_view.dart';
import 'package:myapp/pages/settings_page.dart';
import 'package:myapp/pages/songs_list_page2.dart';
//import 'package:myapp/pages/url_list_page.dart';

class MyDrawer extends StatelessWidget {
  const MyDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            child: Center(
              child: Image.asset('assets/images/steal10.png'),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text("Home"),
            onTap: () {
              Navigator.pop(context);
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(builder: (context) => MusicPage()),
              // );
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text("Settings"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit), // You can choose a suitable icon
            title: const Text("Url List"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const EditableListPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.list),
            title: const Text("Alternate Xmls"),
            onTap: () {
              Navigator.pop(context);
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(
              //       builder: (context) => const AlternateXmlPage()),
              // );
            },
          ),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text("Background Downloader"),
            onTap: () {
              Navigator.pop(context);
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(
              //       builder: (context) => const BackgroundDownloaderPage()),
              // );
            },
          ),
          ListTile(
            leading: const Icon(Icons.music_note),
            title: const Text("albums list"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AlbumsListPage()),
              );
            },
          ),
                    ListTile(
            leading: const Icon(Icons.music_note),
            title: const Text("songs list"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) =>  SongsListPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.list_alt),
            title: const Text("url2"),
            onTap: () {
              Navigator.pop(context);
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(builder: (context) =>  UrlListPage()),
              // );
            },
          ),
        ],
      ),
    );
  }
}
