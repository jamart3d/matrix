// lib/components/my_drawer.dart

import 'package:flutter/material.dart';
// import 'package:matrix/pages/about_page.dart';
import '../routes.dart';

class MyDrawer extends StatelessWidget {
  const MyDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: Colors.grey[900],
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
                      'matrix',
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
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  ListTile(
                    leading: const Icon(Icons.music_note, color: Colors.white70),
                    title: const Text('All Shows', style: TextStyle(color: Colors.white)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushReplacementNamed(context, Routes.showsPage);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.person_pin_circle, color: Colors.white70),
                    title: const Text('Seamons mixes', style: TextStyle(color: Colors.white)),
                    onTap: () {
                      Navigator.pop(context);
                      // --- FIX: Correctly navigate to shows page with argument ---
                      Navigator.pushReplacementNamed(context, Routes.showsPage, arguments: 'seamons');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.person_pin_circle, color: Colors.white70),
                    title: const Text("SirMick's mixes", style: TextStyle(color: Colors.white)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushReplacementNamed(context, Routes.showsPage, arguments: 'sirmick');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.person_pin_circle, color: Colors.white70),
                    title: const Text("Dusborne's mixes", style: TextStyle(color: Colors.white)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushReplacementNamed(context, Routes.showsPage, arguments: 'dusborne');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.mic_none_rounded, color: Colors.white70),
                    title: const Text("others", style: TextStyle(color: Colors.white)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushReplacementNamed(context, Routes.showsPage, arguments: 'misc');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.lightbulb_circle, color: Colors.white70),
                    title: const Text('Wheel', style: TextStyle(color: Colors.white)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushReplacementNamed(context, Routes.albumsListWheelPage);
                    },
                  ),
                  const Divider(color: Colors.white24),
                  ListTile(
                    leading: const Icon(Icons.grain, color: Colors.green),
                    title: const Text('Select a matrix', style: TextStyle(color: Colors.white)),
                    onTap: () {
                      Navigator.pop(context);
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
                  ListTile(
                    leading: const Icon(Icons.info_outline, color: Colors.white70),
                    title: const Text('About', style: TextStyle(color: Colors.white)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, Routes.aboutPage);
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