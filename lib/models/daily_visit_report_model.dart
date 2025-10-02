// file: lib/models/daily_visit_report_model.dart
import 'dart:convert';

DailyVisitReport dailyVisitReportFromJson(String str) => DailyVisitReport.fromJson(json.decode(str));

class DailyVisitReport {
  final String id;
  final int userId;
  final DateTime reportDate;
  final String? dealerType;
  final String? visitType;
  // Assuming other relevant fields might exist
  final String? notes; 
  final DateTime createdAt;
  final DateTime updatedAt;

  DailyVisitReport({
    required this.id,
    required this.userId,
    required this.reportDate,
    this.dealerType,
    this.visitType,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DailyVisitReport.fromJson(Map<String, dynamic> json) {
    return DailyVisitReport(
      id: json['id'],
      userId: json['userId'],
      reportDate: DateTime.parse(json['reportDate']),
      dealerType: json['dealerType'],
      visitType: json['visitType'],
      notes: json['notes'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'reportDate': reportDate.toIso8601String(),
      'dealerType': dealerType,
      'visitType': visitType,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}