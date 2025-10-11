// file: lib/models/technical_visit_report_model.dart
import 'dart:convert';

TechnicalVisitReport technicalVisitReportFromJson(String str) => TechnicalVisitReport.fromJson(json.decode(str));
String technicalVisitReportToJson(TechnicalVisitReport data) => json.encode(data.toJson());

class TechnicalVisitReport {
    final String? id;
    final int userId;
    final DateTime reportDate;
    final String visitType;
    final String siteNameConcernedPerson;
    final String phoneNo;
    final String? emailId;
    final String clientsRemarks;
    final String salespersonRemarks;
    final DateTime checkInTime;
    final DateTime? checkOutTime;
    final String? inTimeImageUrl;
    final String? outTimeImageUrl;
    final List<String> siteVisitBrandInUse;
    final String? siteVisitStage;
    final String? conversionFromBrand;
    final double? conversionQuantityValue;
    final String? conversionQuantityUnit;
    final String? associatedPartyName;
    final List<String> influencerType;
    final String? serviceType;
    final String? qualityComplaint;
    final String? promotionalActivity;
    final String? channelPartnerVisit;
    final DateTime? createdAt;
    final DateTime? updatedAt;

    TechnicalVisitReport({
        this.id,
        required this.userId,
        required this.reportDate,
        required this.visitType,
        required this.siteNameConcernedPerson,
        required this.phoneNo,
        this.emailId,
        required this.clientsRemarks,
        required this.salespersonRemarks,
        required this.checkInTime,
        this.checkOutTime,
        this.inTimeImageUrl,
        this.outTimeImageUrl,
        required this.siteVisitBrandInUse,
        this.siteVisitStage,
        this.conversionFromBrand,
        this.conversionQuantityValue,
        this.conversionQuantityUnit,
        this.associatedPartyName,
        required this.influencerType,
        this.serviceType,
        this.qualityComplaint,
        this.promotionalActivity,
        this.channelPartnerVisit,
        this.createdAt,
        this.updatedAt,
    });

    factory TechnicalVisitReport.fromJson(Map<String, dynamic> json) => TechnicalVisitReport(
        id: json["id"],
        userId: json["userId"],
        reportDate: DateTime.parse(json["reportDate"]),
        visitType: json["visitType"],
        siteNameConcernedPerson: json["siteNameConcernedPerson"],
        phoneNo: json["phoneNo"],
        emailId: json["emailId"],
        clientsRemarks: json["clientsRemarks"],
        salespersonRemarks: json["salespersonRemarks"],
        checkInTime: DateTime.parse(json["checkInTime"]),
        checkOutTime: json["checkOutTime"] == null ? null : DateTime.parse(json["checkOutTime"]),
        inTimeImageUrl: json["inTimeImageUrl"],
        outTimeImageUrl: json["outTimeImageUrl"],
        siteVisitBrandInUse: List<String>.from(json["siteVisitBrandInUse"].map((x) => x)),
        siteVisitStage: json["siteVisitStage"],
        conversionFromBrand: json["conversionFromBrand"],
        conversionQuantityValue: json["conversionQuantityValue"] == null ? null : double.tryParse(json["conversionQuantityValue"].toString()),
        conversionQuantityUnit: json["conversionQuantityUnit"],
        associatedPartyName: json["associatedPartyName"],
        influencerType: List<String>.from(json["influencerType"].map((x) => x)),
        serviceType: json["serviceType"],
        qualityComplaint: json["qualityComplaint"],
        promotionalActivity: json["promotionalActivity"],
        channelPartnerVisit: json["channelPartnerVisit"],
        createdAt: json["createdAt"] == null ? null : DateTime.parse(json["createdAt"]),
        updatedAt: json["updatedAt"] == null ? null : DateTime.parse(json["updatedAt"]),
    );

    Map<String, dynamic> toJson() => {
        "userId": userId,
        "reportDate": reportDate.toIso8601String(),
        "visitType": visitType,
        "siteNameConcernedPerson": siteNameConcernedPerson,
        "phoneNo": phoneNo,
        "emailId": emailId,
        "clientsRemarks": clientsRemarks,
        "salespersonRemarks": salespersonRemarks,
        "checkInTime": checkInTime.toIso8601String(),
        "checkOutTime": checkOutTime?.toIso8601String(),
        "inTimeImageUrl": inTimeImageUrl,
        "outTimeImageUrl": outTimeImageUrl,
        "siteVisitBrandInUse": List<dynamic>.from(siteVisitBrandInUse.map((x) => x)),
        "siteVisitStage": siteVisitStage,
        "conversionFromBrand": conversionFromBrand,
        // --- FIX: Send as a string or null to match the server's Zod schema ---
        "conversionQuantityValue": conversionQuantityValue?.toString(),
        "conversionQuantityUnit": conversionQuantityUnit,
        "associatedPartyName": associatedPartyName,
        "influencerType": List<dynamic>.from(influencerType.map((x) => x)),
        "serviceType": serviceType,
        "qualityComplaint": qualityComplaint,
        "promotionalActivity": promotionalActivity,
        "channelPartnerVisit": channelPartnerVisit,
    };
}