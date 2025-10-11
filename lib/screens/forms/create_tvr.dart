// lib/screens/forms/create_tvr.dart
import 'dart:io';
import 'dart:ui';
import 'package:assetarchiverflutter/api/api_service.dart';
import 'package:assetarchiverflutter/models/technical_visit_report_model.dart';
import 'package:assetarchiverflutter/models/employee_model.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class CreateTvrScreen extends StatefulWidget {
  final Employee employee;
  const CreateTvrScreen({super.key, required this.employee});

  @override
  State<CreateTvrScreen> createState() => _CreateTvrScreenState();
}

class _CreateTvrScreenState extends State<CreateTvrScreen> {
  // Keys & Services
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();
  final _imagePicker = ImagePicker();

  // Form Controllers
  final _siteNameConcernedPersonController = TextEditingController();
  final _phoneNoController = TextEditingController();
  final _emailIdController = TextEditingController();
  final _clientsRemarksController = TextEditingController();
  final _salespersonRemarksController = TextEditingController();
  final _siteVisitBrandInUseController = TextEditingController();
  final _siteVisitStageController = TextEditingController();
  final _conversionFromBrandController = TextEditingController();
  final _conversionQuantityValueController = TextEditingController();
  final _conversionQuantityUnitController = TextEditingController();
  final _associatedPartyNameController = TextEditingController();
  final _influencerTypeController = TextEditingController();
  final _serviceTypeController = TextEditingController();
  final _qualityComplaintController = TextEditingController();
  final _promotionalActivityController = TextEditingController();
  final _channelPartnerVisitController = TextEditingController();

  // State Management
  bool _isSubmitting = false;
  bool _isUploadingImage = false;
  String? _selectedVisitType;

  // Workflow Data Holders
  DateTime? _checkInTime;
  File? _inTimeImageFile;
  String? _inTimeImageUrl;
  Position? _capturedLocation; // To store the location from check-in

  @override
  void dispose() {
    // Dispose all controllers
    _siteNameConcernedPersonController.dispose();
    _phoneNoController.dispose();
    _emailIdController.dispose();
    _clientsRemarksController.dispose();
    _salespersonRemarksController.dispose();
    _siteVisitBrandInUseController.dispose();
    _siteVisitStageController.dispose();
    _conversionFromBrandController.dispose();
    _conversionQuantityValueController.dispose();
    _conversionQuantityUnitController.dispose();
    _associatedPartyNameController.dispose();
    _influencerTypeController.dispose();
    _serviceTypeController.dispose();
    _qualityComplaintController.dispose();
    _promotionalActivityController.dispose();
    _channelPartnerVisitController.dispose();
    super.dispose();
  }

  // --- Core Logic ---

  Future<void> _handleCheckIn() async {
    // Validate the initial required fields before allowing check-in
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please fill Site Name and Phone Number first.'),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    setState(() => _isUploadingImage = true);
    try {
      // 1. Get Location
      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

      // 2. Pick Image
      final pickedFile = await _imagePicker.pickImage(source: ImageSource.camera, imageQuality: 70, maxWidth: 1024);
      if (pickedFile == null) {
         if(mounted) setState(() => _isUploadingImage = false);
         return;
      }
      
      final imageFile = File(pickedFile.path);
      if (mounted) setState(() => _inTimeImageFile = imageFile);

      // 3. Upload Image
      final imageUrl = await _apiService.uploadImageToR2(imageFile);

      // 4. Set State
      if (mounted) {
        setState(() {
          _checkInTime = DateTime.now();
          _inTimeImageUrl = imageUrl;
          _capturedLocation = position; // Save the location
        });
        scaffoldMessenger.showSnackBar(const SnackBar(
          content: Text('Checked-In with photo and location successfully.'), backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(SnackBar(content: Text('Check-In Failed: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if(mounted) setState(() => _isUploadingImage = false);
    }
  }

  Future<void> _submitTvr() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields.'), backgroundColor: Colors.orange));
      return;
    }
    
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _isSubmitting = true);

    try {
      // 1. Capture Check-Out Image
      final pickedFile = await _imagePicker.pickImage(source: ImageSource.camera, imageQuality: 70, maxWidth: 1024);
      if (pickedFile == null) {
        scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Check-out photo is required to submit.'), backgroundColor: Colors.orange));
        setState(() => _isSubmitting = false);
        return;
      }
      final outTimeImageFile = File(pickedFile.path);
      final outTimeImageUrl = await _apiService.uploadImageToR2(outTimeImageFile);
      final checkOutTime = DateTime.now();

      // 2. Prepend location to salesperson remarks
      final locationString = "[Site Location: ${_capturedLocation!.latitude}, ${_capturedLocation!.longitude}]";
      final finalSalespersonRemarks = '$locationString\n${_salespersonRemarksController.text}';

      // 3. Prepare TVR Object
      final tvrReport = TechnicalVisitReport(
        userId: int.parse(widget.employee.id),
        reportDate: _checkInTime!,
        visitType: _selectedVisitType!,
        siteNameConcernedPerson: _siteNameConcernedPersonController.text,
        phoneNo: _phoneNoController.text,
        emailId: _emailIdController.text.isNotEmpty ? _emailIdController.text : null,
        clientsRemarks: _clientsRemarksController.text,
        salespersonRemarks: finalSalespersonRemarks, // Use the modified remarks
        checkInTime: _checkInTime!,
        checkOutTime: checkOutTime,
        inTimeImageUrl: _inTimeImageUrl,
        outTimeImageUrl: outTimeImageUrl,
        siteVisitBrandInUse: _siteVisitBrandInUseController.text.split(',').map((e) => e.trim()).where((s) => s.isNotEmpty).toList(),
        influencerType: _influencerTypeController.text.split(',').map((e) => e.trim()).where((s) => s.isNotEmpty).toList(),
        siteVisitStage: _siteVisitStageController.text.isNotEmpty ? _siteVisitStageController.text : null,
        conversionFromBrand: _conversionFromBrandController.text.isNotEmpty ? _conversionFromBrandController.text : null,
        conversionQuantityValue: _conversionQuantityValueController.text.isNotEmpty ? double.tryParse(_conversionQuantityValueController.text) : null,
        conversionQuantityUnit: _conversionQuantityUnitController.text.isNotEmpty ? _conversionQuantityUnitController.text : null,
        associatedPartyName: _associatedPartyNameController.text.isNotEmpty ? _associatedPartyNameController.text : null,
        serviceType: _serviceTypeController.text.isNotEmpty ? _serviceTypeController.text : null,
        qualityComplaint: _qualityComplaintController.text.isNotEmpty ? _qualityComplaintController.text : null,
        promotionalActivity: _promotionalActivityController.text.isNotEmpty ? _promotionalActivityController.text : null,
        channelPartnerVisit: _channelPartnerVisitController.text.isNotEmpty ? _channelPartnerVisitController.text : null,
      );

      // 4. Submit to API
      await _apiService.createTvr(tvrReport);

      scaffoldMessenger.showSnackBar(const SnackBar(content: Text('TVR submitted successfully!'), backgroundColor: Colors.green));
      navigator.pop();

    } catch (e) {
      if(mounted) {
        scaffoldMessenger.showSnackBar(SnackBar(content: Text('$e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // --- UI Helper Widgets ---
  InputDecoration _inputDecoration(String label, {bool isRequired = true, String? hint}) {
    return InputDecoration(
      labelText: '$label${isRequired ? '*' : ''}',
      hintText: hint,
      labelStyle: const TextStyle(color: Colors.white70),
      hintStyle: const TextStyle(color: Colors.white30),
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
                    border: Border.all(color: Colors.white.withOpacity(0.2))
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
                            const Text('Technical Visit Report', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.white),
                              onPressed: () => Navigator.of(context).pop(),
                            )
                          ],
                        ),
                        const Divider(color: Colors.white24, height: 30),

                        // --- Step 1: Initial Details & Check-In ---
                        if (_checkInTime == null) ...[
                          TextFormField(controller: _siteNameConcernedPersonController, style: const TextStyle(color: Colors.white), decoration: _inputDecoration('Site Name / Concerned Person'), validator: (v) => v!.isEmpty ? 'This field is required' : null),
                          const SizedBox(height: 16),
                          TextFormField(controller: _phoneNoController, keyboardType: TextInputType.phone, style: const TextStyle(color: Colors.white), decoration: _inputDecoration('Phone Number'), validator: (v) => v!.isEmpty ? 'Phone number is required' : null),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _isUploadingImage ? null : _handleCheckIn,
                            icon: _isUploadingImage ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.camera_alt),
                            label: const Text('CHECK-IN WITH PHOTO & LOCATION'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 50),
                              backgroundColor: Colors.amber,
                              foregroundColor: Colors.black,
                            ),
                          ),
                        ],
                        
                        // --- Step 2: Full Form (after check-in) ---
                        if (_checkInTime != null) ...[
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundImage: _inTimeImageFile != null ? FileImage(_inTimeImageFile!) : null,
                              child: _inTimeImageFile == null ? const Icon(Icons.check_circle, color: Colors.green) : null,
                            ),
                            title: Text(_siteNameConcernedPersonController.text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            subtitle: Text('Checked-In at ${DateFormat('hh:mm a').format(_checkInTime!)}', style: const TextStyle(color: Colors.white70)),
                            trailing: const Icon(Icons.location_on, color: Colors.green, size: 32),
                          ),
                          const Divider(color: Colors.white24, height: 30),

                          DropdownButtonFormField<String>(
                            initialValue: _selectedVisitType,
                            dropdownColor: const Color(0xFF0D47A1),
                            style: const TextStyle(color: Colors.white),
                            decoration: _inputDecoration('Visit Type'),
                            items: ['Site Visit', 'Conversion', 'Influencer Meet', 'Service', 'Complaint', 'Promotional', 'Partner Visit']
                                .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                                .toList(),
                            onChanged: (value) => setState(() => _selectedVisitType = value),
                            validator: (v) => v == null ? 'Please select a visit type' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(controller: _emailIdController, keyboardType: TextInputType.emailAddress, style: const TextStyle(color: Colors.white), decoration: _inputDecoration('Email ID', isRequired: false)),
                          const SizedBox(height: 16),
                          TextFormField(controller: _clientsRemarksController, style: const TextStyle(color: Colors.white), decoration: _inputDecoration('Client\'s Remarks'), maxLines: 3, validator: (v) => v!.isEmpty ? 'This field is required' : null),
                          const SizedBox(height: 16),
                          TextFormField(controller: _salespersonRemarksController, style: const TextStyle(color: Colors.white), decoration: _inputDecoration('Salesperson Remarks'), maxLines: 3, validator: (v) => v!.isEmpty ? 'This field is required' : null),
                          const SizedBox(height: 16),
                          TextFormField(controller: _siteVisitBrandInUseController, style: const TextStyle(color: Colors.white), decoration: _inputDecoration('Brands in Use', hint: 'Brand A, Brand B'), validator: (v) => v!.isEmpty ? 'At least one brand is required' : null),
                          const SizedBox(height: 16),
                           TextFormField(controller: _influencerTypeController, style: const TextStyle(color: Colors.white), decoration: _inputDecoration('Influencer Type', hint: 'e.g., Mason, Contractor'), validator: (v) => v!.isEmpty ? 'This field is required' : null),
                          const SizedBox(height: 16),
                          
                          // Optional Fields
                          const Divider(color: Colors.white24, height: 20),
                          const Text("Optional Details", style: TextStyle(color: Colors.white70, fontSize: 16)),
                          const SizedBox(height: 16),

                          TextFormField(controller: _siteVisitStageController, style: const TextStyle(color: Colors.white), decoration: _inputDecoration('Site Visit Stage', isRequired: false)),
                          const SizedBox(height: 16),
                          TextFormField(controller: _conversionFromBrandController, style: const TextStyle(color: Colors.white), decoration: _inputDecoration('Conversion from Brand', isRequired: false)),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(flex: 2, child: TextFormField(controller: _conversionQuantityValueController, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: _inputDecoration('Conversion Qty', isRequired: false))),
                              const SizedBox(width: 8),
                              Expanded(flex: 1, child: TextFormField(controller: _conversionQuantityUnitController, style: const TextStyle(color: Colors.white), decoration: _inputDecoration('Unit', isRequired: false, hint: 'e.g., Bags'))),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextFormField(controller: _associatedPartyNameController, style: const TextStyle(color: Colors.white), decoration: _inputDecoration('Associated Party Name', isRequired: false)),
                          const SizedBox(height: 16),
                          TextFormField(controller: _serviceTypeController, style: const TextStyle(color: Colors.white), decoration: _inputDecoration('Service Type', isRequired: false)),
                          const SizedBox(height: 16),
                          TextFormField(controller: _qualityComplaintController, style: const TextStyle(color: Colors.white), decoration: _inputDecoration('Quality Complaint Details', isRequired: false)),
                          const SizedBox(height: 16),
                          TextFormField(controller: _promotionalActivityController, style: const TextStyle(color: Colors.white), decoration: _inputDecoration('Promotional Activity Details', isRequired: false)),
                          const SizedBox(height: 16),
                          TextFormField(controller: _channelPartnerVisitController, style: const TextStyle(color: Colors.white), decoration: _inputDecoration('Channel Partner Visit Details', isRequired: false)),
                          const SizedBox(height: 24),
                          
                          ElevatedButton(
                            onPressed: _isSubmitting ? null : _submitTvr,
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 50),
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white
                            ),
                            child: _isSubmitting
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text('SUBMIT & CHECK-OUT WITH PHOTO', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
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