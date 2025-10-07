// main.dart

import 'package:assetarchiverflutter/screens/auth/login_screen.dart';
import 'package:assetarchiverflutter/screens/nav_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:assetarchiverflutter/models/employee_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
// --- NEW: Import the Radar SDK ---
import 'package:flutter_radar/flutter_radar.dart';

Future<void> main() async {
  // Ensure Flutter is ready before doing anything else
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  // --- YOUR WAY: Initialize Radar once at app startup ---
  // This is the correct, stable way to initialize the SDK.
  final radarPublishableKey = dotenv.env['RADAR_PUBLISHABLE_KEY'];
  if (radarPublishableKey != null) {
    await Radar.initialize(radarPublishableKey);
    debugPrint("✅ Radar SDK Initialized Successfully.");
  } else {
    debugPrint("❌ ERROR: RADAR_PUBLISHABLE_KEY not found in .env file. Tracking will fail.");
  }
  // --- END FIX ---

  runApp(const MyApp());
}

// The root widget, now responsible for configuration, not UI.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // A modern, clean blue for a Facebook/Android feel
    final modernBlue = const Color.fromARGB(255, 35, 103, 251);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Modern App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: modernBlue,
          brightness: Brightness.dark,
        ),
        textTheme: GoogleFonts.robotoTextTheme(ThemeData.dark().textTheme),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withAlpha(26),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.0),
            borderSide: BorderSide(
              color: Colors.white.withAlpha(51),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.0),
            borderSide: BorderSide(
              color: Colors.white.withAlpha(51),
            ),
          ),
          prefixIconColor: Colors.white.withAlpha(179),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: modernBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
            textStyle: GoogleFonts.roboto(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        useMaterial3: true,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/home') {
          final employee = settings.arguments as Employee;
          return MaterialPageRoute(
            builder: (context) {
              return NavScreen(employee: employee);
            },
          );
        }
        return null;
      },
    );
  }
}