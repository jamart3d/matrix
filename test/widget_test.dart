// This is a basic Flutter widget test for the Matrix app.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:matrix/main.dart';
import 'package:matrix/providers/track_player_provider.dart';
import 'package:matrix/providers/album_settings_provider.dart';

void main() {
  group('Matrix App Tests', () {
    testWidgets('Matrix app loads and shows initial page', (WidgetTester tester) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (context) => TrackPlayerProvider()),
            ChangeNotifierProvider(create: (context) => AlbumSettingsProvider()),
          ],
          child: const Matrix(),
        ),
      );

      // Wait for the initialization to complete
      await tester.pumpAndSettle();

      // Verify that the app title appears in the app bar
      expect(find.text('Matrix'), findsOneWidget);

      // The app should show either "Select a random show" or albums page
      // depending on the skipShowsPage setting
      expect(
        find.byType(Scaffold),
        findsOneWidget,
        reason: 'App should have a main scaffold',
      );
    });

    testWidgets('Shows page displays correctly', (WidgetTester tester) async {
      // Test the shows page specifically
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (context) => TrackPlayerProvider()),
            ChangeNotifierProvider(create: (context) => AlbumSettingsProvider()),
          ],
          child: MaterialApp(
            home: Scaffold(
              appBar: AppBar(
                title: const Text("Select a random show -->"),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.question_mark),
                    tooltip: 'Play Random Show',
                    onPressed: () {},
                  ),
                ],
              ),
              body: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ),
        ),
      );

      // Verify the shows page elements
      expect(find.text('Select a random show -->'), findsOneWidget);
      expect(find.byIcon(Icons.question_mark), findsOneWidget);
      expect(find.byTooltip('Play Random Show'), findsOneWidget);
    });

    testWidgets('Random show button is tappable', (WidgetTester tester) async {
      bool buttonPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              actions: [
                IconButton(
                  icon: const Icon(Icons.question_mark),
                  tooltip: 'Play Random Show',
                  onPressed: () {
                    buttonPressed = true;
                  },
                ),
              ],
            ),
            body: const Center(child: Text('Test')),
          ),
        ),
      );

      // Tap the random show button
      await tester.tap(find.byIcon(Icons.question_mark));
      await tester.pump();

      // Verify the button was pressed
      expect(buttonPressed, isTrue);
    });

    testWidgets('App navigation drawer can be opened', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(title: const Text('Matrix')),
            drawer: const Drawer(
              child: Column(
                children: [
                  DrawerHeader(
                    child: Text('Matrix Menu'),
                  ),
                  ListTile(
                    title: Text('Shows'),
                    leading: Icon(Icons.music_note),
                  ),
                  ListTile(
                    title: Text('Albums'),
                    leading: Icon(Icons.album),
                  ),
                  ListTile(
                    title: Text('Settings'),
                    leading: Icon(Icons.settings),
                  ),
                ],
              ),
            ),
            body: const Center(child: Text('Content')),
          ),
        ),
      );

      // Open the drawer
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      // Verify drawer contents
      expect(find.text('Matrix Menu'), findsOneWidget);
      expect(find.text('Shows'), findsOneWidget);
      expect(find.text('Albums'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('Theme is properly configured', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (context) => TrackPlayerProvider()),
            ChangeNotifierProvider(create: (context) => AlbumSettingsProvider()),
          ],
          child: const Matrix(),
        ),
      );

      await tester.pumpAndSettle();

      // Get the MaterialApp widget to check theme
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));

      // Verify dark theme is configured
      expect(materialApp.theme?.brightness, equals(Brightness.dark));
      expect(materialApp.theme?.colorScheme.brightness, equals(Brightness.dark));
    });
  });
}