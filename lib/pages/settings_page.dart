import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myapp/services/isar_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  ThemeMode _themeMode = ThemeMode.system;
  int _concurrentDownloads = 3;
  bool _buildXmls = false; // New setting for building XMLs
  final IsarService _isarService = IsarService();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
      _themeMode = ThemeMode.values[prefs.getInt('themeMode') ?? 0];
      _concurrentDownloads = prefs.getInt('concurrentDownloads') ?? 3;
      _buildXmls = prefs.getBool('buildXmls') ?? false;
    });
  }

  Future<void> _saveSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationsEnabled', _notificationsEnabled);
    await prefs.setInt('themeMode', _themeMode.index);
    await prefs.setInt('concurrentDownloads', _concurrentDownloads);
    await prefs.setBool('buildXmls', _buildXmls);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: <Widget>[
          ListTile(
            title: const Text('Notifications'),
            trailing: Switch(
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() {
                  _notificationsEnabled = value;
                  _saveSettings();
                });
              },
            ),
          ),
          ListTile(
            title: const Text('Build XMLs'),
            trailing: Switch(
              value: _buildXmls,
              onChanged: (value) {
                setState(() {
                  _buildXmls = value;
                  print(value);
                  _saveSettings();
                });
              },
            ),
          ),
          ListTile(
            title: const Text('Max Concurrent Downloads'),
            trailing: SizedBox(
              width: 150, // Adjust width as needed
              child: Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: _concurrentDownloads.toDouble(),
                      min: 1,
                      max: 5,
                      divisions: 4,
                      label: _concurrentDownloads.toString(),
                      onChanged: (value) {
                        setState(() {
                          _concurrentDownloads = value.toInt();
                          _saveSettings();
                        });
                      },
                    ),
                  ),
                  Text(_concurrentDownloads.toString()),
                ],
              ),
            ),
          ),
           ListTile(
            title: const Text('Clear Database'),
            onTap: () {
              _showClearDatabaseConfirmationDialog(context);
            },
          ),
 
        ],
      ),
    );
  }

  String _getThemeModeTitle(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'System Theme';
      case ThemeMode.light:
        return 'Light Theme';
      case ThemeMode.dark:
        return 'Dark Theme';
    }
  }


Future<void> _showClearDatabaseConfirmationDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Clear Database'),
          content: SingleChildScrollView(
            child: ListBody(
              children: const <Widget>[
                Text('Are you sure you want to clear the entire database? This action cannot be undone.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Clear'),
              onPressed: () async {
                // Clear all collections in the Isar database
                await _isarService.clearAllData();
                
                Navigator.of(context).pop();
                // Optionally show a success message
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Database cleared successfully')),
                );
              },
            ),
          ],
        );
      },
    );
  }
}


