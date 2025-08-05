import 'package:flutter/material.dart';
import 'package:huntrix/pages/about_page.dart'; // Make sure this page exists
import 'package:provider/provider.dart';
import 'package:huntrix/providers/album_settings_provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Define the text styles once for consistency
    const titleStyle = TextStyle(color: Colors.white);
    final subtitleStyle = TextStyle(color: Colors.grey.shade400);
    final focusColor = Colors.yellow.withOpacity(0.5);

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
              // --- Your existing setting, now with correct styling ---
              SwitchListTile(
                // **CORRECTED:** Style is applied directly to the Text widget.
                title: const Text(
                  "Display release order number",
                  style: titleStyle,
                ),
                subtitle: Text(
                  "Shows the # next to each album.",
                  style: subtitleStyle,
                ),
                value: settingsProvider.displayAlbumReleaseNumber,
                onChanged: (newValue) {
                  settingsProvider.setDisplayAlbumReleaseNumber(newValue);
                },
                activeColor: Colors.yellow,
                tileColor: Colors.transparent,
                secondary: const Icon(Icons.format_list_numbered, color: Colors.white70),
              ),
              const Divider(color: Colors.white24),

              // --- The new setting, now with correct styling ---
              SwitchListTile(
                // **CORRECTED:** Style is applied directly to the Text widget.
                title: const Text(
                  'Skip Shows Page on Startup',
                  style: titleStyle,
                ),
                subtitle: Text(
                  'Go directly to the albums list.',
                  style: subtitleStyle,
                ),
                value: settingsProvider.skipShowsPage,
                onChanged: (bool value) {
                  settingsProvider.setSkipShowsPage(value);
                },
                activeColor: Colors.yellow,
                tileColor: Colors.transparent,
                secondary: const Icon(Icons.fast_forward, color: Colors.white70),
              ),
              const Divider(color: Colors.white24),

              // --- Your existing "About" link ---
              ListTile(
                leading: const Icon(Icons.info_outline, color: Colors.white70),
                // **CORRECTED:** Style is applied directly to the Text widget.
                title: const Text(
                  "About",
                  style: titleStyle,
                ),
                focusColor: focusColor,
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