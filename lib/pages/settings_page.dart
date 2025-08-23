// lib/pages/settings_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:matrix/providers/album_settings_provider.dart';
import 'package:matrix/providers/enums.dart';

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
      case StartupPage.albums: return 'Seamons Page';
      case StartupPage.matrix: return 'Matrix Page';
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

  String _getGlowIntensityText(MatrixGlowIntensity intensity) {
    switch (intensity) {
      case MatrixGlowIntensity.half: return 'Half';
      case MatrixGlowIntensity.normal: return 'Normal (Default)';
      case MatrixGlowIntensity.double: return 'Double';
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

  String _getMatrixStepModeText(MatrixStepMode mode) {
    switch (mode) {
      case MatrixStepMode.smooth: return 'Smooth';
      case MatrixStepMode.stepped: return 'Stepped (Default)';
      case MatrixStepMode.chunky: return 'Chunky';
    }
  }

  String _getLaneSpacingText(MatrixLaneSpacing spacing) {
    switch (spacing) {
      case MatrixLaneSpacing.standard:
        return 'Standard (Small Gap)';
      case MatrixLaneSpacing.tight:
        return 'Tight (No Gap)';
      case MatrixLaneSpacing.overlap:
        return 'Overlap';
    }
  }

  String _getFabSizeText(FabSize size) {
    switch (size) {
      case FabSize.normal: return 'Normal';
      case FabSize.large: return 'Large';
    }
  }

  String _getMatrixFontWeightText(MatrixFontWeight weight) {
    switch (weight) {
      case MatrixFontWeight.normal: return 'Normal';
      case MatrixFontWeight.bold: return 'Bold';
    }
  }

  String _getMatrixFontSizeText(MatrixFontSize size) {
    switch (size) {
      case MatrixFontSize.small: return 'Small';
      case MatrixFontSize.medium: return 'Medium (Default)';
      case MatrixFontSize.large: return 'Large';
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
              ExpansionTile(
                key: const PageStorageKey('general_section'),
                initiallyExpanded: settings.isGeneralExpanded,
                onExpansionChanged: settings.setGeneralExpanded,
                title: const Text("General", style: headerStyle),
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.only(left: 32, right: 16),
                    leading: const Icon(Icons.login, color: iconColor),
                    title: const Text('Startup Page', style: titleStyle),
                    subtitle: Text(_getStartupPageText(settings.startupPage), style: subtitleStyle),
                    trailing: PopupMenuButton<StartupPage>(
                      onSelected: settings.setStartupPage,
                      itemBuilder: (ctx) => StartupPage.values.map((page) => PopupMenuItem(value: page, child: Text(_getStartupPageText(page)))).toList(),
                      icon: const Icon(Icons.arrow_drop_down, color: iconColor),
                    ),
                  ),
                ],
              ),
              const Divider(color: Colors.white24, height: 1),

              ExpansionTile(
                key: const PageStorageKey('shows_section'),
                initiallyExpanded: settings.isShowsExpanded,
                onExpansionChanged: settings.setShowsExpanded,
                title: const Text("Shows Page", style: headerStyle),
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.only(left: 32, right: 16),
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
                    contentPadding: const EdgeInsets.only(left: 32, right: 16),
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
                ],
              ),
              const Divider(color: Colors.white24, height: 1),

              ExpansionTile(
                key: const PageStorageKey('player_section'),
                initiallyExpanded: settings.isPlayerExpanded,
                onExpansionChanged: settings.setPlayerExpanded,
                title: const Text("Player & UI", style: headerStyle),
                children: [
                  SwitchListTile(
                    contentPadding: const EdgeInsets.only(left: 32, right: 16),
                    title: const Text('Scrolling Player Title', style: titleStyle),
                    subtitle: Text('Scroll long titles in the player app bar.', style: subtitleStyle),
                    value: settings.marqueePlayerTitle,
                    onChanged: settings.setMarqueePlayerTitle,
                    secondary: const Icon(Icons.text_format, color: iconColor),
                    activeColor: Colors.yellow,
                  ),
                  SwitchListTile(
                    contentPadding: const EdgeInsets.only(left: 32, right: 16),
                    title: const Text('Show Buffer Info', style: titleStyle),
                    subtitle: Text('Displays buffer health in the player.', style: subtitleStyle),
                    value: settings.showBufferInfo,
                    onChanged: settings.setShowBufferInfo,
                    secondary: const Icon(Icons.science, color: iconColor),
                    activeColor: Colors.yellow,
                  ),
                  ListTile(
                    contentPadding: const EdgeInsets.only(left: 32, right: 16),
                    leading: const Icon(Icons.play_circle_outline, color: iconColor),
                    title: const Text('Floating Action Button Size', style: titleStyle),
                    subtitle: Text('Affects the player button on the Shows and Matrix pages.', style: subtitleStyle),
                    trailing: PopupMenuButton<FabSize>(
                      onSelected: settings.setFabSize,
                      itemBuilder: (ctx) => FabSize.values.map((size) => PopupMenuItem(
                        value: size,
                        child: Text(_getFabSizeText(size)),
                      )).toList(),
                      icon: const Icon(Icons.arrow_drop_down, color: iconColor),
                    ),
                  ),
                ],
              ),
              const Divider(color: Colors.white24, height: 1),

              ExpansionTile(
                key: const PageStorageKey('hunter_section'),
                initiallyExpanded: settings.isHunterExpanded,
                onExpansionChanged: settings.setHunterExpanded,
                title: const Text("Hunter's trix Page", style: headerStyle),
                children: [
                  SwitchListTile(
                    contentPadding: const EdgeInsets.only(left: 32, right: 16),
                    title: const Text("Display release order number", style: titleStyle),
                    subtitle: Text("Shows the # next to each album.", style: subtitleStyle),
                    value: settings.displayAlbumReleaseNumber,
                    onChanged: settings.setDisplayAlbumReleaseNumber,
                    secondary: const Icon(Icons.format_list_numbered, color: iconColor),
                    activeColor: Colors.yellow,
                  ),
                ],
              ),
              const Divider(color: Colors.white24, height: 1),

              ExpansionTile(
                key: const PageStorageKey('matrix_section'),
                initiallyExpanded: settings.isMatrixExpanded,
                onExpansionChanged: settings.setMatrixExpanded,
                title: const Text("Matrix Page", style: headerStyle),
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.only(left: 32, right: 16),
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
                  SwitchListTile(
                    contentPadding: const EdgeInsets.only(left: 32, right: 16),
                    title: const Text('Half Speed Animation', style: titleStyle),
                    subtitle: Text('Slows down all rain animations.', style: subtitleStyle),
                    value: settings.matrixHalfSpeed,
                    onChanged: settings.setMatrixHalfSpeed,
                    secondary: const Icon(Icons.slow_motion_video, color: iconColor),
                    activeColor: Colors.yellow,
                  ),
                  ListTile(
                    contentPadding: const EdgeInsets.only(left: 32, right: 16),
                    leading: const Icon(Icons.show_chart, color: iconColor),
                    title: const Text('Step Animation Style', style: titleStyle),
                    subtitle: Text(_getMatrixStepModeText(settings.matrixStepMode), style: subtitleStyle),
                    trailing: PopupMenuButton<MatrixStepMode>(
                      onSelected: settings.setMatrixStepMode,
                      itemBuilder: (ctx) => MatrixStepMode.values.map((mode) => PopupMenuItem(
                        value: mode,
                        child: Text(_getMatrixStepModeText(mode)),
                      )).toList(),
                      icon: const Icon(Icons.arrow_drop_down, color: iconColor),
                    ),
                  ),
                  ListTile(
                    contentPadding: const EdgeInsets.only(left: 32, right: 16),
                    leading: const Icon(Icons.view_stream_outlined, color: iconColor),
                    title: const Text('Lane Spacing', style: titleStyle),
                    subtitle: Text('Adjusts the horizontal gap between columns.', style: subtitleStyle),
                    trailing: PopupMenuButton<MatrixLaneSpacing>(
                      onSelected: settings.setMatrixLaneSpacing,
                      itemBuilder: (ctx) => MatrixLaneSpacing.values.map((spacing) => PopupMenuItem(
                        value: spacing,
                        child: Text(_getLaneSpacingText(spacing)),
                      )).toList(),
                      icon: const Icon(Icons.arrow_drop_down, color: iconColor),
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: const EdgeInsets.only(left: 32, right: 16),
                    title: const Text('Allow Overlap', style: titleStyle),
                    subtitle: Text('Allow new columns to spawn on top of existing ones.', style: subtitleStyle),
                    value: settings.matrixAllowOverlap,
                    onChanged: settings.setMatrixAllowOverlap,
                    secondary: const Icon(Icons.layers, color: iconColor),
                    activeColor: Colors.yellow,
                  ),
                  ListTile(
                    contentPadding: const EdgeInsets.only(left: 32, right: 16),
                    leading: const Icon(Icons.highlight, color: iconColor),
                    title: const Text('Glow Intensity', style: titleStyle),
                    subtitle: Text('Set the brightness of the glow effect.', style: subtitleStyle),
                    trailing: PopupMenuButton<MatrixGlowIntensity>(
                      onSelected: settings.setMatrixGlowIntensity,
                      itemBuilder: (ctx) => MatrixGlowIntensity.values.map((intensity) => PopupMenuItem(
                        value: intensity,
                        child: Text(_getGlowIntensityText(intensity)),
                      )).toList(),
                      icon: const Icon(Icons.arrow_drop_down, color: iconColor),
                    ),
                  ),
                  ListTile(
                    contentPadding: const EdgeInsets.only(left: 32, right: 16),
                    leading: const Icon(Icons.font_download_outlined, color: iconColor),
                    title: const Text('Font Size', style: titleStyle),
                    subtitle: Text('Adjust the size of the falling characters.', style: subtitleStyle),
                    trailing: PopupMenuButton<MatrixFontSize>(
                      onSelected: settings.setMatrixFontSize,
                      itemBuilder: (ctx) => MatrixFontSize.values.map((size) => PopupMenuItem(
                        value: size,
                        child: Text(_getMatrixFontSizeText(size)),
                      )).toList(),
                      icon: const Icon(Icons.arrow_drop_down, color: iconColor),
                    ),
                  ),
                  ListTile(
                    contentPadding: const EdgeInsets.only(left: 32, right: 16),
                    leading: const Icon(Icons.format_bold, color: iconColor),
                    title: const Text('Font Weight', style: titleStyle),
                    subtitle: Text('Set a global font weight for all characters.', style: subtitleStyle),
                    trailing: PopupMenuButton<MatrixFontWeight>(
                      onSelected: settings.setMatrixFontWeight,
                      itemBuilder: (ctx) => MatrixFontWeight.values.map((weight) => PopupMenuItem(
                        value: weight,
                        child: Text(_getMatrixFontWeightText(weight)),
                      )).toList(),
                      icon: const Icon(Icons.arrow_drop_down, color: iconColor),
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: const EdgeInsets.only(left: 32, right: 16),
                    title: const Text('Ripple Effects', style: titleStyle),
                    subtitle: Text('Show ripple animations when tapping columns.', style: subtitleStyle),
                    value: settings.matrixRippleEffects,
                    onChanged: settings.setMatrixRippleEffects,
                    secondary: const Icon(Icons.radio_button_unchecked, color: iconColor),
                    activeColor: Colors.yellow,
                  ),
                  SwitchListTile(
                    contentPadding: const EdgeInsets.only(left: 32, right: 16),
                    title: const Text('Chaotic Leading Characters', style: titleStyle),
                    subtitle: Text('Randomize the leading character on every step.', style: subtitleStyle),
                    value: settings.matrixChaoticLeading,
                    onChanged: settings.setMatrixChaoticLeading,
                    secondary: const Icon(Icons.flash_on, color: iconColor),
                    activeColor: Colors.yellow,
                  ),
                  ListTile(
                    contentPadding: const EdgeInsets.only(left: 32, right: 16),
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
                    contentPadding: const EdgeInsets.only(left: 32, right: 16),
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
                    contentPadding: const EdgeInsets.only(left: 32, right: 16),
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
                    contentPadding: const EdgeInsets.only(left: 32, right: 16),
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
                    contentPadding: const EdgeInsets.only(left: 32, right: 16),
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
                    contentPadding: const EdgeInsets.only(left: 32, right: 16),
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
                    contentPadding: const EdgeInsets.only(left: 32, right: 16),
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
                ],
              ),
              // --- ABOUT LIST TILE HAS BEEN REMOVED FROM HERE ---
            ],
          );
        },
      ),
    );
  }
}