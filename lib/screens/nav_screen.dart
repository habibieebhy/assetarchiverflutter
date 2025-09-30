import 'dart:ui';
import 'package:assetarchiverflutter/models/employee_model.dart';
import 'package:assetarchiverflutter/screens/employee_management/employee_dashboard_screen.dart';
import 'package:assetarchiverflutter/screens/employee_management/employee_profile_screen.dart';
import 'package:assetarchiverflutter/screens/employee_management/employee_salesorder_screen.dart';
import 'package:assetarchiverflutter/widgets/reusableglasscard.dart';
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
      // UPDATED: Replaced the placeholder with your actual SalesOrderScreen
      SalesOrderScreen(employee: widget.employee),
      const _PlaceholderScreen(title: 'Journey'),
      EmployeeProfileScreen(employee: widget.employee),
    ];
    _pageTitles = ['Home', 'PJP', 'Sales Order', 'Journey', 'Profile'];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: AppBar(
        title: Text(_pageTitles[_selectedIndex]),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
            child: Container(
              color: Colors.white.withAlpha(26),
            ),
          ),
        ),
      ),
      drawer: _buildGlassDrawer(),
      body: _pages[_selectedIndex],
      bottomNavigationBar: _buildGlassNavBar(),
    );
  }

  Widget _buildGlassDrawer() {
    return Drawer(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: LiquidGlassCard(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            SizedBox(
              height: 200,
              child: DrawerHeader(
                decoration: const BoxDecoration(
                  color: Colors.transparent,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
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
                    Text(
                      widget.employee.companyName ?? '',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white),
                    )
                  ],
                ),
              ),
            ),
            _buildDrawerActionItem(icon: Icons.description_outlined, text: 'CREATE DVR'),
            _buildDrawerActionItem(icon: Icons.description, text: 'CREATE TVR'),
            _buildDrawerActionItem(icon: Icons.assessment_outlined, text: 'COMPETETION FORM'),
            _buildDrawerActionItem(icon: Icons.shopping_cart, text: 'MODIFY SALES ORDER'),
            _buildDrawerActionItem(icon: Icons.task_alt, text: 'DAILY TASKS'),
            _buildDrawerActionItem(icon: Icons.person_add_alt, text: 'ADD DEALER'),
            _buildDrawerActionItem(icon: Icons.event_note, text: 'APPLY FOR LEAVE'),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerActionItem({required IconData icon, required String text}) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(text, style: const TextStyle(color: Colors.white)),
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$text tapped')),
        );
      },
    );
  }

  Widget _buildGlassNavBar() {
    return LiquidGlassCard(
      child: BottomNavigationBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.checklist_rtl), label: 'PJP'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart_outlined), label: 'Sales Order'),
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

// This placeholder is still used for some tabs
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

