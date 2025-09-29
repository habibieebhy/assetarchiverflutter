import 'package:assetarchiverflutter/models/employee_model.dart';
import 'package:assetarchiverflutter/screens/employee_management/employee_dashboard_screen.dart';
import 'package:flutter/material.dart';

/// This widget is the main "shell" of your app after a user logs in.
/// It holds the BottomNavigationBar and manages which page is currently visible.
class NavScreen extends StatefulWidget {
  final Employee employee;

  const NavScreen({super.key, required this.employee});

  @override
  State<NavScreen> createState() => _NavScreenState();
}

class _NavScreenState extends State<NavScreen> {
  // This integer tracks the currently selected tab. 0 = Home.
  int _selectedIndex = 0;

  // This is the list of pages that the navigation bar will switch between.
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    // We create the list of pages here.
    // The EmployeeDashboardScreen is the first page (index 0).
    _pages = [
      EmployeeDashboardScreen(employee: widget.employee),
      const _PlaceholderScreen(title: 'Missions'), // A temporary placeholder page
      const _PlaceholderScreen(title: 'Profile'),  // A temporary placeholder page
    ];
  }

  // This function is called when a navigation bar item is tapped.
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The body of the screen is set to the currently selected page.
      // When this screen first loads, it will show the EmployeeDashboardScreen.
      body: _pages[_selectedIndex],
      
      // Here is the BottomNavigationBar widget.
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_filled),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Missions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        // Style the selected item to match your app's theme.
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

/// A simple placeholder widget used for the Missions and Profile tabs.
/// You can replace these with your real screen widgets later.
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
