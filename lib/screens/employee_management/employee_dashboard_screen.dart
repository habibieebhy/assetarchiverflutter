import 'package:flutter/material.dart';
import 'package:assetarchiverflutter/widgets/reusableglasscard.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:assetarchiverflutter/models/employee_model.dart';
import 'package:assetarchiverflutter/api/api_service.dart';
import 'package:assetarchiverflutter/models/pjp_model.dart';

class EmployeeDashboardScreen extends StatefulWidget {
  final Employee employee;

  const EmployeeDashboardScreen({
    super.key,
    required this.employee,
  });

  @override
  State<EmployeeDashboardScreen> createState() => _EmployeeDashboardScreenState();
}

class _EmployeeDashboardScreenState extends State<EmployeeDashboardScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<Pjp>> _pjpFuture;
  bool _isCheckingIn = false;
  bool _isCheckingOut = false;

  String _greeting = 'Good Morning';

  @override
  void initState() {
    super.initState();
    _setGreeting();
    _pjpFuture = _apiService.fetchPjpsForUser(
      int.parse(widget.employee.id),
      status: 'pending',
    );
  }

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

  Future<void> _handleCheckIn() async {
    // --- THE FIX: Store the messenger before the async gap ---
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    setState(() => _isCheckingIn = true);
    try {
      final checkInData = {
        'userId': int.parse(widget.employee.id),
        'attendanceDate': DateTime.now().toIso8601String(),
        'locationName': 'Guwahati, Assam',
        'inTimeLatitude': 26.1445,
        'inTimeLongitude': 91.7362,
      };

      // This 'await' is the async gap.
      await _apiService.checkIn(checkInData);

      // --- THE FIX: Use the stored variable after the gap ---
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Checked in successfully!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Check-in failed: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isCheckingIn = false);
    }
  }

  Future<void> _handleCheckOut() async {
    // --- THE FIX: Store the messenger before the async gap ---
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    setState(() => _isCheckingOut = true);
    try {
      final checkOutData = {
        'userId': int.parse(widget.employee.id),
        'attendanceDate': DateTime.now().toIso8601String(),
      };
      
      // This 'await' is the async gap.
      await _apiService.checkOut(checkOutData);

      // --- THE FIX: Use the stored variable after the gap ---
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Checked out successfully!'), backgroundColor: Colors.blue),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Check-out failed: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isCheckingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... (The rest of your build method is perfectly fine, no changes needed here)
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      body: Container(
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
              // Greeting Card
              LiquidGlassCard(
                child: Column(
                  children: [
                    Text(_greeting, style: textTheme.bodyLarge?.copyWith(color: Colors.white70)),
                    const SizedBox(height: 4),
                    Text(
                      widget.employee.displayName,
                      style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    if (widget.employee.companyName != null && widget.employee.companyName!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          widget.employee.companyName!,
                          style: textTheme.bodyMedium?.copyWith(color: Colors.white70),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Actions Card
              LiquidGlassCard(
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: _isCheckingIn ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.login, size: 18),
                        label: const Text('Check In'),
                        onPressed: _isCheckingIn || _isCheckingOut ? null : _handleCheckIn,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: _isCheckingOut ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.logout, size: 18),
                        label: const Text('Check Out'),
                        onPressed: _isCheckingIn || _isCheckingOut ? null : _handleCheckOut,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // PJP Card
              FutureBuilder<List<Pjp>>(
                future: _pjpFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const LiquidGlassCard(
                      child: Center(
                        child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator(color: Colors.white)),
                      ),
                    );
                  }
                  
                  if (snapshot.hasError) {
                    return LiquidGlassCard(
                      child: Center(child: Text('Error fetching PJPs: ${snapshot.error}', style: const TextStyle(color: Colors.yellowAccent))),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return LiquidGlassCard(
                       child: Center(child: Text('No active PJPs found.', style: TextStyle(color: Colors.white70))),
                    );
                  }

                  final pjps = snapshot.data!;

                  return LiquidGlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Active & Upcomin' PJPs (${pjps.length})",
                          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 16),
                        ...pjps.map((pjp) => ListTile(
                              leading: const Icon(Icons.route, color: Colors.white70),
                              title: Text('Plan for: ${pjp.planDate.toLocal().toString().split(' ')[0]}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              subtitle: Text('Status: ${pjp.status}', style: const TextStyle(color: Colors.white70)),
                            )),
                      ],
                    ),
                  );
                },
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