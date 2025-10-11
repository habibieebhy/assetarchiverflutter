// file: lib/models/daily_visit_report_model.dart
import 'dart:convert';

DailyVisitReport dailyVisitReportFromJson(String str) => DailyVisitReport.fromJson(json.decode(str));
String dailyVisitReportToJson(DailyVisitReport data) => json.encode(data.toJson());

class DailyVisitReport {
    final String? id;
    final int userId;
    final DateTime reportDate;
    final String dealerType;
    final String? dealerName;
    final String? subDealerName;
    final String location;
    final double latitude;
    final double longitude;
    final String visitType;
    final double dealerTotalPotential;
    final double dealerBestPotential;
    final List<String> brandSelling;
    final String? contactPerson;
    final String? contactPersonPhoneNo;
    final double todayOrderMt;
    final double todayCollectionRupees;
    final double? overdueAmount;
    final String feedbacks;
    final String? solutionBySalesperson;
    final String? anyRemarks;
    final DateTime checkInTime;
    final DateTime? checkOutTime;
    final String? inTimeImageUrl;
    final String? outTimeImageUrl;
    final DateTime? createdAt;
    final DateTime? updatedAt;

    DailyVisitReport({
        this.id,
        required this.userId,
        required this.reportDate,
        required this.dealerType,
        this.dealerName,
        this.subDealerName,
        required this.location,
        required this.latitude,
        required this.longitude,
        required this.visitType,
        required this.dealerTotalPotential,
        required this.dealerBestPotential,
        required this.brandSelling,
        this.contactPerson,
        this.contactPersonPhoneNo,
        required this.todayOrderMt,
        required this.todayCollectionRupees,
        this.overdueAmount,
        required this.feedbacks,
        this.solutionBySalesperson,
        this.anyRemarks,
        required this.checkInTime,
        this.checkOutTime,
        this.inTimeImageUrl,
        this.outTimeImageUrl,
        this.createdAt,
        this.updatedAt,
    });

    factory DailyVisitReport.fromJson(Map<String, dynamic> json) => DailyVisitReport(
        id: json["id"],
        userId: json["userId"],
        reportDate: DateTime.parse(json["reportDate"]),
        dealerType: json["dealerType"],
        dealerName: json["dealerName"],
        subDealerName: json["subDealerName"],
        location: json["location"],
        latitude: double.tryParse(json["latitude"].toString()) ?? 0.0,
        longitude: double.tryParse(json["longitude"].toString()) ?? 0.0,
        visitType: json["visitType"],
        dealerTotalPotential: double.tryParse(json["dealerTotalPotential"].toString()) ?? 0.0,
        dealerBestPotential: double.tryParse(json["dealerBestPotential"].toString()) ?? 0.0,
        brandSelling: List<String>.from(json["brandSelling"].map((x) => x)),
        contactPerson: json["contactPerson"],
        contactPersonPhoneNo: json["contactPersonPhoneNo"],
        todayOrderMt: double.tryParse(json["todayOrderMt"].toString()) ?? 0.0,
        todayCollectionRupees: double.tryParse(json["todayCollectionRupees"].toString()) ?? 0.0,
        overdueAmount: json["overdueAmount"] == null ? null : double.tryParse(json["overdueAmount"].toString()),
        feedbacks: json["feedbacks"],
        solutionBySalesperson: json["solutionBySalesperson"],
        anyRemarks: json["anyRemarks"],
        checkInTime: DateTime.parse(json["checkInTime"]),
        checkOutTime: json["checkOutTime"] == null ? null : DateTime.parse(json["checkOutTime"]),
        inTimeImageUrl: json["inTimeImageUrl"],
        outTimeImageUrl: json["outTimeImageUrl"],
        createdAt: json["createdAt"] == null ? null : DateTime.parse(json["createdAt"]),
        updatedAt: json["updatedAt"] == null ? null : DateTime.parse(json["updatedAt"]),
    );

    Map<String, dynamic> toJson() => {
        // id, createdAt, and updatedAt are handled by the server, so we don't send them
        "userId": userId,
        "reportDate": reportDate.toIso8601String(),
        "dealerType": dealerType,
        "dealerName": dealerName,
        "subDealerName": subDealerName,
        "location": location,
        "latitude": latitude,
        "longitude": longitude,
        "visitType": visitType,
        "dealerTotalPotential": dealerTotalPotential,
        "dealerBestPotential": dealerBestPotential,
        "brandSelling": List<dynamic>.from(brandSelling.map((x) => x)),
        "contactPerson": contactPerson,
        "contactPersonPhoneNo": contactPersonPhoneNo,
        "todayOrderMt": todayOrderMt,
        "todayCollectionRupees": todayCollectionRupees,
        "overdueAmount": overdueAmount,
        "feedbacks": feedbacks,
        "solutionBySalesperson": solutionBySalesperson,
        "anyRemarks": anyRemarks,
        "checkInTime": checkInTime.toIso8601String(),
        "checkOutTime": checkOutTime?.toIso8601String(),
        "inTimeImageUrl": inTimeImageUrl,
        "outTimeImageUrl": outTimeImageUrl,
    };
}