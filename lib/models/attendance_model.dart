// file: lib/models/attendance_model.dart
import 'dart:convert';

Attendance attendanceFromJson(String str) => Attendance.fromJson(json.decode(str));

class Attendance {
  final String id;
  final int userId;
  final DateTime attendanceDate;
  final String? checkInTime; // Example: "09:05:32"
  final String? checkOutTime; // Example: "18:02:11"
  final String? status; // e.g., "Present", "On Leave"
  final DateTime createdAt;
  final DateTime updatedAt;

  Attendance({
    required this.id,
    required this.userId,
    required this.attendanceDate,
    this.checkInTime,
    this.checkOutTime,
    this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: json['id'],
      userId: json['userId'],
      attendanceDate: DateTime.parse(json['attendanceDate']),
      checkInTime: json['checkInTime'],
      checkOutTime: json['checkOutTime'],
      status: json['status'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}