// lib/screens/forms/create_competition_form.dart
import 'dart:ui';
import 'package:assetarchiverflutter/api/api_service.dart';
import 'package:assetarchiverflutter/models/competition_report_model.dart';
import 'package:assetarchiverflutter/models/employee_model.dart';
import 'package:flutter/material.dart';

class CreateCompetitionFormScreen extends StatefulWidget {
  final Employee employee;
  const CreateCompetitionFormScreen({super.key, required this.employee});

  @override
  State<CreateCompetitionFormScreen> createState() => _CreateCompetitionFormScreenState();
}

class _CreateCompetitionFormScreenState extends State<CreateCompetitionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();
  
  // Controllers
  final _brandNameController = TextEditingController();
  final _billingController = TextEditingController();
  final _nodController = TextEditingController();
  final _retailController = TextEditingController();
  final _avgSchemeCostController = TextEditingController();
  final _remarksController = TextEditingController();

  // State
  bool _isSubmitting = false;
  String? _selectedSchemeOption;

  @override
  void dispose() {
    _brandNameController.dispose();
    _billingController.dispose();
    _nodController.dispose();
    _retailController.dispose();
    _avgSchemeCostController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _isSubmitting = true);

    try {
      final newReport = CompetitionReport(
        userId: int.parse(widget.employee.id),
        reportDate: DateTime.now(),
        brandName: _brandNameController.text,
        billing: _billingController.text,
        nod: _nodController.text,
        retail: _retailController.text,
        schemesYesNo: _selectedSchemeOption!,
        avgSchemeCost: double.parse(_avgSchemeCostController.text),
        remarks: _remarksController.text.isNotEmpty ? _remarksController.text : null,
      );

      await _apiService.createCompetitionReport(newReport);

      scaffoldMessenger.showSnackBar(const SnackBar(
        content: Text('Competition report submitted successfully!'),
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

  InputDecoration _inputDecoration(String label, {bool isRequired = true}) {
    return InputDecoration(
      labelText: '$label${isRequired ? '*' : ''}',
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
                            const Text('Competition Form', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.white),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ],
                        ),
                        const Divider(color: Colors.white24, height: 30),
                        
                        TextFormField(controller: _brandNameController, style: const TextStyle(color: Colors.white), decoration: _inputDecoration('Brand Name'), validator: (v) => v!.isEmpty ? 'Brand name is required' : null),
                        const SizedBox(height: 16),
                        
                        TextFormField(controller: _billingController, style: const TextStyle(color: Colors.white), decoration: _inputDecoration('Billing'), validator: (v) => v!.isEmpty ? 'Billing info is required' : null),
                        const SizedBox(height: 16),

                        TextFormField(controller: _nodController, style: const TextStyle(color: Colors.white), decoration: _inputDecoration('NOD (Net of Distributor)'), validator: (v) => v!.isEmpty ? 'NOD is required' : null),
                        const SizedBox(height: 16),

                        TextFormField(controller: _retailController, style: const TextStyle(color: Colors.white), decoration: _inputDecoration('Retail'), validator: (v) => v!.isEmpty ? 'Retail info is required' : null),
                        const SizedBox(height: 16),
                        
                        DropdownButtonFormField<String>(
                          initialValue: _selectedSchemeOption,
                          dropdownColor: const Color(0xFF0D47A1),
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDecoration('Schemes'),
                          items: ['Yes', 'No']
                              .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                              .toList(),
                          onChanged: (value) => setState(() => _selectedSchemeOption = value),
                          validator: (v) => v == null ? 'Please select an option' : null,
                        ),
                        const SizedBox(height: 16),

                        TextFormField(controller: _avgSchemeCostController, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: _inputDecoration('Average Scheme Cost'), validator: (v) => v!.isEmpty ? 'Average cost is required' : null),
                        const SizedBox(height: 16),
                        
                        TextFormField(controller: _remarksController, style: const TextStyle(color: Colors.white), decoration: _inputDecoration('Remarks', isRequired: false), maxLines: 3),
                        const SizedBox(height: 24),
                        
                        ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitForm,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.black,
                          ),
                          child: _isSubmitting
                              ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.black))
                              : const Text('SUBMIT REPORT', style: TextStyle(fontWeight: FontWeight.bold)),
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