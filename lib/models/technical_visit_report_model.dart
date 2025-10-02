// file: lib/models/technical_visit_report_model.dart
import 'dart:convert';

TechnicalVisitReport technicalVisitReportFromJson(String str) => TechnicalVisitReport.fromJson(json.decode(str));

class TechnicalVisitReport {
  final String id;
  final int userId;
  final DateTime reportDate;
  final String? visitType;
  final String? serviceType;
  // Assuming other relevant fields might exist
  final String? details;
  final DateTime createdAt;
  final DateTime updatedAt;

  TechnicalVisitReport({
    required this.id,
    required this.userId,
    required this.reportDate,
    this.visitType,
    this.serviceType,
    this.details,
    required this.createdAt,
    required this.updatedAt,

  });

  factory TechnicalVisitReport.fromJson(Map<String, dynamic> json) {
    return TechnicalVisitReport(
      id: json['id'],
      userId: json['userId'],
      reportDate: DateTime.parse(json['reportDate']),
      visitType: json['visitType'],
      serviceType: json['serviceType'],
      details: json['details'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'reportDate': reportDate.toIso8601String(),
      'visitType': visitType,
      'serviceType': serviceType,
      'details': details,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}