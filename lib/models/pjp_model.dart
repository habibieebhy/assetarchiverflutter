

class Pjp {
  final String id;
  final int userId;
  final int createdById;
  final DateTime planDate;
  final String status;
  final String areaToBeVisited;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  Pjp({
    required this.id,
    required this.userId,
    required this.createdById,
    required this.planDate,
    required this.status,
    required this.areaToBeVisited,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  /// ✅ FINAL FIX: Reverted to camelCase to match the server's response.
  factory Pjp.fromJson(Map<String, dynamic> json) {
    return Pjp(
      id: json['id'] ?? '',
      userId: json['userId'] ?? 0,
      createdById: json['createdById'] ?? 0,
      planDate: DateTime.tryParse(json['planDate'] ?? '') ?? DateTime.now(),
      status: json['status'] ?? '',
      areaToBeVisited: json['areaToBeVisited'] ?? '',
      description: json['description'],
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }

  Pjp copyWith() {
    return Pjp(
      id: id,
      userId: userId,
      createdById: createdById,
      planDate: planDate,
      status: status,
      areaToBeVisited: areaToBeVisited,
      description: description,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// ✅ FINAL FIX: Reverted to camelCase to match the server's validation schema.
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