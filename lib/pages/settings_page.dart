// lib/pages/settings_page.dart

import 'package:flutter/material.dart';
import 'package:matrix/pages/about_page.dart';
import 'package:provider/provider.dart';
import 'package:matrix/providers/album_settings_provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    const titleStyle = TextStyle(color: Colors.white);
    final subtitleStyle = TextStyle(color: Colors.grey.shade400);
    const headerStyle = TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold);
    const iconColor = Colors.white70;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Settings'),
      ),
      body: Consumer<AlbumSettingsProvider>(
        builder: (context, settings, child) {
          return ListView(
            children: <Widget>[
              const ListTile(title: Text("General", style: headerStyle)),
              SwitchListTile(
                title: const Text('Skip Shows Page on Startup', style: titleStyle),
                value: settings.skipShowsPage,
                onChanged: settings.setSkipShowsPage,
                secondary: const Icon(Icons.fast_forward, color: iconColor),
              ),
              const Divider(color: Colors.white24),

              const ListTile(title: Text("Shows Page", style: headerStyle)),
              // ... (Shows Page settings are unchanged) ...
              SwitchListTile(
                title: const Text('Scrolling Show List Titles', style: titleStyle),
                subtitle: Text('Scroll long titles that don\'t fit.', style: subtitleStyle),
                value: settings.marqueeTitles,
                onChanged: (bool value) => settings.setMarqueeTitles(value),
                activeColor: Colors.yellow,
                secondary: const Icon(Icons.text_fields, color: Colors.white70),
              ),
              SwitchListTile(
                title: const Text('Single Expanded Item', style: titleStyle),
                subtitle: Text('Only allow one show to be expanded at a time.', style: subtitleStyle),
                value: settings.singleExpansion,
                onChanged: (bool value) => settings.setSingleExpansion(value),
                activeColor: Colors.yellow,
                secondary: const Icon(Icons.playlist_add_check, color: Colors.white70),
              ),
              SwitchListTile(
                title: const Text('Show Year Scrollbar', style: titleStyle),
                subtitle: Text('Display year indicator while scrolling shows.', style: subtitleStyle),
                value: settings.showYearScrollbar,
                onChanged: (bool value) => settings.setShowYearScrollbar(value),
                activeColor: Colors.yellow,
                secondary: const Icon(Icons.timeline, color: Colors.white70),
              ),
              ListTile(
                leading: const Icon(Icons.sort_by_alpha, color: Colors.white70),
                title: const Text('Default Show Sort Order', style: titleStyle),
                subtitle: Text(
                  settings.showSortOrder == ShowSortOrder.dateDescending
                      ? 'Newest First'
                      : 'Oldest First',
                  style: subtitleStyle,
                ),
                trailing: PopupMenuButton<ShowSortOrder>(
                  onSelected: (ShowSortOrder result) {
                    settings.setShowSortOrder(result);
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

              const ListTile(title: Text("Player Page", style: headerStyle)),
              SwitchListTile(
                title: const Text('Scrolling Player Title', style: titleStyle),
                value: settings.marqueePlayerTitle,
                onChanged: settings.setMarqueePlayerTitle,
                secondary: const Icon(Icons.text_format, color: iconColor),
              ),
              // --- SWITCHLISTTILE RESTORED ---
              SwitchListTile(
                title: const Text('Show Buffer Info (Debug)', style: titleStyle),
                subtitle: Text('Displays buffer health in the player.', style: subtitleStyle),
                value: settings.showBufferInfo,
                onChanged: settings.setShowBufferInfo,
                activeColor: Colors.yellow,
                secondary: const Icon(Icons.science, color: iconColor),
              ),
              const Divider(color: Colors.white24),

              const ListTile(title: Text("Albums Page", style: headerStyle)),
              SwitchListTile(
                title: const Text("Display release order number", style: titleStyle),
                value: settings.displayAlbumReleaseNumber,
                onChanged: settings.setDisplayAlbumReleaseNumber,
                secondary: const Icon(Icons.format_list_numbered, color: iconColor),
              ),
              const Divider(color: Colors.white24),

              const ListTile(title: Text("Matrix Rain", style: headerStyle)),
              ListTile(
                leading: const Icon(Icons.speed, color: iconColor),
                title: const Text('Rain Density', style: titleStyle),
                subtitle: Text('Controls how frequently new text columns appear.', style: subtitleStyle),
              ),
              Slider(
                value: settings.matrixRainSpeed,
                min: 1.0,
                max: 10.0,
                divisions: 9,
                label: settings.matrixRainSpeed.round().toString(),
                activeColor: Colors.yellow,
                inactiveColor: Colors.grey,
                onChanged: settings.setMatrixRainSpeed,
              ),
              const Divider(color: Colors.white24),

              const ListTile(title: Text("Extras", style: headerStyle)),
              ListTile(
                leading: const Icon(Icons.info_outline, color: iconColor),
                title: const Text("About", style: titleStyle),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutPage()));
                },
              ),
            ],
          );
        },
      ),
    );
  }
}