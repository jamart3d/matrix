// lib/pages/settings_page.dart

import 'package:flutter/material.dart';
import 'package:huntrix/pages/about_page.dart';
import 'package:provider/provider.dart';
import 'package:huntrix/providers/album_settings_provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    const titleStyle = TextStyle(color: Colors.white);
    final subtitleStyle = TextStyle(color: Colors.grey.shade400);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Settings'),
      ),
      body: Consumer<AlbumSettingsProvider>(
        builder: (context, settingsProvider, child) {
          return ListView(
            children: <Widget>[
              const ListTile(
                title: Text("General", style: TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold)),
              ),
              SwitchListTile(
                title: const Text('Skip Shows Page on Startup', style: titleStyle),
                subtitle: Text('Go directly to the albums list.', style: subtitleStyle),
                value: settingsProvider.skipShowsPage,
                onChanged: (bool value) => settingsProvider.setSkipShowsPage(value),
                activeColor: Colors.yellow,
                secondary: const Icon(Icons.fast_forward, color: Colors.white70),
              ),
              const Divider(color: Colors.white24),

              const ListTile(
                title: Text("Shows Page", style: TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold)),
              ),
              SwitchListTile(
                title: const Text('Scrolling Show List Titles', style: titleStyle),
                subtitle: Text('Scroll long titles that don\'t fit in the list.', style: subtitleStyle),
                value: settingsProvider.marqueeTitles,
                onChanged: (bool value) => settingsProvider.setMarqueeTitles(value),
                activeColor: Colors.yellow,
                secondary: const Icon(Icons.text_fields, color: Colors.white70),
              ),
              ListTile(
                leading: const Icon(Icons.sort_by_alpha, color: Colors.white70),
                title: const Text('Default Show Sort Order', style: titleStyle),
                subtitle: Text(
                  settingsProvider.showSortOrder == ShowSortOrder.dateDescending
                    ? 'Newest First'
                    : 'Oldest First',
                  style: subtitleStyle,
                ),
                trailing: PopupMenuButton<ShowSortOrder>(
                  onSelected: (ShowSortOrder result) {
                    settingsProvider.setShowSortOrder(result);
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<ShowSortOrder>>[
                    const PopupMenuItem<ShowSortOrder>(
                      value: ShowSortOrder.dateDescending,
                      child: Text('Newest First'),
                    ),
                    const PopupMenuItem<ShowSortOrder>(
                      value: ShowSortOrder.dateAscending,
                      child: Text('Oldest First'),
                    ),
                  ],
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
                ),
              ),
              const Divider(color: Colors.white24),

              const ListTile(
                title: Text("Player Page", style: TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold)),
              ),
              // --- NEW PLAYER MARQUEE SETTING ---
              SwitchListTile(
                title: const Text('Scrolling Player Title', style: titleStyle),
                subtitle: Text('Scroll long titles in the player app bar.', style: subtitleStyle),
                value: settingsProvider.marqueePlayerTitle,
                onChanged: (bool value) => settingsProvider.setMarqueePlayerTitle(value),
                activeColor: Colors.yellow,
                secondary: const Icon(Icons.text_format, color: Colors.white70),
              ),
              const Divider(color: Colors.white24),

              const ListTile(
                title: Text("Albums Page", style: TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold)),
              ),
              SwitchListTile(
                title: const Text("Display release order number", style: titleStyle),
                subtitle: Text("Shows the # next to each album.", style: subtitleStyle),
                value: settingsProvider.displayAlbumReleaseNumber,
                onChanged: (newValue) => settingsProvider.setDisplayAlbumReleaseNumber(newValue),
                activeColor: Colors.yellow,
                secondary: const Icon(Icons.format_list_numbered, color: Colors.white70),
              ),
              const Divider(color: Colors.white24),

              ListTile(
                leading: const Icon(Icons.info_outline, color: Colors.white70),
                title: const Text("About", style: titleStyle),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AboutPage()),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}