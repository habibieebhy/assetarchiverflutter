// Import the material library, which contains the widgets for Material Design.
import 'package:flutter/material.dart';

// The main function is the entry point for all Flutter apps.
void main() {
  runApp(const MyApp());
}

// MyApp is the root widget of your application.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MaterialApp is the main container for a Material Design app.
    return MaterialApp(
      // Scaffold provides the basic structure of a visual interface.
      home: Scaffold(
        // AppBar is the toolbar at the top of the screen.
        appBar: AppBar(
          title: const Text('Hello Flutter!'),
          backgroundColor: Colors.blueAccent,
        ),
        // The body of the app. We use Center to position its child in the middle.
        body: const Center(
          child: Text(
            'Hello, World! WOW!!',
            style: TextStyle(fontSize: 28),
          ),
        ),
      ),
      // This removes the little "Debug" banner in the corner.
      debugShowCheckedModeBanner: false,
    );
  }
}
