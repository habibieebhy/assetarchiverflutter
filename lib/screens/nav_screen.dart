import 'dart:ui';
import 'package:assetarchiverflutter/api/api_service.dart';
import 'package:assetarchiverflutter/models/dealer_model.dart';
import 'package:assetarchiverflutter/models/employee_model.dart';
import 'package:assetarchiverflutter/screens/employee_management/employee_dashboard_screen.dart';
import 'package:assetarchiverflutter/screens/employee_management/employee_profile_screen.dart';
import 'package:assetarchiverflutter/screens/employee_management/employee_pjp_screen.dart';
import 'package:assetarchiverflutter/screens/employee_management/employee_journey_screen.dart';
import 'package:assetarchiverflutter/screens/employee_management/employee_salesorder_screen.dart';
import 'package:assetarchiverflutter/widgets/reusableglasscard.dart';
import 'package:flutter/material.dart';
import 'package:assetarchiverflutter/screens/forms/create_dvr.dart';
import 'package:assetarchiverflutter/screens/forms/create_tvr.dart';
import 'package:assetarchiverflutter/screens/forms/create_leave_form.dart';
import 'package:assetarchiverflutter/screens/forms/create_competition_form.dart';
import 'package:assetarchiverflutter/screens/forms/create_daily_task_form.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_radar/flutter_radar.dart';
import 'dart:async';
import 'package:provider/provider.dart';

class NavProvider with ChangeNotifier {
  int _selectedIndex = 0;
  Map<String, dynamic>? _journeyData;

  int get selectedIndex => _selectedIndex;
  Map<String, dynamic>? get journeyData => _journeyData;

  void changePage(int index) {
    _selectedIndex = index;
    notifyListeners();
  }

  void startJourney(Map<String, dynamic> data) {
    _journeyData = data;
    _selectedIndex = 3;
    notifyListeners();
  }

  void clearJourneyData() {
    _journeyData = null;
    notifyListeners();
  }

  void refreshDashboard() {
    debugPrint("Refreshing Dashboard...");
  }

  void refreshPjpList() {
    debugPrint("Refreshing PJP List...");
  }
}

class NavScreen extends StatefulWidget {
  final Employee employee;
  const NavScreen({super.key, required this.employee});

  @override
  State<NavScreen> createState() => _NavScreenState();
}

class _NavScreenState extends State<NavScreen> {
  late final NavProvider _navProvider;

  // --- FIX: PART 1 ---
  // Create a GlobalKey for the Dashboard's state. This gives us direct access to it.
  final GlobalKey<EmployeeDashboardScreenState> _dashboardKey =
      GlobalKey<EmployeeDashboardScreenState>();

  @override
  void initState() {
    super.initState();
    _navProvider = NavProvider();
  }

  @override
  void dispose() {
    _navProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _navProvider,
      child: Consumer<NavProvider>(
        builder: (context, provider, child) {
          final pageTitles = [
            'Home',
            'PJP',
            'Sales Order',
            'Journey',
            'Profile',
          ];

          final pages = <Widget>[
            // --- FIX: PART 2 ---
            // Pass the key to the Dashboard screen instance.
            EmployeeDashboardScreen(
              key: _dashboardKey,
              employee: widget.employee,
            ),
            EmployeePJPScreen(
              employee: widget.employee,
              onStartJourney: provider.startJourney,
              // --- FIX: PART 3 ---
              // When a PJP is created, call our key to trigger the refresh,
              // then call the provider's debugPrint method.
              onPjpCreated: () {
                _dashboardKey.currentState?.refreshData();
                provider.refreshDashboard();
              },
            ),
            SalesOrderScreen(employee: widget.employee),
            EmployeeJourneyScreen(
              initialJourneyData: provider.journeyData,
              employee: widget.employee,
              onDestinationConsumed: provider.clearJourneyData,
            ),
            EmployeeProfileScreen(employee: widget.employee),
          ];

          return Scaffold(
            extendBodyBehindAppBar: true,
            extendBody: true,
            appBar: AppBar(
              title: Text(pageTitles[provider.selectedIndex]),
              backgroundColor: Colors.transparent,
              elevation: 0,
              flexibleSpace: ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
                  child: Container(color: Colors.white.withAlpha(26)),
                ),
              ),
            ),
            drawer: _buildGlassDrawer(context, widget.employee),
            body: IndexedStack(index: provider.selectedIndex, children: pages),
            bottomNavigationBar: _buildGlassNavBar(context, provider),
          );
        },
      ),
    );
  }

  Widget _buildGlassNavBar(BuildContext context, NavProvider provider) {
    return LiquidGlassCard(
      child: BottomNavigationBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.checklist_rtl),
            label: 'PJP',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_outlined),
            label: 'Sales Order',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            label: 'Journey',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: provider.selectedIndex,
        onTap: (index) {
          if (index == 0) provider.refreshDashboard();
          if (index == 1) provider.refreshPjpList();
          provider.changePage(index);
        },
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),
    );
  }

  void _showAddDealerDialog(BuildContext context, Employee employee) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.0),
        ),
        child: _AddDealerForm(employee: employee),
      ),
    );
  }

  void _showCreateDvrDialog(BuildContext context, Employee employee) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.0),
        ),
        child: CreateDvrScreen(employee: employee),
      ),
    );
  }

  void _showCreateTvrDialog(BuildContext context, Employee employee) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: CreateTvrScreen(employee: employee),
      ),
    );
  }

  void _showApplyForLeaveDialog(BuildContext context, Employee employee) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: CreateLeaveFormScreen(employee: employee),
      ),
    );
  }

  void _showCompetitionFormDialog(BuildContext context, Employee employee) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: CreateCompetitionFormScreen(employee: employee),
      ),
    );
  }

  void _showCreateDailyTaskDialog(BuildContext context, Employee employee) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: CreateDailyTaskScreen(employee: employee),
      ),
    );
  }

  Widget _buildGlassDrawer(BuildContext context, Employee employee) {
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
                decoration: const BoxDecoration(color: Colors.transparent),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      employee.companyName ?? 'Your Company',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      employee.displayName,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(color: Colors.white),
                    ),
                    Text(
                      employee.email ?? '',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(color: Colors.white24),
            _buildDrawerActionItem(
              context,
              icon: Icons.person_add_alt,
              text: 'ADD DEALER',
              onTap: () => _showAddDealerDialog(context, employee),
            ),
            _buildDrawerActionItem(
              context,
              icon: Icons.description_outlined,
              text: 'CREATE DVR',
              onTap: () => _showCreateDvrDialog(context, employee),
            ),
            _buildDrawerActionItem(
              context,
              icon: Icons.description,
              text: 'CREATE TVR',
              onTap: () => _showCreateTvrDialog(context, employee),
            ),
            _buildDrawerActionItem(
              context,
              icon: Icons.assessment_outlined,
              text: 'COMPETETION FORM', // Note: Typo in "COMPETETION"
              onTap: () => _showCompetitionFormDialog(context, employee),
            ),
            _buildDrawerActionItem(
              context,
              icon: Icons.account_box_sharp,
              text: 'APPLY FOR LEAVE',
              onTap: () => _showApplyForLeaveDialog(context, employee),
            ),
            _buildDrawerActionItem(
              context,
              icon: Icons.task_alt, // Changed icon
              text: 'CREATE DAILY TASK', // Changed text
              onTap: () => _showCreateDailyTaskDialog(context, employee),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerActionItem(
    BuildContext context, {
    required IconData icon,
    required String text,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(text, style: const TextStyle(color: Colors.white)),
      onTap:
          onTap ??
          () {
            Navigator.pop(context);
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('$text tapped')));
          },
    );
  }
}

// _AddDealerForm remains exactly the same
class _AddDealerForm extends StatefulWidget {
  final Employee employee;
  const _AddDealerForm({required this.employee});

  @override
  State<_AddDealerForm> createState() => _AddDealerFormState();
}

class _AddDealerFormState extends State<_AddDealerForm> {
  // Form and State Management
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();
  bool _isSubmitting = false;
  bool _isLoadingDealers = true;
  bool _isFetchingLocation = false;

  // Controllers for Form Fields
  final _nameController = TextEditingController();
  final _regionController = TextEditingController();
  final _areaController = TextEditingController();
  final _phoneNoController = TextEditingController();
  final _addressController = TextEditingController();
  final _pinCodeController = TextEditingController();
  final _totalPotentialController = TextEditingController();
  final _bestPotentialController = TextEditingController();
  final _brandSellingController = TextEditingController();
  final _feedbacksController = TextEditingController();
  final _remarksController = TextEditingController();

  // Data for Dropdowns and Switches
  String? _selectedType;
  bool _isSubDealer = false;
  List<Dealer> _parentDealers = [];
  Dealer? _selectedParentDealer;

  // Location Data
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _fetchParentDealers();
  }

  @override
  void dispose() {
    // Dispose all controllers to prevent memory leaks
    _nameController.dispose();
    _regionController.dispose();
    _areaController.dispose();
    _phoneNoController.dispose();
    _addressController.dispose();
    _pinCodeController.dispose();
    _totalPotentialController.dispose();
    _bestPotentialController.dispose();
    _brandSellingController.dispose();
    _feedbacksController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  /// Fetches main dealers to act as potential parent dealers for sub-dealers.
  Future<void> _fetchParentDealers() async {
    try {
      final allDealers = await _apiService.fetchDealers(
        userId: int.tryParse(widget.employee.id),
      );
      // A parent dealer is a dealer that doesn't have a parent itself
      final mainDealers = allDealers
          .where((d) => d.parentDealerId == null)
          .toList();
      if (mounted) {
        setState(() {
          _parentDealers = mainDealers;
          _isLoadingDealers = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingDealers = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not fetch parent dealers: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  /// Gets the device's current location and uses reverse geocoding to populate address fields.
// In NavScreen.dart -> _AddDealerFormState

Future<void> _fetchLocationAndAddress() async {
  setState(() => _isFetchingLocation = true);
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  StreamSubscription<Position>? positionStreamSubscription; // Keep track of the stream

  try {
    // 1. Permissions (Using Radar's method for consistency)
    String? status = await Radar.getPermissionsStatus();
    if (status == 'DENIED' || status == 'NOT_DETERMINED') {
      status = await Radar.requestPermissions(true);
    }
    if (status != 'GRANTED_BACKGROUND' && status != 'GRANTED_FOREGROUND') {
      throw Exception('Location permissions are required.');
    }

    // 2. Service Check (Using Geolocator)
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception('Location services are disabled.');

    // --- Listen to stream for 5 seconds ---
    // Completer<Position> positionCompleter = Completer<Position>(); // <-- REMOVED (Unused)
    List<Position> positions = []; // Store readings

    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 0,
    );

    positionStreamSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((Position position) {
      debugPrint("Received location reading: Accuracy ${position.accuracy}");
      positions.add(position);
    });

    // Stop listening after 5 seconds
    await Future.delayed(const Duration(seconds: 5));
    await positionStreamSubscription.cancel(); // Use ?. here is fine
    positionStreamSubscription = null; // Clear the subscription

    // Process the collected positions
    if (positions.isEmpty) {
      throw Exception('Failed to get any location readings in 5 seconds.');
    }

    final Position bestPosition = positions.last;
    debugPrint("Using position with accuracy: ${bestPosition.accuracy}");
    // --- END OF STREAM LOGIC ---

    // 4. Use the chosen coordinates for Reverse Geocoding
    final addressDetails = await _apiService.reverseGeocodeWithRadar(
      latitude: bestPosition.latitude,
      longitude: bestPosition.longitude,
    );

    // 5. Update UI
    if (mounted) {
      setState(() {
        _currentPosition = bestPosition;
        _addressController.text = addressDetails['address']!;
        _regionController.text = addressDetails['region']!;
        _areaController.text = addressDetails['area']!;
        _pinCodeController.text = addressDetails['pinCode']!;
      });
    }
  } catch (e) {
    // --- FIX: Use an explicit null check before cancelling in catch ---
    if (positionStreamSubscription != null) {
      await positionStreamSubscription.cancel();
    }
    scaffoldMessenger.showSnackBar(
      SnackBar(content: Text('Error getting location/address: $e'), backgroundColor: Colors.red),
    );
  } finally {
    if (mounted) {
      setState(() => _isFetchingLocation = false);
    }
  }
}

  /// Validates and submits the form data to create a new dealer.
  Future<void> _submitForm() async {
    // Pre-submission checks
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please get the current location first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    if (_isSubDealer && _selectedParentDealer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a parent dealer for the sub-dealer.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      // Construct the Dealer object from form controllers
      final newDealer = Dealer(
        id: '', // ID is generated by the server
        userId: int.parse(widget.employee.id),
        type: _selectedType!,
        parentDealerId: _isSubDealer ? _selectedParentDealer!.id : null,
        name: _nameController.text,
        region: _regionController.text,
        area: _areaController.text,
        phoneNo: _phoneNoController.text,
        address: _addressController.text,
        pinCode: _pinCodeController.text.isNotEmpty
            ? _pinCodeController.text
            : null,
        totalPotential: double.parse(_totalPotentialController.text),
        bestPotential: double.parse(_bestPotentialController.text),
        brandSelling: _brandSellingController.text
            .split(',')
            .map((e) => e.trim())
            .where((s) => s.isNotEmpty)
            .toList(),
        feedbacks: _feedbacksController.text,
        remarks: _remarksController.text.isNotEmpty
            ? _remarksController.text
            : null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Send the new dealer and its location to the API
      await _apiService.createDealer(
        newDealer,
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
      );

      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Dealer created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      navigator.pop(); // Close the form on success
    } catch (e) {
      debugPrint('--- DEALER CREATION FAILED ---\n$e');
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Failed to create dealer. See debug console for details.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  /// Helper function to create consistent styling for input fields.
  InputDecoration _inputDecoration(String label, {bool readOnly = false}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      fillColor: readOnly ? Colors.white10 : Colors.transparent,
      filled: readOnly,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.white30),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.white),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24.0),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        padding: const EdgeInsets.all(24.0),
        color: const Color(0xFF020a67),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add New Dealer',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _isFetchingLocation
                    ? null
                    : _fetchLocationAndAddress,
                icon: _isFetchingLocation
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : const Icon(Icons.my_location),
                label: const Text('Get Current Location & Address'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Auto-filled location fields (read-only)
                      TextFormField(
                        controller: _addressController,
                        readOnly: true,
                        style: const TextStyle(color: Colors.white70),
                        decoration: _inputDecoration(
                          'Address*',
                          readOnly: true,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _regionController,
                        readOnly: true,
                        style: const TextStyle(color: Colors.white70),
                        decoration: _inputDecoration('Region*', readOnly: true),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _areaController,
                        readOnly: true,
                        style: const TextStyle(color: Colors.white70),
                        decoration: _inputDecoration('Area*', readOnly: true),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _pinCodeController,
                        readOnly: true,
                        style: const TextStyle(color: Colors.white70),
                        decoration: _inputDecoration(
                          'PIN Code',
                          readOnly: true,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Sub-dealer switch and conditional dropdown
                      SwitchListTile(
                        title: const Text(
                          'Is this a Sub-dealer?',
                          style: TextStyle(color: Colors.white),
                        ),
                        value: _isSubDealer,
                        onChanged: (bool value) {
                          setState(() {
                            _isSubDealer = value;
                            if (!value)
                              _selectedParentDealer =
                                  null; // Clear selection if switched off
                          });
                        },
                        activeThumbColor: Colors.amber,
                        contentPadding: EdgeInsets.zero,
                      ),
                      if (_isSubDealer)
                        Padding(
                          padding: const EdgeInsets.only(
                            top: 8.0,
                            bottom: 16.0,
                          ),
                          child: _isLoadingDealers
                              ? const Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                  ),
                                )
                              : DropdownButtonFormField<Dealer>(
                                  value: _selectedParentDealer,
                                  isExpanded: true,
                                  hint: const Text(
                                    'Select Parent Dealer*',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                  dropdownColor: const Color(0xFF0D47A1),
                                  style: const TextStyle(color: Colors.white),
                                  decoration: _inputDecoration('Parent Dealer'),
                                  items: _parentDealers
                                      .map(
                                        (dealer) => DropdownMenuItem(
                                          value: dealer,
                                          child: Text(
                                            dealer.name,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) => setState(
                                    () => _selectedParentDealer = value,
                                  ),
                                  validator: (value) =>
                                      _isSubDealer && value == null
                                      ? 'Please select a parent'
                                      : null,
                                ),
                        ),

                      // Manual input fields
                      TextFormField(
                        controller: _nameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('Dealer/Sub-dealer Name*'),
                        validator: (v) =>
                            v!.isEmpty ? 'Name is required' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedType,
                        hint: const Text(
                          'Select Type*',
                          style: TextStyle(color: Colors.white70),
                        ),
                        dropdownColor: const Color(0xFF0D47A1),
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('Business Type'),
                        items:
                            ['Wholesaler', 'Retailer', 'Distributor', 'Other']
                                .map(
                                  (type) => DropdownMenuItem(
                                    value: type,
                                    child: Text(type),
                                  ),
                                )
                                .toList(),
                        onChanged: (value) =>
                            setState(() => _selectedType = value),
                        validator: (value) =>
                            value == null ? 'Please select a type' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneNoController,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('Phone Number*'),
                        validator: (v) =>
                            v!.isEmpty ? 'Phone number is required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _totalPotentialController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('Total Potential*'),
                        validator: (v) =>
                            v!.isEmpty ? 'Total Potential is required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _bestPotentialController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('Best Potential*'),
                        validator: (v) =>
                            v!.isEmpty ? 'Best Potential is required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _brandSellingController,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration(
                          'Brands (comma-separated)*',
                        ),
                        validator: (v) => v!.isEmpty
                            ? 'At least one brand is required'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _feedbacksController,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('Feedbacks*'),
                        validator: (v) =>
                            v!.isEmpty ? 'Feedback is required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _remarksController,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('Remarks (Optional)'),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isSubmitting || _currentPosition == null
                    ? null
                    : _submitForm,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('SUBMIT DEALER'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
