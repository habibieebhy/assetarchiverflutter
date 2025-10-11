// lib/screens/forms/create_dvr.dart
import 'dart:io';
import 'dart:ui';
import 'package:assetarchiverflutter/api/api_service.dart';
import 'package:assetarchiverflutter/models/daily_visit_report_model.dart';
import 'package:assetarchiverflutter/models/dealer_model.dart'; // You need this model
import 'package:assetarchiverflutter/models/employee_model.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class CreateDvrScreen extends StatefulWidget {
  final Employee employee;
  const CreateDvrScreen({super.key, required this.employee});

  @override
  State<CreateDvrScreen> createState() => _CreateDvrScreenState();
}

class _CreateDvrScreenState extends State<CreateDvrScreen> {
  // Keys & Services
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();
  final _imagePicker = ImagePicker();

  // Form Controllers
  final _dealerTotalPotentialController = TextEditingController();
  final _dealerBestPotentialController = TextEditingController();
  final _brandSellingController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _contactPersonPhoneNoController = TextEditingController();
  final _todayOrderMtController = TextEditingController();
  final _todayCollectionRupeesController = TextEditingController();
  final _overdueAmountController = TextEditingController();
  final _feedbacksController = TextEditingController();
  final _solutionBySalespersonController = TextEditingController();
  final _anyRemarksController = TextEditingController();

  // State Management Variables
  bool _isSubmitting = false;
  bool _isLoadingDealers = true;
  bool _isUploadingImage = false;

  // Data Holders for the Workflow
  List<Dealer> _allDealers = [];
  Dealer? _selectedDealer;
  String? _selectedVisitType;
  DateTime? _checkInTime;
  File? _inTimeImageFile;
  String? _inTimeImageUrl;

  @override
  void initState() {
    super.initState();
    _fetchDealersForDropdown();
  }

  @override
  void dispose() {
    _dealerTotalPotentialController.dispose();
    _dealerBestPotentialController.dispose();
    _brandSellingController.dispose();
    _contactPersonController.dispose();
    _contactPersonPhoneNoController.dispose();
    _todayOrderMtController.dispose();
    _todayCollectionRupeesController.dispose();
    _overdueAmountController.dispose();
    _feedbacksController.dispose();
    _solutionBySalespersonController.dispose();
    _anyRemarksController.dispose();
    super.dispose();
  }

  // --- Data Fetching ---
  Future<void> _fetchDealersForDropdown() async {
    try {
      final dealers = await _apiService.fetchDealers(userId: int.tryParse(widget.employee.id));
      if (mounted) {
        setState(() {
          _allDealers = dealers;
          _isLoadingDealers = false;
        });
      }
    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load dealers: $e'), backgroundColor: Colors.red),
        );
        setState(() => _isLoadingDealers = false);
      }
    }
  }

  // --- Workflow Logic ---
  void _onDealerSelected(Dealer? dealer) {
    if (dealer == null) return;
    setState(() {
      _selectedDealer = dealer;
      // Auto-fill fields from the selected dealer object
      _dealerTotalPotentialController.text = dealer.totalPotential.toString(); // <-- FIXED
      _dealerBestPotentialController.text = dealer.bestPotential.toString(); // <-- FIXED
      _brandSellingController.text = dealer.brandSelling.join(', ');
      _contactPersonController.text = dealer.name; // Assuming contact person is the dealer name initially
      _contactPersonPhoneNoController.text = dealer.phoneNo ; // Safer assignment
    });
  }

  Future<void> _handleCheckIn() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    setState(() => _isUploadingImage = true);
    try {
      // 1. Pick Image
      final pickedFile = await _imagePicker.pickImage(source: ImageSource.camera, imageQuality: 70, maxWidth: 1024);
      if (pickedFile == null) {
        // If user cancels, stop the loading indicator
        if(mounted) setState(() => _isUploadingImage = false);
        return;
      }
      
      final imageFile = File(pickedFile.path);
      if (mounted) setState(() => _inTimeImageFile = imageFile);

      // 2. Upload Image
      final imageUrl = await _apiService.uploadImageToR2(imageFile);

      // 3. Set State
      if (mounted) {
        setState(() {
          _checkInTime = DateTime.now();
          _inTimeImageUrl = imageUrl;
        });
        scaffoldMessenger.showSnackBar(const SnackBar(
          content: Text('Checked-In successfully.'), backgroundColor: Colors.green,
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

  Future<void> _submitDvr() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    if (!_formKey.currentState!.validate()) {
      scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Please fill all required fields.'), backgroundColor: Colors.orange));
      return;
    }
    
    setState(() => _isSubmitting = true);

    try {
      // 1. Capture Check-Out Image & Location
      final pickedFile = await _imagePicker.pickImage(source: ImageSource.camera, imageQuality: 70, maxWidth: 1024);
      if (pickedFile == null) {
        scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Check-out photo is required to submit.'), backgroundColor: Colors.orange));
        setState(() => _isSubmitting = false);
        return;
      }
      final outTimeImageFile = File(pickedFile.path);
      final outTimeImageUrl = await _apiService.uploadImageToR2(outTimeImageFile);

      // 2. Verify Location
      final currentPosition = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final dealerLatitude = _selectedDealer!.latitude;
      final dealerLongitude = _selectedDealer!.longitude;

      if (dealerLatitude == null || dealerLongitude == null) {
        throw Exception("Selected dealer does not have location data.");
      }

      final distance = Geolocator.distanceBetween(
        currentPosition.latitude, currentPosition.longitude,
        dealerLatitude, dealerLongitude
      );

      // Allow submission if within 200 meters
      if (distance > 200) {
        throw Exception("Submission failed. You are ${distance.toStringAsFixed(0)} meters away from the dealer's location.");
      }
      
      final checkOutTime = DateTime.now();

      // 3. Prepare DVR Object
      String? mainDealerName = _selectedDealer!.parentDealerId == null 
          ? _selectedDealer!.name 
          : _allDealers.firstWhere((d) => d.id == _selectedDealer!.parentDealerId, orElse: () => _selectedDealer!).name;
      
      String? subDealerName = _selectedDealer!.parentDealerId != null ? _selectedDealer!.name : null;

      final dvrReport = DailyVisitReport(
        userId: int.parse(widget.employee.id),
        reportDate: _checkInTime!,
        dealerType: _selectedDealer!.type,
        dealerName: mainDealerName,
        subDealerName: subDealerName,
        location: _selectedDealer!.address,
        latitude: currentPosition.latitude, // Use precise check-out location
        longitude: currentPosition.longitude,
        visitType: _selectedVisitType!,
        dealerTotalPotential: double.parse(_dealerTotalPotentialController.text),
        dealerBestPotential: double.parse(_dealerBestPotentialController.text),
        brandSelling: _brandSellingController.text.split(',').map((e) => e.trim()).where((s) => s.isNotEmpty).toList(),
        contactPerson: _contactPersonController.text.isNotEmpty ? _contactPersonController.text : null,
        contactPersonPhoneNo: _contactPersonPhoneNoController.text.isNotEmpty ? _contactPersonPhoneNoController.text : null,
        todayOrderMt: double.parse(_todayOrderMtController.text),
        todayCollectionRupees: double.parse(_todayCollectionRupeesController.text),
        overdueAmount: _overdueAmountController.text.isNotEmpty ? double.tryParse(_overdueAmountController.text) : null,
        feedbacks: _feedbacksController.text,
        solutionBySalesperson: _solutionBySalespersonController.text.isNotEmpty ? _solutionBySalespersonController.text : null,
        anyRemarks: _anyRemarksController.text.isNotEmpty ? _anyRemarksController.text : null,
        checkInTime: _checkInTime!,
        checkOutTime: checkOutTime,
        inTimeImageUrl: _inTimeImageUrl,
        outTimeImageUrl: outTimeImageUrl,
      );

      // 4. Submit to API
      await _apiService.createDvr(dvrReport);

      scaffoldMessenger.showSnackBar(const SnackBar(content: Text('DVR submitted successfully!'), backgroundColor: Colors.green));
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
  InputDecoration _inputDecoration(String label, {bool isRequired = true, bool readOnly = false}) {
    return InputDecoration(
      labelText: '$label${isRequired ? '*' : ''}',
      labelStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: readOnly ? Colors.white10 : Colors.transparent,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white30), borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white), borderRadius: BorderRadius.circular(12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // For the "floating" effect
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
                            const Text('Daily Visit Report', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.white),
                              onPressed: () => Navigator.of(context).pop(),
                            )
                          ],
                        ),
                        const Divider(color: Colors.white24, height: 30),

                        // --- Step 1: Dealer Selection ---
                        if (_checkInTime == null) ...[
                          _isLoadingDealers
                              ? const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator(color: Colors.white)))
                              : DropdownButtonFormField<Dealer>(
                                  initialValue: _selectedDealer,
                                  isExpanded: true,
                                  hint: const Text('Select Dealer/Sub-dealer*', style: TextStyle(color: Colors.white70)),
                                  dropdownColor: const Color(0xFF0D47A1),
                                  style: const TextStyle(color: Colors.white),
                                  decoration: _inputDecoration('Dealer/Sub-dealer'),
                                  items: _allDealers.map((dealer) => DropdownMenuItem(value: dealer, child: Text(dealer.name, overflow: TextOverflow.ellipsis))).toList(),
                                  onChanged: _onDealerSelected,
                                  validator: (v) => v == null ? 'Please select a dealer' : null,
                                ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _selectedDealer == null || _isUploadingImage ? null : _handleCheckIn,
                            icon: _isUploadingImage ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.camera_alt),
                            label: const Text('CHECK-IN WITH PHOTO'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 50),
                              backgroundColor: Colors.amber,
                              foregroundColor: Colors.black,
                            ),
                          ),
                        ],
                        
                        // --- Step 2: Form Filling (visible after check-in) ---
                        if (_checkInTime != null) ...[
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundImage: _inTimeImageFile != null ? FileImage(_inTimeImageFile!) : null,
                              child: _inTimeImageFile == null ? const Icon(Icons.check_circle, color: Colors.green) : null,
                            ),
                            title: Text(_selectedDealer?.name ?? 'Dealer', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            subtitle: Text('Checked-In at ${DateFormat('hh:mm a').format(_checkInTime!)}', style: const TextStyle(color: Colors.white70)),
                            trailing: const Icon(Icons.check_circle, color: Colors.green, size: 32),
                          ),
                          const Divider(color: Colors.white24, height: 30),

                          DropdownButtonFormField<String>(
                            initialValue: _selectedVisitType,
                            dropdownColor: const Color(0xFF0D47A1),
                            style: const TextStyle(color: Colors.white),
                            decoration: _inputDecoration('Visit Type'),
                            items: ['Routine', 'Follow-up', 'Complaint', 'New Lead']
                                .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                                .toList(),
                            onChanged: (value) => setState(() => _selectedVisitType = value),
                            validator: (v) => v == null ? 'Please select a visit type' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(controller: _dealerTotalPotentialController, readOnly: true, style: const TextStyle(color: Colors.white70), decoration: _inputDecoration('Dealer Total Potential', readOnly: true)),
                          const SizedBox(height: 16),
                          TextFormField(controller: _dealerBestPotentialController, readOnly: true, style: const TextStyle(color: Colors.white70), decoration: _inputDecoration('Dealer Best Potential', readOnly: true)),
                          const SizedBox(height: 16),
                          TextFormField(controller: _brandSellingController, readOnly: true, style: const TextStyle(color: Colors.white70), decoration: _inputDecoration('Brands Selling', readOnly: true)),
                          const SizedBox(height: 16),
                          TextFormField(controller: _contactPersonController, style: const TextStyle(color: Colors.white), decoration: _inputDecoration('Contact Person', isRequired: false)),
                          const SizedBox(height: 16),
                          TextFormField(controller: _contactPersonPhoneNoController, keyboardType: TextInputType.phone, style: const TextStyle(color: Colors.white), decoration: _inputDecoration('Contact Phone', isRequired: false)),
                          const SizedBox(height: 16),
                          TextFormField(controller: _todayOrderMtController, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: _inputDecoration('Today\'s Order (MT)'), validator: (v) => v!.isEmpty ? 'Field is required' : null),
                          const SizedBox(height: 16),
                          TextFormField(controller: _todayCollectionRupeesController, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: _inputDecoration('Today\'s Collection (₹)'), validator: (v) => v!.isEmpty ? 'Field is required' : null),
                          const SizedBox(height: 16),
                          TextFormField(controller: _overdueAmountController, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: _inputDecoration('Overdue Amount (₹)', isRequired: false)),
                          const SizedBox(height: 16),
                          TextFormField(controller: _feedbacksController, style: const TextStyle(color: Colors.white), decoration: _inputDecoration('Feedbacks'), maxLines: 3, validator: (v) => v!.isEmpty ? 'Feedback is required' : null),
                          const SizedBox(height: 16),
                          TextFormField(controller: _solutionBySalespersonController, style: const TextStyle(color: Colors.white), decoration: _inputDecoration('Solution by Salesperson', isRequired: false), maxLines: 3),
                          const SizedBox(height: 16),
                          TextFormField(controller: _anyRemarksController, style: const TextStyle(color: Colors.white), decoration: _inputDecoration('Any Other Remarks', isRequired: false), maxLines: 3),
                          const SizedBox(height: 24),
                          
                          ElevatedButton(
                            onPressed: _isSubmitting ? null : _submitDvr,
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