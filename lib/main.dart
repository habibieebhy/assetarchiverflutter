// Import the login screen, which will be the first screen to use our theme.
import 'package:assetarchiverflutter/screens/auth/login_screen.dart';
// UPDATED: Import the new NavScreen which now acts as our home.
import 'package:assetarchiverflutter/screens/nav_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// ADDED: Import the Employee model to recognize its type for routing.
import 'package:assetarchiverflutter/models/employee_model.dart';


// The app's entry point.
void main() {
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

      // --- THE GLASS-READY "MATERIAL SPECIFICATION SHEET" ---
      theme: ThemeData(
        // 1. THE "GLASS": A dark theme lets the background colors shine through.
        colorScheme: ColorScheme.fromSeed(
          seedColor: modernBlue,
          brightness: Brightness.dark,
        ),

        // 2. THE "PRINTING": Roboto is the standard Android font, clean and readable.
        textTheme: GoogleFonts.robotoTextTheme(ThemeData.dark().textTheme),

        // 3. THE "VIRTUAL COMPONENTS": Semi-transparent styles for text fields.
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          // UPDATED: Replaced deprecated withOpacity with withAlpha for better precision.
          fillColor: Colors.white.withAlpha(26), // Semi-transparent white
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.0),
            borderSide: BorderSide(
              color: Colors.white.withAlpha(51), // Subtle edge highlight
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

        // 4. THE "SOLID BUTTONS": Opaque and vibrant to stand out.
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

      // --- NAVIGATION ---
      initialRoute: '/login',
      // UPDATED: The routes map is now used only for routes that don't need arguments.
      routes: {
        '/login': (context) => const LoginScreen(),
      },
      // UPDATED: onGenerateRoute handles dynamic routing for screens that require arguments.
      onGenerateRoute: (settings) {
        // Handle the '/home' route.
        if (settings.name == '/home') {
          // Extract the Employee object passed during navigation.
          final employee = settings.arguments as Employee;

          // FIXED: This now correctly returns your NavScreen widget.
          return MaterialPageRoute(
            builder: (context) {
              return NavScreen(employee: employee);
            },
          );
        }
        // If the route name is not handled, return null.
        return null;
      },
    );
  }
}

