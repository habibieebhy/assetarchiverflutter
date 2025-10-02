// file: lib/models/pjp_model.dart
import './dealer_model.dart';

class Pjp {
  final String id;
  final int userId;
  final int createdById;
  final DateTime planDate;
  final String status;
  final String areaToBeVisited;
  final String? description;
  
  // This is populated by the first API call from the PJP list
  final String? dealerId;
  
  // This is populated by our second API call (fetching the dealer)
  final Dealer? dealer; 

  Pjp({
    required this.id,
    required this.userId,
    required this.createdById,
    required this.planDate,
    required this.status,
    required this.areaToBeVisited,
    this.description,
    this.dealerId,
    this.dealer,
  });

  factory Pjp.fromJson(Map<String, dynamic> json) {
    return Pjp(
      id: json['id'],
      userId: json['userId'],
      createdById: json['createdById'],
      planDate: DateTime.parse(json['planDate']),
      status: json['status'],
      areaToBeVisited: json['areaToBeVisited'] ?? '', // Handle if null
      description: json['description'],
      // We assume the server is sending a dealerId with the PJP list
      dealerId: json['dealerId'], 
      dealer: null, // This will be fetched in the second step
    );
  }

  // Helper method to create a copy of a PJP with the full dealer info added
  Pjp copyWith({ Dealer? dealer }) {
    return Pjp(
      id: this.id,
      userId: this.userId,
      createdById: this.createdById,
      planDate: this.planDate,
      status: this.status,
      areaToBeVisited: this.areaToBeVisited,
      description: this.description,
      dealerId: this.dealerId,
      dealer: dealer ?? this.dealer,
    );
  }
  
  // This creates the JSON for the POST request, matching your server schema
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'createdById': createdById,
      'planDate': planDate.toIso8601String().split('T').first,
      'status': status,
      'areaToBeVisited': areaToBeVisited,
      'description': description,
    };
  }
}