import 'package:assetarchiverflutter/models/employee_model.dart';
import 'package:assetarchiverflutter/widgets/reusableglasscard.dart';
import 'package:flutter/material.dart';

class EmployeeProfileScreen extends StatelessWidget {
  final Employee employee;

  const EmployeeProfileScreen({super.key, required this.employee});

  // Helper to get user initials for the avatar
  String getInitials() {
    String firstNameInitial = employee.firstName?.isNotEmpty == true ? employee.firstName![0] : '';
    String lastNameInitial = employee.lastName?.isNotEmpty == true ? employee.lastName![0] : '';
    return (firstNameInitial + lastNameInitial).toUpperCase();
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
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // --- Profile Header ---
            Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: theme.colorScheme.primary,
                  child: Text(
                    getInitials(),
                    style: textTheme.headlineLarge?.copyWith(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  employee.displayName,
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  employee.email ?? 'No email available',
                  style: textTheme.bodyLarge?.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 12),
                Chip(
                  avatar: Icon(Icons.work_outline, color: Colors.white70, size: 18),
                  label: Text(
                    'Junior Executive', // This would come from employee.role
                    style: textTheme.bodyMedium?.copyWith(color: Colors.white),
                  ),
                  backgroundColor: Colors.white.withOpacity(0.1),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // --- Stats Grid ---
            Row(
              children: [
                Expanded(child: _StatCard(icon: Icons.description_outlined, label: 'Reports', value: '0')),
                const SizedBox(width: 16),
                Expanded(child: _StatCard(icon: Icons.store_mall_directory_outlined, label: 'Dealers', value: '2')),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _StatCard(icon: Icons.checklist_rtl_outlined, label: 'PJPs', value: '1')),
                const SizedBox(width: 16),
                Expanded(child: _StatCard(icon: Icons.task_alt_outlined, label: 'Tasks Done', value: '0')),
              ],
            ),
            const SizedBox(height: 24),

            // --- Performance Section ---
            const LiquidGlassCard(
              child: Row(
                children: [
                  Icon(Icons.military_tech_outlined, color: Colors.amber, size: 28),
                  SizedBox(width: 16),
                  Text(
                    'PERFORMANCE',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // --- Action Buttons ---
            Row(
              children: [
                Expanded(child: _ActionCard(icon: Icons.event_note_outlined, label: 'Apply for Leave')),
                const SizedBox(width: 16),
                Expanded(child: _ActionCard(icon: Icons.map_outlined, label: 'Brand Mapping')),
              ],
            ),
            const SizedBox(height: 32),

            // --- Log Out Button ---
            _LogoutButton(),
          ],
        ),
      ),
    );
  }
}

// --- Helper Widgets for a Cleaner Build Method ---

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

  const _ActionCard({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return LiquidGlassCard(
      onPressed: () {},
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 32),
          const SizedBox(height: 12),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white),
          ),
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
        // Clear all navigation history and go back to the login screen
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red.withOpacity(0.8),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(vertical: 18),
      ),
    );
  }
}
