import 'dart:async';
import 'package:assetarchiverflutter/models/employee_model.dart';
import 'package:assetarchiverflutter/widgets/reusableglasscard.dart';
import 'package:flutter/material.dart';
import 'package:assetarchiverflutter/api/api_service.dart';
import 'package:assetarchiverflutter/models/dealer_model.dart';
// --- REMOVED: The slidable package is no longer needed ---

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

class EmployeeProfileScreen extends StatefulWidget {
  final Employee employee;
  const EmployeeProfileScreen({super.key, required this.employee});

  @override
  State<EmployeeProfileScreen> createState() => _EmployeeProfileScreenState();
}

class _EmployeeProfileScreenState extends State<EmployeeProfileScreen> {
  final ApiService _apiService = ApiService();
  late Future<_ProfileStats> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = _fetchProfileStats();
  }

  void refreshStats() {
    if (mounted) {
      setState(() {
        _statsFuture = _fetchProfileStats();
      });
    }
  }

  String getInitials() {
    String firstNameInitial = widget.employee.firstName?.isNotEmpty == true ? widget.employee.firstName![0] : '';
    String lastNameInitial = widget.employee.lastName?.isNotEmpty == true ? widget.employee.lastName![0] : '';
    return (firstNameInitial + lastNameInitial).toUpperCase();
  }

  Future<_ProfileStats> _fetchProfileStats() async {
    final employeeId = int.parse(widget.employee.id);

    final results = await Future.wait([
      _apiService.fetchDvrsForUser(employeeId),
      _apiService.fetchTvrsForUser(employeeId),
      _apiService.fetchDealers(userId: employeeId),
      _apiService.fetchPjpsForUser(employeeId),
      _apiService.fetchDailyTasksForUser(employeeId, status: 'Completed'),
    ]);

    final dvrCount = (results[0] as List).length;
    final tvrCount = (results[1] as List).length;
    final dealerCount = (results[2] as List).length;
    final pjpCount = (results[3] as List).length;
    final completedTasksCount = (results[4] as List).length;

    return _ProfileStats(
      reportCount: dvrCount + tvrCount,
      dealerCount: dealerCount,
      pjpCount: pjpCount,
      completedTasksCount: completedTasksCount,
    );
  }

  void _showManageDealersSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (BuildContext context, ScrollController scrollController) {
          return Container(
             decoration: const BoxDecoration(
              color: Color(0xFF020a67),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
            ),
            child: _ManageDealersContent(
              employee: widget.employee,
              scrollController: scrollController,
              onDealersUpdated: refreshStats,
            ),
          );
        },
      ),
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
        child: FutureBuilder<_ProfileStats>(
          future: _statsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Colors.white));
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.yellow)));
            }
            final stats = snapshot.data ?? _ProfileStats(reportCount: 0, dealerCount: 0, pjpCount: 0, completedTasksCount: 0);

            return ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                Column(
                  children: [
                    CircleAvatar(radius: 50, backgroundColor: theme.colorScheme.primary, child: Text(getInitials(), style: textTheme.headlineLarge?.copyWith(color: Colors.white))),
                    const SizedBox(height: 16),
                    Text(widget.employee.displayName, style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 4),
                    Text(widget.employee.email ?? 'No email', style: textTheme.bodyLarge?.copyWith(color: Colors.white70)),
                    const SizedBox(height: 12),
                    Chip(
                      avatar: const Icon(Icons.work_outline, color: Colors.white70, size: 18),
                      label: Text('Junior Executive', style: textTheme.bodyMedium?.copyWith(color: Colors.white)),
                      backgroundColor: Colors.white.withAlpha(26),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: _StatCard(icon: Icons.description_outlined, label: 'Reports', value: stats.reportCount.toString())),
                    const SizedBox(width: 16),
                    Expanded(child: _StatCard(icon: Icons.store_mall_directory_outlined, label: 'Manage Dealers', value: stats.dealerCount.toString(), onTap: _showManageDealersSheet)),
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
                const LiquidGlassCard(child: Row(children: [Icon(Icons.military_tech_outlined, color: Colors.amber, size: 28), SizedBox(width: 16), Text('PERFORMANCE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))])),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _ActionCard(icon: Icons.event_note_outlined, label: 'Apply for Leave', onPressed: () {})),
                    const SizedBox(width: 16),
                    Expanded(child: _ActionCard(icon: Icons.map_outlined, label: 'Brand Mapping', onPressed: () {})),
                  ],
                ),
                const SizedBox(height: 32),
                _LogoutButton(),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ManageDealersContent extends StatefulWidget {
  final Employee employee;
  final ScrollController scrollController;
  final VoidCallback onDealersUpdated;

  const _ManageDealersContent({required this.employee, required this.scrollController, required this.onDealersUpdated});

  @override
  State<_ManageDealersContent> createState() => _ManageDealersContentState();
}

class _ManageDealersContentState extends State<_ManageDealersContent> {
  final ApiService _apiService = ApiService();
  late Future<List<Dealer>> _dealersFuture;

  @override
  void initState() {
    super.initState();
    _refreshDealers(notifyParent: false);
  }

  void _refreshDealers({bool notifyParent = true}) {
    if (mounted) {
      setState(() {
        _dealersFuture = _apiService.fetchDealers(userId: int.parse(widget.employee.id));
      });
      if (notifyParent) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.onDealersUpdated();
        });
      }
    }
  }

  void _deleteDealer(String dealerId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text('Are you sure you want to delete this dealer? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await _apiService.deleteDealer(dealerId);
      if(!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dealer deleted'), backgroundColor: Colors.green));
      _refreshDealers(notifyParent: true);
    } catch (e) {
      if(!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete: $e'), backgroundColor: Colors.red));
    }
  }

  void _editDealer(Dealer dealer) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Editing ${dealer.name}...')));
  }

  // --- NEW: This method shows the Edit/Delete options for a dealer ---
  void _showDealerActions(Dealer dealer) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0D47A1),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
          ),
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.white70),
                title: const Text('Edit Dealer', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.of(context).pop(); // Close this actions sheet
                  _editDealer(dealer);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.redAccent),
                title: const Text('Delete Dealer', style: TextStyle(color: Colors.redAccent)),
                onTap: () {
                  Navigator.of(context).pop(); // Close this actions sheet
                  _deleteDealer(dealer.id);
                },
              ),
              ListTile(
                title: const Center(child: Text('Cancel', style: TextStyle(color: Colors.white70))),
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 20.0),
          child: Text('Manage Your Dealers', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: FutureBuilder<List<Dealer>>(
            future: _dealersFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Colors.white));
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.yellow)));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No dealers found for this user.', style: TextStyle(color: Colors.white70)));
              }
              final dealers = snapshot.data!;
              return ListView.builder(
                controller: widget.scrollController,
                itemCount: dealers.length,
                itemBuilder: (context, index) {
                  final dealer = dealers[index];
                  // --- UPDATED: Replaced Slidable with a standard ListTile ---
                  return ListTile(
                    title: Text(dealer.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Text(dealer.address, style: const TextStyle(color: Colors.white70)),
                    // --- UPDATED: Changed icon and added onTap for actions ---
                    trailing: const Icon(Icons.more_vert, color: Colors.white54),
                    onTap: () => _showDealerActions(dealer),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _StatCard({required this.icon, required this.label, required this.value, this.onTap});

  @override
  Widget build(BuildContext context) {
    return LiquidGlassCard(
      onPressed: onTap,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: Colors.white70, size: 28),
              Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 28)),
            ],
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.white70)),
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
        backgroundColor: Colors.red.withAlpha(200),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(vertical: 18),
      ),
    );
  }
}

