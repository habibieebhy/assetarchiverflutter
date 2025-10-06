import 'package:assetarchiverflutter/models/employee_model.dart';
import 'package:assetarchiverflutter/widgets/reusableglasscard.dart';
import 'package:flutter/material.dart';
import 'package:assetarchiverflutter/api/api_service.dart';
import 'package:assetarchiverflutter/models/pjp_model.dart';
import 'package:assetarchiverflutter/models/dealer_model.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:maplibre_gl/maplibre_gl.dart'; // <-- ADD THIS IMPORT

class EmployeePJPScreen extends StatefulWidget {
  final Employee employee;
  // --- MODIFIED: The callback now expects a LatLng object, not a String ---
  final Function(LatLng destination) onStartJourney;
  final VoidCallback onPjpCreated;

  const EmployeePJPScreen({
    super.key,
    required this.employee,
    required this.onStartJourney,
    required this.onPjpCreated,
  });

  @override
  State<EmployeePJPScreen> createState() => EmployeePJPScreenState();
}

class EmployeePJPScreenState extends State<EmployeePJPScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<Pjp>> _pjpFuture;

  @override
  void initState() {
    super.initState();
    refreshPjpList();
  }

  void refreshPjpList() {
    if (mounted) {
      setState(() {
        _pjpFuture = _apiService.fetchPjpsForUser(int.parse(widget.employee.id), status: 'pending');
      });
    }
  }

  void _handlePjpCreation() {
    refreshPjpList();
    widget.onPjpCreated();
  }

  void _showAddPjpForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddPjpForm(
        employee: widget.employee,
        onPjpCreated: _handlePjpCreation,
      ),
    );
  }

  // --- MODIFIED: This function now parses coordinates from the 'areaToBeVisited' string ---
  Future<void> _startJourneyForPjp(Pjp pjp) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      // 1. Parse the coordinate string (e.g., "26.1445,91.7362")
      final parts = pjp.areaToBeVisited.split(',');
      if (parts.length != 2) throw const FormatException('Invalid coordinate format in PJP.');
      
      final lat = double.tryParse(parts[0]);
      final lon = double.tryParse(parts[1]);

      if (lat == null || lon == null) throw const FormatException('Could not parse numbers from PJP coordinates.');

      // 2. Update the PJP status on the server
      await _apiService.updatePjp(pjp.id, {'status': 'started'});
      scaffoldMessenger.showSnackBar(const SnackBar(
        content: Text('Journey Started!'),
        backgroundColor: Colors.green,
      ));
      
      refreshPjpList();
      widget.onPjpCreated(); 
      
      // 3. Pass the parsed LatLng object to the callback
      final destination = LatLng(lat, lon);
      widget.onStartJourney(destination);

    } catch (e) {
      debugPrint("Failed to start journey: $e");
      scaffoldMessenger.showSnackBar(SnackBar(
        content: Text('Failed to start journey: PJP has invalid location data.'),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          color: const Color(0xFF0D47A1),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0D47A1), Color.fromARGB(255, 2, 10, 103)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: FutureBuilder<List<Pjp>>(
              future: _pjpFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.white));
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.yellow)));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No PJPs to visit.', style: TextStyle(color: Colors.white70)));
                }
                final pjpList = snapshot.data!;
                return ListView.builder(
                  padding: EdgeInsets.only(top: kToolbarHeight + MediaQuery.of(context).padding.top, bottom: 80),
                  itemCount: pjpList.length,
                  itemBuilder: (context, index) {
                    final pjp = pjpList[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Slidable(
                        key: ValueKey(pjp.id),
                        startActionPane: ActionPane(
                          motion: const StretchMotion(),
                          children: [
                            SlidableAction(
                              onPressed: (_) => _startJourneyForPjp(pjp),
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Colors.white,
                              icon: Icons.route,
                              label: 'Start Journey',
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ],
                        ),
                        child: _PjpCard(pjp: pjp),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
        Positioned(
          bottom: 120.0,
          right: 16.0,
          child: FloatingActionButton(
            onPressed: _showAddPjpForm,
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}

class _PjpCard extends StatelessWidget {
  final Pjp pjp;
  const _PjpCard({required this.pjp});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    
    // 👇 FIX: Use dealerName and only fallback to areaToBeVisited if the name is missing.
    // The coordinate parsing logic is REMOVED.
    String displayName = pjp.dealerName ?? pjp.areaToBeVisited; 

    return LiquidGlassCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              displayName, // This now correctly displays the Dealer Name
              style: textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 16),
          const Icon(Icons.keyboard_arrow_left, color: Colors.white70, size: 30),
        ],
      ),
    );
  }
}

class _AddPjpForm extends StatefulWidget {
  final Employee employee;
  final VoidCallback onPjpCreated;
  const _AddPjpForm({required this.employee, required this.onPjpCreated});
  @override
  State<_AddPjpForm> createState() => _AddPjpFormState();
}

class _AddPjpFormState extends State<_AddPjpForm> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  
  Dealer? _selectedDealer;
  final _descriptionController = TextEditingController();
  bool _isSubmitting = false;

  late Future<List<Dealer>> _dealersFuture;

  @override
  void initState() {
    super.initState();
    _dealersFuture = _apiService.fetchDealers(userId: int.parse(widget.employee.id));
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  // --- MODIFIED: This function now stores coordinates in 'areaToBeVisited' ---
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate() || _selectedDealer == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a dealer.'), backgroundColor: Colors.orange));
      return;
    }
    
    final dealer = _selectedDealer!;

    // Check if the selected dealer has location data
    if (dealer.latitude == null || dealer.longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('The selected dealer does not have location data saved.'), 
        backgroundColor: Colors.orange,
      ));
      return;
    }

    setState(() => _isSubmitting = true);
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    try {
      // Format the coordinates into a string: "latitude,longitude"
      final String visitLocation = '${dealer.latitude},${dealer.longitude}';

      final newPjp = Pjp(
        id: '',
        planDate: DateTime.now(),
        userId: int.parse(widget.employee.id),
        createdById: int.parse(widget.employee.id),
        status: 'pending',
        areaToBeVisited: visitLocation, // Use the coordinate string here
        description: _descriptionController.text,
        dealerName: dealer.name,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      await _apiService.createPjp(newPjp);
      widget.onPjpCreated();
      navigator.pop();
      scaffoldMessenger.showSnackBar(const SnackBar(content: Text('PJP Created!'), backgroundColor: Colors.green));

    } catch (e) {
      debugPrint('--- FAILED TO CREATE PJP ---');
      debugPrint('Error: $e');
      scaffoldMessenger.showSnackBar(SnackBar(content: Text('Failed to create PJP: $e'), backgroundColor: Colors.red));
    } finally {
      if(mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(24.0),
        decoration: const BoxDecoration(
          color: Color(0xFF020a67),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Create New PJP', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              FutureBuilder<List<Dealer>>(
                future: _dealersFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                  if (!snapshot.hasData || snapshot.data!.isEmpty) return const Text('No dealers found for this user.', style: TextStyle(color: Colors.white70));
                  
                  return DropdownButtonFormField<Dealer>(
                    hint: const Text('Select a Dealer', style: TextStyle(color: Colors.white70)),
                    dropdownColor: const Color(0xFF0D47A1),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white30), borderRadius: BorderRadius.circular(12)),
                    ),
                    items: snapshot.data!.map((dealer) => DropdownMenuItem(value: dealer, child: Text(dealer.name))).toList(),
                    onChanged: (value) => setState(() => _selectedDealer = value),
                    validator: (value) => value == null ? 'Please select a dealer' : null,
                  );
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Description (Optional)',
                  labelStyle: const TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white30), borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitForm,
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                child: _isSubmitting ? const CircularProgressIndicator() : const Text('SUBMIT PJP'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}