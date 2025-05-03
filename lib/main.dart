import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    const ProviderScope(
      child: FairFlipApp(),
    ),
  );
}

class FairFlipApp extends StatelessWidget {
  const FairFlipApp({super.key});

  @override
  Widget build(BuildContext context) {

    final colorScheme = ColorScheme.fromSeed(
        seedColor: Colors.greenAccent,
    );

    final baseTextTheme = GoogleFonts.latoTextTheme(Theme.of(context).textTheme);

    return MaterialApp(
      title: 'FairFlip',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        textTheme: baseTextTheme.copyWith(
           titleLarge: baseTextTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
           titleMedium: baseTextTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        scaffoldBackgroundColor: Colors.grey[50],

        appBarTheme: AppBarTheme(
          backgroundColor: Colors.grey[50],
          elevation: 0,
          foregroundColor: colorScheme.onSurface,
          titleTextStyle: baseTextTheme.titleLarge?.copyWith(color: colorScheme.onSurface),
        ),
        cardTheme: CardTheme(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
          color: colorScheme.surface,
        ),
        bottomAppBarTheme: BottomAppBarTheme(
             color: colorScheme.surface,
             elevation: 2,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
           backgroundColor: colorScheme.primary,
           foregroundColor: colorScheme.onPrimary,
        ),
      ),
      home: const GroupListScreen(),
    );
  }
}