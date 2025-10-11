// lib/screens/forms/create_daily_task_form.dart
import 'dart:ui';
import 'package:assetarchiverflutter/api/api_service.dart';
import 'package:assetarchiverflutter/models/daily_task_model.dart';
import 'package:assetarchiverflutter/models/pjp_model.dart';
import 'package:assetarchiverflutter/models/dealer_model.dart';
import 'package:assetarchiverflutter/models/employee_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// We need the PJP Form, so let's import the screen where it lives.
import 'package:assetarchiverflutter/screens/employee_management/employee_pjp_screen.dart';

class CreateDailyTaskScreen extends StatefulWidget {
  final Employee employee;
  const CreateDailyTaskScreen({super.key, required this.employee});

  @override
  State<CreateDailyTaskScreen> createState() => _CreateDailyTaskScreenState();
}

class _CreateDailyTaskScreenState extends State<CreateDailyTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();

  // Controllers
  final _siteNameController = TextEditingController();
  final _descriptionController = TextEditingController();

  // State
  bool _isSubmitting = false;
  String? _selectedVisitType;
  Pjp? _selectedPjp;

  late Future<List<Pjp>> _pjpFuture;
  List<Pjp> _pjpList = [];

  @override
  void initState() {
    super.initState();
    _fetchTodaysPjps();
  }

  @override
  void dispose() {
    _siteNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _fetchTodaysPjps() {
    // Fetch only PJPs that are pending for today
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    if (mounted) {
      setState(() {
        _pjpFuture = _apiService.fetchPjpsForUser(
          int.parse(widget.employee.id),
          status: 'pending',
          startDate: today,
          endDate: today,
        );
        // Store the result for easy access
        _pjpFuture.then((pjps) {
          if (mounted) {
            setState(() => _pjpList = pjps);
          }
        });
      });
    }
  }

  Future<void> _showAddPjpFormAndRefresh() async {
    // This function shows the PJP form and waits for it to close.
    // We pass a callback that will refresh our PJP list.
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddPjpForm(
        employee: widget.employee,
        onPjpCreated: () {
          _fetchTodaysPjps();
        },
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _isSubmitting = true);

    try {
      // Find the dealer ID from the selected PJP if it's a dealer visit.
      String? relatedDealerId;
      if (_selectedVisitType == 'Dealer Visit' && _selectedPjp != null) {
        final List<Dealer> dealers = await _apiService.fetchDealers(
          userId: int.parse(widget.employee.id),
        );
        final matchingDealer = dealers.firstWhere(
          (d) => d.name == _selectedPjp!.dealerName,
          orElse: () => throw Exception(
            'Could not find the dealer associated with the selected PJP.',
          ),
        );
        relatedDealerId = matchingDealer.id;
      }

      final newTask = DailyTask(
        userId: int.parse(widget.employee.id),
        assignedByUserId: int.parse(
          widget.employee.id,
        ), // User assigns to themselves
        taskDate: DateTime.now(),
        visitType: _selectedVisitType!,
        status: 'Assigned',
        pjpId: _selectedPjp?.id,
        relatedDealerId: relatedDealerId,
        siteName: _siteNameController.text.isNotEmpty
            ? _siteNameController.text
            : null,
        description: _descriptionController.text.isNotEmpty
            ? _descriptionController.text
            : null,
      );

      await _apiService.createDailyTask(newTask);

      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Daily task created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      navigator.pop();
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Submission failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  InputDecoration _inputDecoration(String label, {bool isRequired = true}) {
    return InputDecoration(
      labelText: '$label${isRequired ? '*' : ''}',
      labelStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: Colors.transparent,
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
    bool isDealerVisit = _selectedVisitType == 'Dealer Visit';
    bool isSiteVisit = _selectedVisitType == 'Site Visit';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24.0),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFF020a67).withOpacity(0.9),
                    borderRadius: BorderRadius.circular(24.0),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Create Daily Task',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white,
                              ),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ],
                        ),
                        const Divider(color: Colors.white24, height: 30),

                        DropdownButtonFormField<String>(
                          initialValue: _selectedVisitType,
                          dropdownColor: const Color(0xFF0D47A1),
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDecoration('Task Type'),
                          items:
                              [
                                    'Dealer Visit',
                                    'Site Visit',
                                    'Office Work',
                                    'Follow-up',
                                  ]
                                  .map(
                                    (type) => DropdownMenuItem(
                                      value: type,
                                      child: Text(type),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (value) => setState(() {
                            _selectedVisitType = value;
                            _selectedPjp =
                                null; // Reset PJP selection on type change
                          }),
                          validator: (v) =>
                              v == null ? 'Please select a task type' : null,
                        ),
                        const SizedBox(height: 16),

                        // --- Conditional UI for Dealer Visit ---
                        if (isDealerVisit)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              FutureBuilder<List<Pjp>>(
                                future: _pjpFuture,
                                builder: (context, snapshot) {
                                  // --- FIX: Added curly braces {} ---
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
                                  }
                                  // --- FIX: Added curly braces {} ---
                                  if (snapshot.hasError) {
                                    return Text(
                                      'Could not load PJPs: ${snapshot.error}',
                                      style: const TextStyle(color: Colors.red),
                                    );
                                  }

                                  return DropdownButtonFormField<Pjp>(
                                    hint: const Text(
                                      'Select Today\'s PJP',
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                    initialValue: _selectedPjp,
                                    isExpanded: true,
                                    dropdownColor: const Color(0xFF0D47A1),
                                    style: const TextStyle(color: Colors.white),
                                    decoration: _inputDecoration('PJP'),
                                    items: _pjpList
                                        .map(
                                          (pjp) => DropdownMenuItem(
                                            value: pjp,
                                            child: Text(
                                              pjp.dealerName ??
                                                  'PJP for ${pjp.areaToBeVisited.split("|").first}',
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (value) =>
                                        setState(() => _selectedPjp = value),
                                    validator: (v) => v == null
                                        ? 'Please select a PJP'
                                        : null,
                                  );
                                },
                              ),
                              const SizedBox(height: 8),
                              TextButton.icon(
                                icon: const Icon(
                                  Icons.add,
                                  color: Colors.amber,
                                ),
                                label: const Text(
                                  'Create New PJP if not listed',
                                  style: TextStyle(color: Colors.amber),
                                ),
                                onPressed: _showAddPjpFormAndRefresh,
                              ),
                            ],
                          ),

                        // --- Conditional UI for Site Visit ---
                        if (isSiteVisit)
                          TextFormField(
                            controller: _siteNameController,
                            style: const TextStyle(color: Colors.white),
                            decoration: _inputDecoration('Site Name'),
                            validator: (v) =>
                                v!.isEmpty ? 'Site name is required' : null,
                          ),

                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _descriptionController,
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDecoration(
                            'Description',
                            isRequired: false,
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 24),

                        ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitForm,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.black,
                          ),
                          child: _isSubmitting
                              ? const CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.black,
                                  ),
                                )
                              : const Text(
                                  'SUBMIT TASK',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}