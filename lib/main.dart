// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Import Riverpod
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/group_list_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Wrap the entire app in ProviderScope
  runApp(
    const ProviderScope( // <-- ADDED ProviderScope HERE
      child: FairFlipApp(),
    ),
  );
}

class FairFlipApp extends StatelessWidget {
  const FairFlipApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Define base color scheme
    final colorScheme = ColorScheme.fromSeed(
        seedColor: Colors.greenAccent,
        // Optional: Override specific colors
        // background: Colors.grey[100], // Example background
    );

    // Define base text theme using Google Fonts
    final baseTextTheme = GoogleFonts.latoTextTheme(Theme.of(context).textTheme);

    return MaterialApp(
      title: 'FairFlip',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme, // Use the defined color scheme
        // Apply Lato font to the entire app text theme
        textTheme: baseTextTheme.copyWith(
          // Optional: Customize specific text styles further
           titleLarge: baseTextTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
           titleMedium: baseTextTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        // Apply background color globally
        scaffoldBackgroundColor: Colors.grey[50], // Slightly off-white background

        appBarTheme: AppBarTheme(
          // Make AppBar blend with background, more modern look
          backgroundColor: Colors.grey[50], // Match scaffold background
          elevation: 0, // No shadow for flat design
          foregroundColor: colorScheme.onSurface, // Text/icon color based on theme
          titleTextStyle: baseTextTheme.titleLarge?.copyWith(color: colorScheme.onSurface),
        ),
        // Keep card theme simple as we use Container in list item now
        cardTheme: CardTheme(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
          // Ensure cards don't have forced white background if theme changes
          color: colorScheme.surface,
        ),
        bottomAppBarTheme: BottomAppBarTheme(
             color: colorScheme.surface, // Use theme surface color
             elevation: 2,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
           backgroundColor: colorScheme.primary,
           foregroundColor: colorScheme.onPrimary,
        ),
         // Optional: Style ListTiles globally if needed
        // listTileTheme: ListTileThemeData(...)
      ),
      home: const GroupListScreen(),
    );
  }
}