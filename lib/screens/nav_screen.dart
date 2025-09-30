import 'package:assetarchiverflutter/models/employee_model.dart';
import 'package:assetarchiverflutter/screens/employee_management/employee_dashboard_screen.dart';
import 'package:assetarchiverflutter/widgets/reusableglasscard.dart'; // IMPORTED: Your custom glass card
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
  late final List<String> _pageTitles;

  @override
  void initState() {
    super.initState();
    _pages = [
      EmployeeDashboardScreen(employee: widget.employee),
      const _PlaceholderScreen(title: 'PJP'),
      const _PlaceholderScreen(title: 'Journey'),
      const _PlaceholderScreen(title: 'Profile'),
    ];
    _pageTitles = ['Home', 'PJP', 'Journey', 'Profile'];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: Text(_pageTitles[_selectedIndex]),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      // REFACTORED: Now uses the LiquidGlassCard widget
      drawer: _buildGlassDrawer(),
      body: _pages[_selectedIndex],
      // REFACTORED: Now uses the LiquidGlassCard widget
      bottomNavigationBar: _buildGlassNavBar(),
    );
  }

  // --- REFACTORED: The Side Drawer now uses your LiquidGlassCard ---
  Widget _buildGlassDrawer() {
    return Drawer(
      // The drawer's own background must be transparent
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: LiquidGlassCard(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                // A slightly different color to distinguish the header
                color: Colors.transparent,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(radius: 30, child: Icon(Icons.person, size: 30)),
                  const SizedBox(height: 10),
                  Text(
                    widget.employee.displayName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
                  ),
                  Text(
                    widget.employee.email ?? '',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
            _buildDrawerItem(icon: Icons.home_filled, text: 'Home', index: 0),
            _buildDrawerItem(icon: Icons.checklist_rtl, text: 'PJP', index: 1),
            _buildDrawerItem(icon: Icons.map_outlined, text: 'Journey', index: 2),
            _buildDrawerItem(icon: Icons.person, text: 'Profile', index: 3),
          ],
        ),
      ),
    );
  }

  // Helper method for drawer items, unchanged.
  Widget _buildDrawerItem({required IconData icon, required String text, required int index}) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(text, style: const TextStyle(color: Colors.white)),
      onTap: () {
        _onItemTapped(index);
        Navigator.pop(context); // Close the drawer
      },
    );
  }

  // --- REFACTORED: The Bottom Nav Bar now uses your LiquidGlassCard ---
  Widget _buildGlassNavBar() {
    // We wrap the BottomNavigationBar in your custom card.
    return LiquidGlassCard(
      child: BottomNavigationBar(
        // The bar's own background must be transparent to let the glass effect show.
        backgroundColor: Colors.transparent,
        elevation: 0, // Remove the shadow.
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.checklist_rtl), label: 'PJP'),
          BottomNavigationBarItem(icon: Icon(Icons.map_outlined), label: 'Journey'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),
    );
  }
}

// Placeholder screen, unchanged.
class _PlaceholderScreen extends StatelessWidget {
  final String title;
  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'This is the $title page.',
        style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: Colors.white),
      ),
    );
  }
}

