

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

  /// ✅ FINAL FIX: Reverted to camelCase to match the server's response.
  factory Dealer.fromJson(Map<String, dynamic> json) {
    return Dealer(
      id: json['id'] ?? '',
      userId: json['userId'],
      type: json['type'] ?? '',
      parentDealerId: json['parentDealerId'],
      name: json['name'] ?? '',
      region: json['region'] ?? '',
      area: json['area'] ?? '',
      phoneNo: json['phoneNo'] ?? '',
      address: json['address'] ?? '',
      pinCode: json['pinCode'],
      latitude: double.tryParse(json['latitude']?.toString() ?? ''),
      longitude: double.tryParse(json['longitude']?.toString() ?? ''),
      dateOfBirth: json['dateOfBirth'] != null ? DateTime.tryParse(json['dateOfBirth']) : null,
      anniversaryDate: json['anniversaryDate'] != null ? DateTime.tryParse(json['anniversaryDate']) : null,
      totalPotential: double.tryParse(json['totalPotential'].toString()) ?? 0.0,
      bestPotential: double.tryParse(json['bestPotential'].toString()) ?? 0.0,
      brandSelling: List<String>.from(json['brandSelling'] ?? []),
      feedbacks: json['feedbacks'] ?? '',
      remarks: json['remarks'],
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }

  /// ✅ FINAL FIX: Reverted to camelCase to match the server's validation schema.
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