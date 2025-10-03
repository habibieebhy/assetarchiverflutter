// file: lib/models/pjp_model.dart
import './dealer_model.dart';

class Pjp {
  final String id;
  final int userId;
  final int createdById;
  final DateTime planDate;
  final String status;
  final String? description;
  final String? dealerId;
  final Dealer? dealer;

  String get displayArea {
    if (dealer != null) {
      return '${dealer!.name}, ${dealer!.address}';
    }
    return 'No Dealer Assigned';
  }

  Pjp({
    required this.id,
    required this.userId,
    required this.createdById,
    required this.planDate,
    required this.status,
    this.description,
    this.dealerId,
    this.dealer,
  });

  factory Pjp.fromJson(Map<String, dynamic> json) {
    return Pjp(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? 0,
      createdById: json['created_by_id'] ?? 0,
      planDate: DateTime.tryParse(json['plan_date'] ?? '') ?? DateTime.now(),
      status: json['status'] ?? '',
      description: json['description'],
      dealerId: json['dealer_id'],
      dealer: null,
    );
  }

  /// ✅ FIXED: Removed unnecessary 'this.' qualifiers for cleaner code.
  Pjp copyWith({ Dealer? dealer }) {
    return Pjp(
      id: id,
      userId: userId,
      createdById: createdById,
      planDate: planDate,
      status: status,
      description: description,
      dealerId: dealerId,
      // 'this.' is still needed here to distinguish the class property
      // from the 'dealer' parameter being passed into the method.
      dealer: dealer ?? this.dealer,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'createdById': createdById,
      'planDate': planDate.toIso8601String().split('T').first,
      'status': status,
      'description': description,
      'dealerId': dealerId,
    };
  }
}