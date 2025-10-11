// lib/screens/forms/create_leave_form.dart
import 'dart:ui';
import 'package:assetarchiverflutter/api/api_service.dart';
import 'package:assetarchiverflutter/models/leave_application_model.dart';
import 'package:assetarchiverflutter/models/employee_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CreateLeaveFormScreen extends StatefulWidget {
  final Employee employee;
  const CreateLeaveFormScreen({super.key, required this.employee});

  @override
  State<CreateLeaveFormScreen> createState() => _CreateLeaveFormScreenState();
}

class _CreateLeaveFormScreenState extends State<CreateLeaveFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();
  final _reasonController = TextEditingController();

  // State Management
  bool _isSubmitting = false;
  String? _selectedLeaveType;
  DateTime? _startDate;
  DateTime? _endDate;

  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, {required bool isStartDate}) async {
    final now = DateTime.now();
    final firstDate = isStartDate ? now : (_startDate ?? now);
    final initialDate = isStartDate ? (_startDate ?? now) : (_endDate ?? _startDate ?? now);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime(now.year + 1),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          _startDateController.text = DateFormat('dd-MM-yyyy').format(picked);
          // If end date is before new start date, reset it
          if (_endDate != null && _endDate!.isBefore(picked)) {
            _endDate = null;
            _endDateController.clear();
          }
        } else {
          _endDate = picked;
          _endDateController.text = DateFormat('dd-MM-yyyy').format(picked);
        }
      });
    }
  }

  Future<void> _submitLeaveApplication() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _isSubmitting = true);

    try {
      final newApplication = LeaveApplication(
        userId: int.parse(widget.employee.id),
        leaveType: _selectedLeaveType!,
        startDate: _startDate!,
        endDate: _endDate!,
        reason: _reasonController.text,
        status: 'Pending', // Status is always "Pending" on creation
      );

      await _apiService.createLeaveApplication(newApplication);

      scaffoldMessenger.showSnackBar(const SnackBar(
        content: Text('Leave application submitted successfully!'),
        backgroundColor: Colors.green,
      ));
      navigator.pop();
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(SnackBar(
          content: Text('Submission failed: $e'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: '$label*',
      labelStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: Colors.transparent,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white30), borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white), borderRadius: BorderRadius.circular(12)),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                            const Text('Apply for Leave', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.white),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ],
                        ),
                        const Divider(color: Colors.white24, height: 30),
                        
                        DropdownButtonFormField<String>(
                          initialValue: _selectedLeaveType,
                          dropdownColor: const Color(0xFF0D47A1),
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDecoration('Leave Type'),
                          items: ['Sick Leave', 'Casual Leave', 'Paid Leave', 'Other']
                              .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                              .toList(),
                          onChanged: (value) => setState(() => _selectedLeaveType = value),
                          validator: (v) => v == null ? 'Please select a leave type' : null,
                        ),
                        const SizedBox(height: 16),
                        
                        TextFormField(
                          controller: _startDateController,
                          readOnly: true,
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDecoration('Start Date').copyWith(
                            suffixIcon: const Icon(Icons.calendar_today, color: Colors.white70),
                          ),
                          onTap: () => _selectDate(context, isStartDate: true),
                          validator: (v) => v!.isEmpty ? 'Please select a start date' : null,
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _endDateController,
                          readOnly: true,
                          style: const TextStyle(color: Colors.white),
                           decoration: _inputDecoration('End Date').copyWith(
                            suffixIcon: const Icon(Icons.calendar_today, color: Colors.white70),
                          ),
                          onTap: () => _selectDate(context, isStartDate: false),
                          validator: (v) => v!.isEmpty ? 'Please select an end date' : null,
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _reasonController,
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDecoration('Reason'),
                          maxLines: 4,
                          validator: (v) => v!.isEmpty ? 'Please provide a reason' : null,
                        ),
                        const SizedBox(height: 24),
                        
                        ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitLeaveApplication,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.black,
                          ),
                          child: _isSubmitting
                              ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.black))
                              : const Text('SUBMIT APPLICATION', style: TextStyle(fontWeight: FontWeight.bold)),
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