import 'dart:ui'; // Required for the blur effect
import 'package:assetarchiverflutter/models/employee_model.dart';
import 'package:assetarchiverflutter/screens/employee_management/employee_dashboard_screen.dart';
import 'package:flutter/material.dart';

class NavScreen extends StatefulWidget {
  final Employee employee;
  const NavScreen({super.key, required this.employee});

  @override
  State<NavScreen> createState() => _NavScreenState();
}

class _NavScreenState extends State<NavScreen> {
  int _selectedIndex = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      EmployeeDashboardScreen(employee: widget.employee),
      // UPDATED: Changed "Missions" to "PJP"
      const _PlaceholderScreen(title: 'PJP'),
      // ADDED: New "Journey" screen
      const _PlaceholderScreen(title: 'Journey'),
      const _PlaceholderScreen(title: 'Profile'),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // This allows the body of the pages to extend behind the navigation bar,
      // which is necessary for the blur effect to work.
      extendBody: true,
      body: _pages[_selectedIndex],
      // UPDATED: The BottomNavigationBar is now wrapped in a custom glass widget.
      bottomNavigationBar: _buildGlassmorphicNavBar(),
    );
  }

  // --- NEW: Custom Glassmorphic Navigation Bar Widget ---
  Widget _buildGlassmorphicNavBar() {
    return ClipRRect(
      // The corners are rounded only at the top.
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(24.0),
        topRight: Radius.circular(24.0),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
        child: Container(
          // A subtle border to give the glass a defined top edge.
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: Colors.white.withAlpha(51))),
          ),
          child: BottomNavigationBar(
            // The actual bar is now transparent to let the blur show through.
            backgroundColor: Colors.white.withAlpha(26),
            elevation: 0, // Remove the shadow.
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.home_filled),
                label: 'Home',
              ),
              // UPDATED: Renamed to PJP, using a more relevant icon.
              BottomNavigationBarItem(
                icon: Icon(Icons.checklist_rtl),
                label: 'PJP',
              ),
              // ADDED: New Journey tab with a map icon.
              BottomNavigationBarItem(
                icon: Icon(Icons.map_outlined),
                label: 'Journey',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            selectedItemColor: Colors.white, // Brighter color for selected item
            unselectedItemColor: Colors.white70, // Softer color for unselected items
            type: BottomNavigationBarType.fixed,
            showUnselectedLabels: true, // Ensure all labels are visible
          ),
        ),
      ),
    );
  }
}

/// A simple placeholder widget used for the new tabs.
class _PlaceholderScreen extends StatelessWidget {
  final String title;
  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Text(
          'This is the $title page.',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }
}

