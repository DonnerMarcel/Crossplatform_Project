// lib/main.dart
import 'package:flutter/material.dart';
import 'screens/group_list_screen.dart'; // Import the new location for GroupListScreen

void main() {
  runApp(const FairFlipApp());
}

class FairFlipApp extends StatelessWidget {
  const FairFlipApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FairFlip', // App title remains
      theme: ThemeData( // Theme definition remains the same
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        scaffoldBackgroundColor: Colors.grey[100],
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.grey[100],
          elevation: 0,
          foregroundColor: Colors.black87,
        ),
        cardTheme: CardTheme(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          // Consistent margin for cards unless overridden
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
        ),
        bottomAppBarTheme: const BottomAppBarTheme(
             color: Colors.white, // Example color
             elevation: 2,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
           // Use colorScheme for consistency
           backgroundColor: ColorScheme.fromSeed(seedColor: Colors.blueAccent).primary,
           foregroundColor: Colors.white,
        ),
        // Add text theme if you want more control over text styles globally
        // textTheme: TextTheme(...)
      ),
      // Set the initial screen to GroupListScreen from its new file
      home: const GroupListScreen(),
    );
  }
}