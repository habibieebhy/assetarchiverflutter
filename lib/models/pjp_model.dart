class Pjp {
  final String id;
  final int userId;
  final int createdById;
  final DateTime planDate;
  final String status;
  final String areaToBeVisited;
  final String? description;
  final String? dealerName;
  final DateTime createdAt;
  final DateTime updatedAt;

  Pjp({
    required this.id,
    required this.userId,
    required this.createdById,
    required this.planDate,
    required this.status,
    required this.areaToBeVisited,
    this.dealerName,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  /// ✅ Handles both camelCase and snake_case from server
  factory Pjp.fromJson(Map<String, dynamic> json) {
    return Pjp(
      id: json['id']?.toString() ?? '',
      userId: json['userId'] ?? 0,
      createdById: json['createdById'] ?? 0,
      planDate: DateTime.tryParse(json['planDate'] ?? '') ?? DateTime.now(),
      status: json['status'] ?? '',
      areaToBeVisited: json['areaToBeVisited'] ?? '',
      dealerName: json['dealerName'] ?? json['dealer_name'],
      description: json['description'],
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }

  /// ✅ Proper copyWith
  Pjp copyWith({
    String? id,
    int? userId,
    int? createdById,
    DateTime? planDate,
    String? status,
    String? areaToBeVisited,
    String? description,
    String? dealerName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Pjp(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      createdById: createdById ?? this.createdById,
      planDate: planDate ?? this.planDate,
      status: status ?? this.status,
      areaToBeVisited: areaToBeVisited ?? this.areaToBeVisited,
      description: description ?? this.description,
      dealerName: dealerName ?? this.dealerName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// ✅ Matches server camelCase schema
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'createdById': createdById,
      'planDate': planDate.toIso8601String().split('T').first,
      'status': status,
      'areaToBeVisited': areaToBeVisited,
      'description': description,
      'dealerName': dealerName,
    };
  }
}
