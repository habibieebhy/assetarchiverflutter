// file: lib/models/leave_application_model.dart

class LeaveApplication {
  final String id;
  final int userId;
  final String leaveType;
  final DateTime startDate;
  final DateTime endDate;
  final String? reason;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  LeaveApplication({
    required this.id,
    required this.userId,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    this.reason,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LeaveApplication.fromJson(Map<String, dynamic> json) {
    return LeaveApplication(
      id: json['id'],
      userId: json['userId'],
      leaveType: json['leaveType'],
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      reason: json['reason'],
      status: json['status'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  // --- THIS IS THE MISSING PART ---
  /// Converts the LeaveApplication object into a Map for creating a new application.
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'leaveType': leaveType,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'reason': reason,
      'status': status,
    };
  }
}