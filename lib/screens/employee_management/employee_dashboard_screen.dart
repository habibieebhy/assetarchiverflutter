import 'package:flutter/material.dart';
// Assuming your glass card widget is here. Adjust the path if necessary.
import 'package:assetarchiverflutter/widgets/reusableglasscard.dart';
import 'package:flutter_animate/flutter_animate.dart';
// Import the Employee model to use its data structure.
import 'package:assetarchiverflutter/models/employee_model.dart';

//A dashboard screen that displays information tailored to the logged-in employee.
class EmployeeDashboardScreen extends StatefulWidget {
  // The Employee object containing the data for the logged-in user.
  // This is required to build the screen.
  final Employee employee;

  const EmployeeDashboardScreen({
    super.key,
    required this.employee,
  });

  @override
  State<EmployeeDashboardScreen> createState() => _EmployeeDashboardScreenState();
}

class _EmployeeDashboardScreenState extends State<EmployeeDashboardScreen> {
  // State to manage loading for dashboard sections like missions or stats.
  bool _isLoading = true;
  String _greeting = 'Good Morning';

  @override
  void initState() {
    super.initState();
    _setGreeting();
    // Simulate fetching dashboard-specific data after the screen loads.
    _fetchDashboardData();
  }

  // Sets a time-appropriate greeting based on the current hour.
  void _setGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      _greeting = 'Good Morning';
    } else if (hour < 17) {
      _greeting = 'Good Afternoon';
    } else {
      _greeting = 'Good Evening';
    }
  }

  // Simulates fetching data from a network for the dashboard content.
  Future<void> _fetchDashboardData() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Access the global theme for consistent styling.
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      body: Container(
        // Maintain the same background gradient for a consistent app feel.
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D47A1), Color(0xFF42A5F5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // --- Card 1: Personalized Greeting ---
              LiquidGlassCard(
                child: Column(
                  children: [
                    Text(
                      _greeting,
                      style: textTheme.bodyLarge?.copyWith(color: Colors.white70),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      // TAILORED: Use the employee's name from the passed-in model.
                      // Provides a fallback to loginId or a generic term if name is null.
                      widget.employee.name ?? widget.employee.loginId ?? 'Employee',
                      style: textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // --- Card 2: Main Actions ---
              LiquidGlassCard(
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.login, size: 18),
                        label: const Text('Check In'),
                        onPressed: () {
                          // TODO: Implement Check-In logic for this employee.
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.logout, size: 18),
                        label: const Text('Check Out'),
                        onPressed: () {
                          // TODO: Implement Check-Out logic for this employee.
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // --- Card 3: Dashboard/Missions Section ---
              _isLoading
                  ? const LiquidGlassCard(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      ),
                    )
                  : LiquidGlassCard(
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Today's Missions",
                                style: textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                ),
                                child: const Icon(Icons.add, size: 18),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Center(
                            child: Text(
                              'No missions planned.',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),
                        ],
                      ),
                    ),
            ]
                .animate(interval: 100.ms)
                .fadeIn(duration: 500.ms)
                .slideY(begin: 0.3),
          ),
        ),
      ),
    );
  }
}
