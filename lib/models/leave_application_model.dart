// file: lib/models/leave_application_model.dart
import 'dart:convert';

LeaveApplication leaveApplicationFromJson(String str) => LeaveApplication.fromJson(json.decode(str));
String leaveApplicationToJson(LeaveApplication data) => json.encode(data.toJson());

class LeaveApplication {
  final String? id;
  final int userId;
  final String leaveType;
  final DateTime startDate;
  final DateTime endDate;
  final String reason;
  final String status;
  final String? adminRemarks;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  LeaveApplication({
    this.id,
    required this.userId,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.reason,
    required this.status,
    this.adminRemarks,
    this.createdAt,
    this.updatedAt,
  });

  factory LeaveApplication.fromJson(Map<String, dynamic> json) => LeaveApplication(
        id: json["id"],
        userId: json["userId"],
        leaveType: json["leaveType"],
        startDate: DateTime.parse(json["startDate"]),
        endDate: DateTime.parse(json["endDate"]),
        reason: json["reason"],
        status: json["status"],
        adminRemarks: json["adminRemarks"],
        createdAt: json["createdAt"] == null ? null : DateTime.parse(json["createdAt"]),
        updatedAt: json["updatedAt"] == null ? null : DateTime.parse(json["updatedAt"]),
      );

  /// Converts the object into a Map for creating a new application.
  /// Note: id, adminRemarks, createdAt, and updatedAt are omitted as they are handled by the server.
  Map<String, dynamic> toJson() => {
        "userId": userId,
        "leaveType": leaveType,
        "startDate": startDate.toIso8601String(),
        "endDate": endDate.toIso8601String(),
        "reason": reason,
        "status": status, // Status is required by the server, e.g., "Pending"
      };
}