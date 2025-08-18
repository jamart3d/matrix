// lib/pages/settings_page.dart

import 'package:flutter/material.dart';
import 'package:matrix/pages/about_page.dart';
import 'package:provider/provider.dart';
import 'package:matrix/providers/album_settings_provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  String _getScrollbarBehaviorText(YearScrollbarBehavior behavior) {
    switch (behavior) {
      case YearScrollbarBehavior.onScroll: return 'While Scrolling';
      case YearScrollbarBehavior.always: return 'Always On';
      case YearScrollbarBehavior.off: return 'Off';
    }
  }

  String _getStartupPageText(StartupPage page) {
    switch (page) {
      case StartupPage.shows: return 'Shows Page (Default)';
      case StartupPage.albums: return 'Albums Page';
      case StartupPage.matrix: return 'Matrix Rain Page';
    }
  }

  String _getMatrixTitleStyleText(MatrixTitleStyle style) {
    switch (style) {
      case MatrixTitleStyle.random: return 'Random Colors';
      case MatrixTitleStyle.gradient: return 'Smooth Gradient';
      case MatrixTitleStyle.solid: return 'Solid Color';
    }
  }

  String _getMatrixFillerStyleText(MatrixFillerStyle style) {
    switch (style) {
      case MatrixFillerStyle.dimmed: return 'Dimmed (Default)';
      case MatrixFillerStyle.themed: return 'Match Theme Color';
      case MatrixFillerStyle.invisible: return 'Invisible';
    }
  }

  String _getMatrixColorThemeText(MatrixColorTheme theme) {
    switch (theme) {
      case MatrixColorTheme.classicGreen: return 'Classic Green';
      case MatrixColorTheme.cyanBlue: return 'Cyan Blue';
      case MatrixColorTheme.purpleMatrix: return 'Purple Matrix';
      case MatrixColorTheme.redAlert: return 'Red Alert';
      case MatrixColorTheme.goldLux: return 'Gold Luxury';
    }
  }

  String _getFillerColorText(MatrixFillerColor color) {
    switch (color) {
      case MatrixFillerColor.defaultGray: return 'Default Gray';
      case MatrixFillerColor.green: return 'Green';
      case MatrixFillerColor.cyan: return 'Cyan';
      case MatrixFillerColor.purple: return 'Purple';
      case MatrixFillerColor.red: return 'Red';
      case MatrixFillerColor.gold: return 'Gold';
      case MatrixFillerColor.white: return 'White';
    }
  }

  String _getMatrixGlowStyleText(MatrixGlowStyle style) {
    switch (style) {
      case MatrixGlowStyle.all: return 'All Columns';
      case MatrixGlowStyle.current: return 'Currently Playing Only';
      case MatrixGlowStyle.none: return 'None';
    }
  }

  String _getLeadingColorText(MatrixLeadingColor color) {
    switch (color) {
      case MatrixLeadingColor.white: return 'White (Default)';
      case MatrixLeadingColor.green: return 'Green';
      case MatrixLeadingColor.cyan: return 'Cyan';
      case MatrixLeadingColor.purple: return 'Purple';
      case MatrixLeadingColor.red: return 'Red';
      case MatrixLeadingColor.gold: return 'Gold';
    }
  }

  Color _getLeadingColorValue(MatrixLeadingColor color) {
    switch (color) {
      case MatrixLeadingColor.white: return Colors.white;
      case MatrixLeadingColor.green: return Colors.green;
      case MatrixLeadingColor.cyan: return Colors.cyan;
      case MatrixLeadingColor.purple: return Colors.purpleAccent;
      case MatrixLeadingColor.red: return Colors.redAccent;
      case MatrixLeadingColor.gold: return Colors.amber;
    }
  }

  Color _getFillerColorValue(MatrixFillerColor color) {
    switch (color) {
      case MatrixFillerColor.defaultGray: return const Color(0xFF282828);
      case MatrixFillerColor.green: return Colors.green;
      case MatrixFillerColor.cyan: return Colors.cyan;
      case MatrixFillerColor.purple: return Colors.purple;
      case MatrixFillerColor.red: return Colors.red;
      case MatrixFillerColor.gold: return Colors.amber;
      case MatrixFillerColor.white: return Colors.grey.shade400;
    }
  }

  Color _getThemePreviewColor(MatrixColorTheme theme) {
    switch (theme) {
      case MatrixColorTheme.classicGreen: return Colors.green;
      case MatrixColorTheme.cyanBlue: return Colors.cyan;
      case MatrixColorTheme.purpleMatrix: return Colors.purple;
      case MatrixColorTheme.redAlert: return Colors.red;
      case MatrixColorTheme.goldLux: return Colors.amber;
    }
  }

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
          final isDimmedFiller = settings.matrixFillerStyle == MatrixFillerStyle.dimmed;
          return ListView(
            children: <Widget>[
              const ListTile(title: Text("General", style: headerStyle)),
              ListTile(
                leading: const Icon(Icons.login, color: iconColor),
                title: const Text('Startup Page', style: titleStyle),
                subtitle: Text(_getStartupPageText(settings.startupPage), style: subtitleStyle),
                trailing: PopupMenuButton<StartupPage>(
                  onSelected: settings.setStartupPage,
                  itemBuilder: (ctx) => StartupPage.values.map((page) => PopupMenuItem(value: page, child: Text(_getStartupPageText(page)))).toList(),
                  icon: const Icon(Icons.arrow_drop_down, color: iconColor),
                ),
              ),
              const Divider(color: Colors.white24),
              const ListTile(title: Text("Shows Page", style: headerStyle)),
              ListTile(
                leading: const Icon(Icons.timeline, color: iconColor),
                title: const Text('Year Scrollbar Behavior', style: titleStyle),
                subtitle: Text(_getScrollbarBehaviorText(settings.yearScrollbarBehavior), style: subtitleStyle),
                trailing: PopupMenuButton<YearScrollbarBehavior>(
                  onSelected: settings.setYearScrollbarBehavior,
                  itemBuilder: (ctx) => YearScrollbarBehavior.values.map((s) => PopupMenuItem(value: s, child: Text(_getScrollbarBehaviorText(s)))).toList(),
                  icon: const Icon(Icons.arrow_drop_down, color: iconColor),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.sort_by_alpha, color: iconColor),
                title: const Text('Default Show Sort Order', style: titleStyle),
                subtitle: Text(settings.showSortOrder == ShowSortOrder.dateDescending ? 'Newest First' : 'Oldest First', style: subtitleStyle),
                trailing: PopupMenuButton<ShowSortOrder>(
                  onSelected: settings.setShowSortOrder,
                  itemBuilder: (ctx) => const [
                    PopupMenuItem(value: ShowSortOrder.dateDescending, child: Text('Newest First')),
                    PopupMenuItem(value: ShowSortOrder.dateAscending, child: Text('Oldest First')),
                  ],
                  icon: const Icon(Icons.arrow_drop_down, color: iconColor),
                ),
              ),
              const Divider(color: Colors.white24),
              const ListTile(title: Text("Player Page", style: headerStyle)),
              SwitchListTile(
                title: const Text('Scrolling Player Title', style: titleStyle),
                subtitle: Text('Scroll long titles in the player app bar.', style: subtitleStyle),
                value: settings.marqueePlayerTitle,
                onChanged: settings.setMarqueePlayerTitle,
                secondary: const Icon(Icons.text_format, color: iconColor),
                activeColor: Colors.yellow,
              ),
              SwitchListTile(
                title: const Text('Show Buffer Info', style: titleStyle),
                subtitle: Text('Displays buffer health in the player.', style: subtitleStyle),
                value: settings.showBufferInfo,
                onChanged: settings.setShowBufferInfo,
                secondary: const Icon(Icons.science, color: iconColor),
                activeColor: Colors.yellow,
              ),
              const Divider(color: Colors.white24),
              const ListTile(title: Text("Hunter's trix Page", style: headerStyle)),
              SwitchListTile(
                title: const Text("Display release order number", style: titleStyle),
                subtitle: Text("Shows the # next to each album.", style: subtitleStyle),
                value: settings.displayAlbumReleaseNumber,
                onChanged: settings.setDisplayAlbumReleaseNumber,
                secondary: const Icon(Icons.format_list_numbered, color: iconColor),
                activeColor: Colors.yellow,
              ),
              const Divider(color: Colors.white24),
              const ListTile(title: Text("Matrix Page", style: headerStyle)),
              ListTile(
                leading: const Icon(Icons.speed, color: iconColor),
                title: const Text('Rain Density', style: titleStyle),
                subtitle: Text('Controls how frequently new text columns appear.', style: subtitleStyle),
              ),
              Slider(
                value: settings.matrixRainSpeed,
                min: 1.0, max: 10.0, divisions: 9,
                label: settings.matrixRainSpeed.round().toString(),
                activeColor: Colors.yellow,
                inactiveColor: Colors.grey,
                onChanged: settings.setMatrixRainSpeed,
              ),
              ListTile(
                leading: const Icon(Icons.auto_awesome, color: iconColor),
                title: const Text('Glow Effects', style: titleStyle),
                subtitle: Text(_getMatrixGlowStyleText(settings.matrixGlowStyle), style: subtitleStyle),
                trailing: PopupMenuButton<MatrixGlowStyle>(
                  onSelected: settings.setMatrixGlowStyle,
                  itemBuilder: (ctx) => MatrixGlowStyle.values.map((style) => PopupMenuItem(
                    value: style,
                    child: Text(_getMatrixGlowStyleText(style)),
                  )).toList(),
                  icon: const Icon(Icons.arrow_drop_down, color: iconColor),
                ),
              ),
              SwitchListTile(
                title: const Text('Ripple Effects', style: titleStyle),
                subtitle: Text('Show ripple animations when tapping columns.', style: subtitleStyle),
                value: settings.matrixRippleEffects,
                onChanged: settings.setMatrixRippleEffects,
                secondary: const Icon(Icons.radio_button_unchecked, color: iconColor),
                activeColor: Colors.yellow,
              ),
              ListTile(
                leading: const Icon(Icons.gradient, color: iconColor),
                title: const Text('Title Color Style', style: titleStyle),
                subtitle: Text(_getMatrixTitleStyleText(settings.matrixTitleStyle), style: subtitleStyle),
                trailing: PopupMenuButton<MatrixTitleStyle>(
                  onSelected: settings.setMatrixTitleStyle,
                  itemBuilder: (ctx) => MatrixTitleStyle.values.map((style) => PopupMenuItem(
                    value: style,
                    child: Text(_getMatrixTitleStyleText(style)),
                  )).toList(),
                  icon: const Icon(Icons.arrow_drop_down, color: iconColor),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.format_color_text, color: iconColor),
                title: const Text('Filler Character Style', style: titleStyle),
                subtitle: Text(_getMatrixFillerStyleText(settings.matrixFillerStyle), style: subtitleStyle),
                trailing: PopupMenuButton<MatrixFillerStyle>(
                  onSelected: settings.setMatrixFillerStyle,
                  itemBuilder: (ctx) => MatrixFillerStyle.values.map((style) => PopupMenuItem(
                    value: style,
                    child: Text(_getMatrixFillerStyleText(style)),
                  )).toList(),
                  icon: const Icon(Icons.arrow_drop_down, color: iconColor),
                ),
              ),
              ListTile(
                leading: Icon(Icons.colorize, color: isDimmedFiller ? iconColor : Colors.grey.shade700),
                title: Text('Filler Color', style: isDimmedFiller ? titleStyle : titleStyle.copyWith(color: Colors.grey.shade700)),
                subtitle: Text(
                  'Base color for the "Dimmed" style.',
                  style: isDimmedFiller ? subtitleStyle : subtitleStyle.copyWith(color: Colors.grey.shade700),
                ),
                enabled: isDimmedFiller,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 20, height: 20,
                      decoration: BoxDecoration(
                        color: isDimmedFiller ? _getFillerColorValue(settings.matrixFillerColor) : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(color: isDimmedFiller ? Colors.white54 : Colors.grey.shade700),
                      ),
                    ),
                    PopupMenuButton<MatrixFillerColor>(
                      onSelected: settings.setMatrixFillerColor,
                      enabled: isDimmedFiller,
                      itemBuilder: (ctx) => MatrixFillerColor.values.map((color) => PopupMenuItem(
                        value: color,
                        child: Row(
                          children: [
                            Container(width: 16, height: 16, decoration: BoxDecoration(color: _getFillerColorValue(color), shape: BoxShape.circle), margin: const EdgeInsets.only(right: 8)),
                            Text(_getFillerColorText(color)),
                          ],
                        ),
                      )).toList(),
                      icon: Icon(Icons.arrow_drop_down, color: isDimmedFiller ? iconColor : Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.wb_sunny, color: iconColor),
                title: const Text('Leading Character Color', style: titleStyle),
                subtitle: Text('Color of the main falling character.', style: subtitleStyle),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 20, height: 20,
                      decoration: BoxDecoration(
                        color: _getLeadingColorValue(settings.matrixLeadingColor),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white54),
                      ),
                    ),
                    PopupMenuButton<MatrixLeadingColor>(
                      onSelected: settings.setMatrixLeadingColor,
                      itemBuilder: (ctx) => MatrixLeadingColor.values.map((color) => PopupMenuItem(
                        value: color,
                        child: Row(
                          children: [
                            Container(width: 16, height: 16, decoration: BoxDecoration(color: _getLeadingColorValue(color), shape: BoxShape.circle), margin: const EdgeInsets.only(right: 8)),
                            Text(_getLeadingColorText(color)),
                          ],
                        ),
                      )).toList(),
                      icon: const Icon(Icons.arrow_drop_down, color: iconColor),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.palette, color: iconColor),
                title: const Text('Color Theme', style: titleStyle),
                subtitle: Text(_getMatrixColorThemeText(settings.matrixColorTheme), style: subtitleStyle),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 20, height: 20,
                      decoration: BoxDecoration(
                        color: _getThemePreviewColor(settings.matrixColorTheme),
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: _getThemePreviewColor(settings.matrixColorTheme).withOpacity(0.5), blurRadius: 4, spreadRadius: 1)],
                      ),
                    ),
                    PopupMenuButton<MatrixColorTheme>(
                      onSelected: settings.setMatrixColorTheme,
                      itemBuilder: (ctx) => MatrixColorTheme.values.map((theme) => PopupMenuItem(
                        value: theme,
                        child: Row(
                          children: [
                            Container(width: 16, height: 16, decoration: BoxDecoration(color: _getThemePreviewColor(theme), shape: BoxShape.circle), margin: const EdgeInsets.only(right: 8)),
                            Text(_getMatrixColorThemeText(theme)),
                          ],
                        ),
                      )).toList(),
                      icon: const Icon(Icons.arrow_drop_down, color: iconColor),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.view_column, color: iconColor),
                title: const Text('Maximum Columns', style: titleStyle),
                subtitle: Text('Limits columns for better performance (${settings.matrixColumnLimit} columns).', style: subtitleStyle),
              ),
              Slider(
                value: settings.matrixColumnLimit.toDouble(),
                min: 20.0, max: 100.0, divisions: 8,
                label: settings.matrixColumnLimit.toString(),
                activeColor: Colors.yellow,
                inactiveColor: Colors.grey,
                onChanged: (v) => settings.setMatrixColumnLimit(v.round()),
              ),
              ListTile(
                leading: const Icon(Icons.brightness_6, color: iconColor),
                title: const Text('Visual Feedback Intensity', style: titleStyle),
                subtitle: Text('Controls brightness of tap and highlight effects.', style: subtitleStyle),
              ),
              Slider(
                value: settings.matrixFeedbackIntensity,
                min: 0.1, max: 2.0, divisions: 19,
                label: '${(settings.matrixFeedbackIntensity * 100).round()}%',
                activeColor: Colors.yellow,
                inactiveColor: Colors.grey,
                onChanged: settings.setMatrixFeedbackIntensity,
              ),
              if (settings.showBufferInfo)
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.grey.shade900, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade700)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Matrix Performance Tips:', style: TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('• Lower column limit for older devices\n• Disable effects if experiencing lag\n• Higher rain density increases CPU usage', style: TextStyle(color: Colors.grey.shade300, fontSize: 12)),
                    ],
                  ),
                ),
              const Divider(color: Colors.white24),
              ListTile(
                leading: const Icon(Icons.info_outline, color: iconColor),
                title: const Text("About", style: titleStyle),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutPage())),
              ),
            ],
          );
        },
      ),
    );
  }
}