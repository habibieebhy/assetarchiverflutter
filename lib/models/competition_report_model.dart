// lib/models/competition_report_model.dart
import 'dart:convert';

CompetitionReport competitionReportFromJson(String str) => CompetitionReport.fromJson(json.decode(str));
String competitionReportToJson(CompetitionReport data) => json.encode(data.toJson());

class CompetitionReport {
    final String? id;
    final int userId;
    final DateTime reportDate;
    final String brandName;
    final String billing;
    final String nod;
    final String retail;
    final String schemesYesNo;
    final double avgSchemeCost;
    final String? remarks;
    final DateTime? createdAt;
    final DateTime? updatedAt;

    CompetitionReport({
        this.id,
        required this.userId,
        required this.reportDate,
        required this.brandName,
        required this.billing,
        required this.nod,
        required this.retail,
        required this.schemesYesNo,
        required this.avgSchemeCost,
        this.remarks,
        this.createdAt,
        this.updatedAt,
    });

    factory CompetitionReport.fromJson(Map<String, dynamic> json) => CompetitionReport(
        id: json["id"],
        userId: json["userId"],
        reportDate: DateTime.parse(json["reportDate"]),
        brandName: json["brandName"],
        billing: json["billing"],
        nod: json["nod"],
        retail: json["retail"],
        schemesYesNo: json["schemesYesNo"],
        avgSchemeCost: double.parse(json["avgSchemeCost"].toString()),
        remarks: json["remarks"],
        createdAt: json["createdAt"] == null ? null : DateTime.parse(json["createdAt"]),
        updatedAt: json["updatedAt"] == null ? null : DateTime.parse(json["updatedAt"]),
    );

    /// Converts the object into a Map for creating a new report.
    Map<String, dynamic> toJson() => {
        "userId": userId,
        "reportDate": reportDate.toIso8601String(),
        "brandName": brandName,
        "billing": billing,
        "nod": nod,
        "retail": retail,
        "schemesYesNo": schemesYesNo,
        // Server expects a numeric string, so we convert the double
        "avgSchemeCost": avgSchemeCost.toString(),
        "remarks": remarks,
    };
}