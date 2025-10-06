import 'dart:io';
import 'package:flutter/material.dart';
import 'package:assetarchiverflutter/widgets/reusableglasscard.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:assetarchiverflutter/models/employee_model.dart';
import 'package:assetarchiverflutter/api/api_service.dart';
import 'package:assetarchiverflutter/models/pjp_model.dart';
import 'package:image_picker/image_picker.dart';
// --- NEW: Imported Geolocator for live location data ---
import 'package:geolocator/geolocator.dart';

class EmployeeDashboardScreen extends StatefulWidget {
  final Employee employee;

  const EmployeeDashboardScreen({
    super.key,
    required this.employee,
  });

  @override
  // --- FIXED: Changed to public state type ---
  State<EmployeeDashboardScreen> createState() => EmployeeDashboardScreenState();
}

// --- FIXED: Renamed the class to be public (removed the '_') ---
class EmployeeDashboardScreenState extends State<EmployeeDashboardScreen> with WidgetsBindingObserver {
  final ApiService _apiService = ApiService();
  late Future<List<Pjp>> _pjpFuture;
  bool _isCheckingIn = false;
  bool _isCheckingOut = false;

  String _greeting = 'Good Morning';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _setGreeting();
    refreshPjps();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      refreshPjps();
    }
  }
  
  // --- This method is now public so NavScreen can call it ---
  void refreshPjps() {
    if (mounted) {
      setState(() {
        _pjpFuture = _apiService.fetchPjpsForUser(
          int.parse(widget.employee.id),
          status: 'pending',
        );
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
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
  
  Future<File?> _captureImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 50,
    );
    if (image != null) {
      return File(image.path);
    }
    return null;
  }
  
  // --- NEW: Helper to get current device position ---
  Future<Position?> _getCurrentPosition() async {
     try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!mounted) return null;
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location services are disabled.')));
        return null;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (!mounted) return null;
        if (permission == LocationPermission.denied) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permissions are denied')));
           return null;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return null;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permissions are permanently denied, we cannot request permissions.')));
        return null;
      }
      return await Geolocator.getCurrentPosition();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to get location: $e')));
      }
      return null;
    }
  }


  // --- UPDATED: Now uses image capture and live location data ---
  Future<void> _handleCheckIn() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    setState(() => _isCheckingIn = true);

    try {
      final position = await _getCurrentPosition();
      if (position == null) {
        if(mounted) setState(() => _isCheckingIn = false);
        return;
      }

      final imageFile = await _captureImage();
      if (imageFile == null) {
        if(mounted) setState(() => _isCheckingIn = false);
        return;
      }

      scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Uploading image...')));
      final imageUrl = await _apiService.uploadImageToR2(imageFile);

      final checkInData = {
        'userId': int.parse(widget.employee.id),
        'attendanceDate': DateTime.now().toIso8601String(),
        'locationName': 'Live Location', // Updated
        'inTimeLatitude': position.latitude,
        'inTimeLongitude': position.longitude,
        'inTimeImageUrl': imageUrl,
        'inTimeImageCaptured': true,
      };

      await _apiService.checkIn(checkInData);

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
  
  // --- UPDATED: Now uses image capture and live location data ---
  Future<void> _handleCheckOut() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    setState(() => _isCheckingOut = true);

    try {
      final position = await _getCurrentPosition();
      if (position == null) {
         if(mounted) setState(() => _isCheckingOut = false);
        return;
      }

      final imageFile = await _captureImage();
      if (imageFile == null) {
        if(mounted) setState(() => _isCheckingOut = false);
        return;
      }
      
      scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Uploading image...')));
      final imageUrl = await _apiService.uploadImageToR2(imageFile);
      
      final checkOutData = {
        'userId': int.parse(widget.employee.id),
        'attendanceDate': DateTime.now().toIso8601String(),
        'outTimeImageUrl': imageUrl,
        'outTimeImageCaptured': true,
        'outTimeLatitude': position.latitude,
        'outTimeLongitude': position.longitude,
      };
      
      await _apiService.checkOut(checkOutData);

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
                       child: Padding(
                         padding: const EdgeInsets.all(16.0),
                         child: Center(child: Text('No active PJPs found.', style: TextStyle(color: Colors.white70))),
                       ),
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

