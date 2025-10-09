// lib/main.dart (Updated)

import 'package:assetarchiverflutter/api/auth_service.dart'; // IMPORT THIS
import 'package:assetarchiverflutter/screens/auth/login_screen.dart';
import 'package:assetarchiverflutter/screens/nav_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:assetarchiverflutter/models/employee_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_radar/flutter_radar.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  final radarPublishableKey = dotenv.env['RADAR_API_KEY'];
  if (radarPublishableKey != null) {
    await Radar.initialize(radarPublishableKey);
    debugPrint("✅ Radar SDK Initialized Successfully.");
  } else {
    debugPrint("❌ ERROR: RADAR_PUBLISHABLE_KEY not found in .env file. Tracking will fail.");
  }
  
  // --- ADDED: Check for a logged-in user before running the app ---
  final Employee? loggedInEmployee = await AuthService().tryAutoLogin();

  runApp(MyApp(loggedInEmployee: loggedInEmployee)); // Pass the result to MyApp
}

class MyApp extends StatelessWidget {
  // --- ADDED: Accept the loggedInEmployee object ---
  final Employee? loggedInEmployee;
  const MyApp({super.key, this.loggedInEmployee});

  @override
  Widget build(BuildContext context) {
    final modernBlue = const Color.fromARGB(255, 35, 103, 251);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Modern App',
      theme: ThemeData(
        // Your theme data remains the same...
        colorScheme: ColorScheme.fromSeed(seedColor: modernBlue, brightness: Brightness.dark,),
        textTheme: GoogleFonts.robotoTextTheme(ThemeData.dark().textTheme),
        inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: Colors.white.withAlpha(26), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16.0), borderSide: BorderSide(color: Colors.white.withAlpha(51),),), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16.0), borderSide: BorderSide(color: Colors.white.withAlpha(51),),), prefixIconColor: Colors.white.withAlpha(179),),
        elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(backgroundColor: modernBlue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0),), textStyle: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.bold,),),),
        useMaterial3: true,
      ),
      // --- MODIFIED: The initial route is now determined by the login status ---
      initialRoute: loggedInEmployee != null ? '/home' : '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/home') {
          // This now handles both cases: starting the app logged in,
          // or navigating after a successful manual login.
          final employee = loggedInEmployee ?? settings.arguments as Employee;
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