import 'package:assetarchiverflutter/models/employee_model.dart';
import 'package:assetarchiverflutter/widgets/reusableglasscard.dart';
import 'package:flutter/material.dart';
import 'package:assetarchiverflutter/api/api_service.dart';
import 'package:assetarchiverflutter/models/pjp_model.dart';
import 'package:assetarchiverflutter/models/dealer_model.dart';

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
    _pjpFuture = _apiService.fetchPjpsForUser(int.parse(widget.employee.id));
  }

  void _refreshPjpList() {
    setState(() {
      _pjpFuture = _apiService.fetchPjpsForUser(int.parse(widget.employee.id));
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
        ),
  
        Positioned(
          bottom: 100.0,
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

    return LiquidGlassCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              pjp.areaToBeVisited, 
              style: textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)
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
      final dealer = _selectedDealer!;
      final String visitDescription = '${dealer.name}, ${dealer.address}';

      final newPjp = Pjp(
        id: '',
        planDate: DateTime.now(),
        userId: int.parse(widget.employee.id),
        createdById: int.parse(widget.employee.id),
        status: 'pending',
        areaToBeVisited: visitDescription, 
        description: _descriptionController.text,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      await _apiService.createPjp(newPjp);
      widget.onPjpCreated();
      navigator.pop();
      scaffoldMessenger.showSnackBar(const SnackBar(content: Text('PJP Created!'), backgroundColor: Colors.green));

    } catch (e) {
      // ✅ DEBUGGING LINES ADDED HERE
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