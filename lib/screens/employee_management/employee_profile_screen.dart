import 'package:assetarchiverflutter/models/employee_model.dart';
import 'package:assetarchiverflutter/widgets/reusableglasscard.dart';
import 'package:flutter/material.dart';

// Import the ApiService to fetch live data
import 'package:assetarchiverflutter/api/api_service.dart';

// Helper class to hold all the fetched stats in one object
class _ProfileStats {
  final int reportCount;
  final int dealerCount;
  final int pjpCount;
  final int completedTasksCount;

  _ProfileStats({
    required this.reportCount,
    required this.dealerCount,
    required this.pjpCount,
    required this.completedTasksCount,
  });
}

// Converted to a StatefulWidget to fetch data
class EmployeeProfileScreen extends StatefulWidget {
  final Employee employee;
  const EmployeeProfileScreen({super.key, required this.employee});

  @override
  State<EmployeeProfileScreen> createState() => _EmployeeProfileScreenState();
}

class _EmployeeProfileScreenState extends State<EmployeeProfileScreen> {
  // ApiService instance and a single Future for all our stats
  final ApiService _apiService = ApiService();
  late final Future<_ProfileStats> _statsFuture;

  @override
  void initState() {
    super.initState();
    // Call the method to fetch all stats at once
    _statsFuture = _fetchProfileStats();
  }

  // Helper to get user initials for the avatar
  String getInitials() {
    String firstNameInitial = widget.employee.firstName?.isNotEmpty == true ? widget.employee.firstName![0] : '';
    String lastNameInitial = widget.employee.lastName?.isNotEmpty == true ? widget.employee.lastName![0] : '';
    return (firstNameInitial + lastNameInitial).toUpperCase();
  }

  // New method to fetch all data in parallel
  Future<_ProfileStats> _fetchProfileStats() async {
    final employeeId = int.parse(widget.employee.id);

    // Use Future.wait to run all API calls at the same time
    final results = await Future.wait([
      _apiService.fetchDvrsForUser(employeeId),
      _apiService.fetchTvrsForUser(employeeId),
      _apiService.fetchDealers(userId: employeeId),
      _apiService.fetchPjpsForUser(employeeId),
      _apiService.fetchDailyTasksForUser(employeeId, status: 'Completed'),
    ]);

    // Process the results once they all complete
    final dvrCount = results[0].length;
    final tvrCount = results[1].length;
    final dealerCount = results[2].length;
    final pjpCount = results[3].length;
    final completedTasksCount = results[4].length;

    // Return a single object with all the stats
    return _ProfileStats(
      reportCount: dvrCount + tvrCount,
      dealerCount: dealerCount,
      pjpCount: pjpCount,
      completedTasksCount: completedTasksCount,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D47A1), Color.fromARGB(255, 2, 10, 103)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        // Wrap the main content in a FutureBuilder
        child: FutureBuilder<_ProfileStats>(
          future: _statsFuture,
          builder: (context, snapshot) {
            // While loading, show a full-screen spinner
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Colors.white));
            }
            // If an error occurs, show an error message
            if (snapshot.hasError) {
              return Center(child: Text('Error loading profile stats: ${snapshot.error}', style: const TextStyle(color: Colors.yellow)));
            }
            // If data is loaded successfully, get the stats object
            final stats = snapshot.data ?? _ProfileStats(reportCount: 0, dealerCount: 0, pjpCount: 0, completedTasksCount: 0);

            // Build the main UI with the fetched stats
            return ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // Profile Header
                Column(
                  children: [
                    CircleAvatar(radius: 50, backgroundColor: theme.colorScheme.primary, child: Text(getInitials(), style: textTheme.headlineLarge?.copyWith(color: Colors.white))),
                    const SizedBox(height: 16),
                    Text(widget.employee.displayName, style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 4),
                    Text(widget.employee.email ?? 'No email available', style: textTheme.bodyLarge?.copyWith(color: Colors.white70)),
                    const SizedBox(height: 12),
                    Chip(
                      avatar: const Icon(Icons.work_outline, color: Colors.white70, size: 18),
                      label: Text('Junior Executive', style: textTheme.bodyMedium?.copyWith(color: Colors.white)),
                      backgroundColor: Colors.white.withAlpha((255 * 0.1).round()),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Stats Grid now uses live data
                Row(
                  children: [
                    Expanded(child: _StatCard(icon: Icons.description_outlined, label: 'Reports', value: stats.reportCount.toString())),
                    const SizedBox(width: 16),
                    Expanded(child: _StatCard(icon: Icons.store_mall_directory_outlined, label: 'Dealers', value: stats.dealerCount.toString())),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _StatCard(icon: Icons.checklist_rtl_outlined, label: 'PJPs', value: stats.pjpCount.toString())),
                    const SizedBox(width: 16),
                    Expanded(child: _StatCard(icon: Icons.task_alt_outlined, label: 'Tasks Done', value: stats.completedTasksCount.toString())),
                  ],
                ),
                const SizedBox(height: 24),

                // Performance Section
                const LiquidGlassCard(child: Row(children: [Icon(Icons.military_tech_outlined, color: Colors.amber, size: 28), SizedBox(width: 16), Text('PERFORMANCE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))])),
                const SizedBox(height: 16),

                // Action Buttons are now functional
                Row(
                  children: [
                    Expanded(child: _ActionCard(icon: Icons.event_note_outlined, label: 'Apply for Leave', onPressed: () {/* TODO: Navigator.pushNamed(context, '/apply-leave'); */})),
                    const SizedBox(width: 16),
                    Expanded(child: _ActionCard(icon: Icons.map_outlined, label: 'Brand Mapping', onPressed: () {/* TODO: Navigator.pushNamed(context, '/brand-mapping'); */})),
                  ],
                ),
                const SizedBox(height: 32),

                // Log Out Button
                _LogoutButton(),
              ],
            );
          },
        ),
      ),
    );
  }
}

// --- Helper Widgets ---

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatCard({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return LiquidGlassCard(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: Colors.white70, size: 28),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 28,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _ActionCard({required this.icon, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return LiquidGlassCard(
      onPressed: onPressed,
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 32),
          const SizedBox(height: 12),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.logout),
      label: const Text('LOG OUT'),
      onPressed: () {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red.withAlpha((255 * 0.8).round()),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(vertical: 18),
      ),
    );
  }
}