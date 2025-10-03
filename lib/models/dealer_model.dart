// file: lib/models/dealer_model.dart

class Dealer {
  final String id;
  final int? userId;
  final String type;
  final String? parentDealerId;
  final String name;
  final String region;
  final String area;
  final String phoneNo;
  final String address;
  final String? pinCode;
  final double? latitude;
  final double? longitude;
  final DateTime? dateOfBirth;
  final DateTime? anniversaryDate;
  final double totalPotential;
  final double bestPotential;
  final List<String> brandSelling;
  final String feedbacks;
  final String? remarks;
  final DateTime createdAt;
  final DateTime updatedAt;

  Dealer({
    required this.id,
    this.userId,
    required this.type,
    this.parentDealerId,
    required this.name,
    required this.region,
    required this.area,
    required this.phoneNo,
    required this.address,
    this.pinCode,
    this.latitude,
    this.longitude,
    this.dateOfBirth,
    this.anniversaryDate,
    required this.totalPotential,
    required this.bestPotential,
    required this.brandSelling,
    required this.feedbacks,
    this.remarks,
    required this.createdAt,
    required this.updatedAt,
  });

  /// This factory now reads snake_case keys from the server's JSON response.
  factory Dealer.fromJson(Map<String, dynamic> json) {
    return Dealer(
      id: json['id'],
      userId: json['user_id'], // ✅ Fixed
      type: json['type'],
      parentDealerId: json['parent_dealer_id'], // ✅ Fixed
      name: json['name'],
      region: json['region'],
      area: json['area'],
      phoneNo: json['phone_no'], // ✅ Fixed
      address: json['address'],
      pinCode: json['pinCode'], // Unchanged (was already correct in schema)
      latitude: double.tryParse(json['latitude']?.toString() ?? ''),
      longitude: double.tryParse(json['longitude']?.toString() ?? ''),
      dateOfBirth: json['dateOfBirth'] != null ? DateTime.parse(json['dateOfBirth']) : null, // Unchanged
      anniversaryDate: json['anniversaryDate'] != null ? DateTime.parse(json['anniversaryDate']) : null, // Unchanged
      totalPotential: double.parse(json['total_potential'].toString()), // ✅ Fixed
      bestPotential: double.parse(json['best_potential'].toString()), // ✅ Fixed
      brandSelling: List<String>.from(json['brand_selling'] ?? []), // ✅ Fixed
      feedbacks: json['feedbacks'],
      remarks: json['remarks'],
      createdAt: DateTime.parse(json['created_at']), // ✅ Fixed
      updatedAt: DateTime.parse(json['updated_at']), // ✅ Fixed
    );
  }

  /// This method remains unchanged. It sends camelCase keys TO the server,
  /// which is what Drizzle and your server-side code expect for creating new entries.
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'type': type,
      'parentDealerId': parentDealerId,
      'name': name,
      'region': region,
      'area': area,
      'phoneNo': phoneNo,
      'address': address,
      'pinCode': pinCode,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'anniversaryDate': anniversaryDate?.toIso8601String(),
      'totalPotential': totalPotential,
      'bestPotential': bestPotential,
      'brandSelling': brandSelling,
      'feedbacks': feedbacks,
      'remarks': remarks,
    };
  }
}