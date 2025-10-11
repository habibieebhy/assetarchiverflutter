// lib/screens/employee_management/employee_profile_screen.dart

import 'dart:async';
import 'package:assetarchiverflutter/models/employee_model.dart';
import 'package:assetarchiverflutter/widgets/reusableglasscard.dart';
import 'package:flutter/material.dart';
import 'package:assetarchiverflutter/api/api_service.dart';
import 'package:assetarchiverflutter/models/dealer_model.dart';
import 'package:assetarchiverflutter/api/auth_service.dart';
import 'package:fl_chart/fl_chart.dart'; // --- NEW: Import for charts ---
import 'package:intl/intl.dart';       // --- NEW: Import for date formatting ---

// --- UPDATED: Helper class now includes monthly and all-time stats ---
class _ProfileStats {
  // Monthly stats
  final int monthlyReportCount;
  final int monthlyPjpCount;
  // All-time stats
  final int allTimeDealerCount;
  final int allTimeCompletedTasksCount;

  _ProfileStats({
    required this.monthlyReportCount,
    required this.monthlyPjpCount,
    required this.allTimeDealerCount,
    required this.allTimeCompletedTasksCount,
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

  // --- UPDATED: This function is now used for both initial load and pull-to-refresh ---
  Future<void> _refreshStats() async {
    if (mounted) {
      setState(() {
        _statsFuture = _fetchProfileStats();
      });
    }
    // Return a future to satisfy the RefreshIndicator
    await _statsFuture;
  }

  String getInitials() {
    String firstNameInitial = widget.employee.firstName?.isNotEmpty == true ? widget.employee.firstName![0] : '';
    String lastNameInitial = widget.employee.lastName?.isNotEmpty == true ? widget.employee.lastName![0] : '';
    return (firstNameInitial + lastNameInitial).toUpperCase();
  }

  String _capitalize(String? s) {
    if (s == null || s.isEmpty) return '';
    return s[0].toUpperCase() + s.substring(1);
  }

  // --- UPDATED: This function now fetches stats specifically for the current month ---
  Future<_ProfileStats> _fetchProfileStats() async {
    final employeeId = int.parse(widget.employee.id);

    // Calculate the start and end of the current month
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
    final formatter = DateFormat('yyyy-MM-dd');
    final startDate = formatter.format(firstDayOfMonth);
    final endDate = formatter.format(lastDayOfMonth);

    // Fetch data in parallel
    final results = await Future.wait([
      // Fetch reports for the current month
      _apiService.fetchDvrsForUser(employeeId, startDate: startDate, endDate: endDate),
      _apiService.fetchTvrsForUser(employeeId, startDate: startDate, endDate: endDate),
      // Fetch PJPs for the current month
      _apiService.fetchPjpsForUser(employeeId, startDate: startDate, endDate: endDate),
      // These stats remain all-time
      _apiService.fetchDealers(userId: employeeId),
      _apiService.fetchDailyTasksForUser(employeeId, status: 'Completed'),
    ]);

    // Process results
    final dvrCount = (results[0] as List).length;
    final tvrCount = (results[1] as List).length;
    final monthlyPjpCount = (results[2] as List).length;
    final allTimeDealerCount = (results[3] as List).length;
    final allTimeCompletedTasksCount = (results[4] as List).length;

    return _ProfileStats(
      monthlyReportCount: dvrCount + tvrCount,
      monthlyPjpCount: monthlyPjpCount,
      allTimeDealerCount: allTimeDealerCount,
      allTimeCompletedTasksCount: allTimeCompletedTasksCount,
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
              onDealersUpdated: _refreshStats, // Connects to the new refresh logic
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
            if (snapshot.connectionState == ConnectionState.waiting && snapshot.data == null) {
              return const Center(child: CircularProgressIndicator(color: Colors.white));
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.yellow)));
            }
            final stats = snapshot.data ?? _ProfileStats(monthlyReportCount: 0, monthlyPjpCount: 0, allTimeDealerCount: 0, allTimeCompletedTasksCount: 0);

            // --- UPDATED: Wrapped ListView in RefreshIndicator for pull-to-refresh ---
            return RefreshIndicator(
              onRefresh: _refreshStats,
              color: Colors.white,
              backgroundColor: theme.primaryColor,
              child: ListView(
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
                        label: Text(_capitalize(widget.employee.role ?? 'Employee'), style: textTheme.bodyMedium?.copyWith(color: Colors.white)),
                        backgroundColor: Colors.white.withAlpha(26),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(child: _StatCard(icon: Icons.description_outlined, label: 'Reports (This Month)', value: stats.monthlyReportCount.toString())),
                      const SizedBox(width: 16),
                      Expanded(child: _StatCard(icon: Icons.store_mall_directory_outlined, label: 'Manage Dealers', value: stats.allTimeDealerCount.toString(), onTap: _showManageDealersSheet)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _StatCard(icon: Icons.checklist_rtl_outlined, label: 'PJPs (This Month)', value: stats.monthlyPjpCount.toString())),
                      const SizedBox(width: 16),
                      Expanded(child: _StatCard(icon: Icons.task_alt_outlined, label: 'Tasks Done', value: stats.allTimeCompletedTasksCount.toString())),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // --- NEW: Replaced the static card with the dynamic performance chart ---
                  _PerformanceChart(
                    reportCount: stats.monthlyReportCount.toDouble(),
                    pjpCount: stats.monthlyPjpCount.toDouble(),
                  ),
                  
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
              ),
            );
          },
        ),
      ),
    );
  }
}

// --- NEW WIDGET: The interactive performance chart ---
class _PerformanceChart extends StatelessWidget {
  final double reportCount;
  final double pjpCount;

  const _PerformanceChart({required this.reportCount, required this.pjpCount});

  @override
  Widget build(BuildContext context) {
    return LiquidGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.military_tech_outlined, color: Colors.amber, size: 28),
              const SizedBox(width: 16),
              Text(
                'MONTHLY PERFORMANCE (${DateFormat('MMMM').format(DateTime.now())})',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 150,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: (reportCount > pjpCount ? reportCount : pjpCount) * 1.2 + 5, // Dynamic max Y
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => Colors.blueGrey,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      String label = rod.toY.round().toString();
                      return BarTooltipItem(
                        label,
                        const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      );
                    },
                  ),
                  handleBuiltInTouches: true,
                ),
                titlesData: const FlTitlesData(
                  show: true,
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: _getBottomTitles,
                      reservedSize: 38,
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
                barGroups: [
                  _makeBarGroup(0, reportCount, Colors.blueAccent),
                  _makeBarGroup(1, pjpCount, Colors.amber),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  BarChartGroupData _makeBarGroup(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 22,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(6),
            topRight: Radius.circular(6),
          ),
        ),
      ],
    );
  }

  static Widget _getBottomTitles(double value, TitleMeta meta) {
    const style = TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 14);
    Widget text;
    switch (value.toInt()) {
      case 0:
        text = const Text('Reports', style: style);
        break;
      case 1:
        text = const Text('PJPs', style: style);
        break;
      default:
        text = const Text('', style: style);
        break;
    }
    return SideTitleWidget(axisSide: meta.axisSide, child: text);
  }
}

// --- All other widgets below remain unchanged ---

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
                  Navigator.of(context).pop();
                  _editDealer(dealer);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.redAccent),
                title: const Text('Delete Dealer', style: TextStyle(color: Colors.redAccent)),
                onTap: () {
                  Navigator.of(context).pop();
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
                  return ListTile(
                    title: Text(dealer.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Text(dealer.address, style: const TextStyle(color: Colors.white70)),
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
      onPressed: () async {
        await AuthService().logout();
        if (context.mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
        }
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