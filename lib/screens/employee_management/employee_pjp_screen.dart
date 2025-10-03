import 'package:assetarchiverflutter/models/employee_model.dart';
import 'package:assetarchiverflutter/widgets/reusableglasscard.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:slide_to_act/slide_to_act.dart';
import 'package:assetarchiverflutter/api/api_service.dart';
import 'package:assetarchiverflutter/models/pjp_model.dart';
import 'package:assetarchiverflutter/models/dealer_model.dart';

class JourneyScreenArgs {
  final Position startLocation;
  final Dealer destination;
  JourneyScreenArgs({required this.startLocation, required this.destination});
}

class EmployeePJPScreen extends StatefulWidget {
  final Employee employee;
  const EmployeePJPScreen({super.key, required this.employee});

  @override
  State<EmployeePJPScreen> createState() => _EmployeePJPScreenState();
}

class _EmployeePJPScreenState extends State<EmployeePJPScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<Pjp>> _pjpFuture;

  @override
  void initState() {
    super.initState();
    _pjpFuture = _fetchAndPopulatePjps();
  }

  Future<List<Pjp>> _fetchAndPopulatePjps() async {
    final basicPjps = await _apiService.fetchPjpsForUser(int.parse(widget.employee.id));
    final listOfDetailFutures = basicPjps.map((pjp) async {
      if (pjp.dealerId != null && pjp.dealerId!.isNotEmpty) {
        try {
          final dealer = await _apiService.fetchDealerById(pjp.dealerId!);
          return pjp.copyWith(dealer: dealer);
        } catch (e) { return pjp; }
      }
      return pjp;
    }).toList();
    return await Future.wait(listOfDetailFutures);
  }
  
  void _refreshPjpList() {
    setState(() {
      _pjpFuture = _fetchAndPopulatePjps();
    });
  }

  void _showAddPjpForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddPjpForm(
        employee: widget.employee,
        onPjpCreated: _refreshPjpList,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D47A1),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddPjpForm,
        child: const Icon(Icons.add),
      ),
      body: Container(
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
              return const Center(child: Text('No PJPs found.', style: TextStyle(color: Colors.white70)));
            }
            final pjpList = snapshot.data!;
            return ListView.builder(
              padding: EdgeInsets.only(top: kToolbarHeight + MediaQuery.of(context).padding.top, bottom: 80),
              itemCount: pjpList.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: _PjpCard(pjp: pjpList[index]),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _PjpCard extends StatelessWidget {
  final Pjp pjp;
  const _PjpCard({required this.pjp});

  Future<void> _launchDialer(String phoneNumber, BuildContext context) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (!await launchUrl(launchUri)) {
      scaffoldMessenger.showSnackBar(SnackBar(content: Text('Could not open dialer for $phoneNumber')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    // We can still get the dealer for the phone number, etc.
    final dealer = pjp.dealer;

    return LiquidGlassCard(
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ✅ CHANGED: Use the new displayArea getter for a cleaner look
                    Text(
                      pjp.displayArea, 
                      style: textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)
                    ),
                    const SizedBox(height: 8),
                    if (dealer != null && dealer.phoneNo.isNotEmpty)
                      InkWell(
                        onTap: () => _launchDialer(dealer.phoneNo, context),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Text(dealer.phoneNo, style: textTheme.bodyMedium?.copyWith(color: Colors.lightBlueAccent, decoration: TextDecoration.underline, decorationColor: Colors.lightBlueAccent)),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: SizedBox(
                  width: 80, height: 80,
                  child: Stack(fit: StackFit.expand, alignment: Alignment.center, children: [
                    Image.network('https://placehold.co/160x160/334155/e2e8f0?text=Map', fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(color: Colors.grey.shade800)),
                    const Icon(Icons.location_on, color: Colors.redAccent, size: 40),
                  ]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (pjp.dealer != null) _SwipeToStartAction(pjp: pjp),
        ],
      ),
    );
  }
}

class _SwipeToStartAction extends StatefulWidget {
  final Pjp pjp;
  const _SwipeToStartAction({required this.pjp});

  @override
  State<_SwipeToStartAction> createState() => _SwipeToStartActionState();
}

class _SwipeToStartActionState extends State<_SwipeToStartAction> {
  bool _isLoading = false;
  final GlobalKey<SlideActionState> _slideKey = GlobalKey<SlideActionState>();

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return Future.error('Location services are disabled.');
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return Future.error('Location permissions are denied');
    }
    if (permission == LocationPermission.deniedForever) return Future.error('Location permissions are permanently denied.');
    return await Geolocator.getCurrentPosition();
  }

  Future<void> _startJourney() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final startLocation = await _determinePosition();
      final destination = widget.pjp.dealer!;
      navigator.pushNamed('/journey', arguments: JourneyScreenArgs(startLocation: startLocation, destination: destination));
    } catch (e) {
      scaffoldMessenger.showSnackBar(SnackBar(content: Text('Failed to start journey: $e'), backgroundColor: Colors.red));
      if(mounted) _slideKey.currentState?.reset();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading 
      ? const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator(color: Colors.white)))
      : SlideAction(
        key: _slideKey,
        onSubmit: _startJourney,
        innerColor: Colors.white,
        outerColor: Theme.of(context).colorScheme.primary.withAlpha((255 * 0.5).round()),
        sliderButtonIcon: const Icon(Icons.arrow_forward),
        text: 'SWIPE TO START JOURNEY',
        textStyle: const TextStyle(color: Colors.white, fontSize: 14),
        borderRadius: 12,
        elevation: 0,
        height: 56,
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

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate() || _selectedDealer == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a dealer.'), backgroundColor: Colors.orange));
      return;
    }
    setState(() => _isSubmitting = true);
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    try {
      // ✅ CHANGED: The Pjp constructor no longer needs areaToBeVisited
      final newPjp = Pjp(
        id: '', // Placeholder
        planDate: DateTime.now(),
        userId: int.parse(widget.employee.id),
        createdById: int.parse(widget.employee.id),
        status: 'pending',
        description: _descriptionController.text,
        dealerId: _selectedDealer!.id,
      );
      
      await _apiService.createPjp(newPjp);
      widget.onPjpCreated();
      navigator.pop();
      scaffoldMessenger.showSnackBar(const SnackBar(content: Text('PJP Created!'), backgroundColor: Colors.green));

    } catch (e) {
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