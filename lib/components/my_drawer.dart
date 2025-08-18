// lib/components/my_drawer.dart

import 'package:flutter/material.dart';
import '../routes.dart';

class MyDrawer extends StatelessWidget {
  const MyDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container( // Wrap with a container for a solid background color
        color: Colors.grey[900], // A dark background for the drawer body
        child: Column(
          children: [
            DrawerHeader(
              padding: EdgeInsets.zero,
              margin: EdgeInsets.zero,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/t_steal.webp',
                    fit: BoxFit.cover,
                  ),
                  Container(color: Colors.black.withOpacity(0.5)),
                  const Center(
                    child: Text(
                      'Options',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Drawer Body - Links
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  ListTile(
                    leading: const Icon(Icons.music_note, color: Colors.white70),
                    title: const Text('Shows', style: TextStyle(color: Colors.white)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushReplacementNamed(context, Routes.showsPage);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.album, color: Colors.white70),
                    title: const Text('hunter\'s trix (List)', style: TextStyle(color: Colors.white)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushReplacementNamed(context, Routes.albumsPage);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.view_carousel, color: Colors.white70),
                    title: const Text('Hunter\'s trix (Wheel)', style: TextStyle(color: Colors.white)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushReplacementNamed(context, Routes.albumsListWheelPage);
                    },
                  ),
                  const Divider(color: Colors.white24),

                  ListTile(
                    leading: const Icon(Icons.grain, color: Colors.green),
                    title: const Text('select a matrix', style: TextStyle(color: Colors.white)),
                    onTap: () {
                      Navigator.pop(context); // Close the drawer first
                      Navigator.pushNamed(context, Routes.matrixRainPage);
                    },
                  ),
                  const Divider(color: Colors.white24),

                  ListTile(
                    leading: const Icon(Icons.settings, color: Colors.white70),
                    title: const Text('Settings', style: TextStyle(color: Colors.white)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, Routes.settingsPage);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}