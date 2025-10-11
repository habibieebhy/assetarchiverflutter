// lib/models/daily_task_model.dart
import 'dart:convert';

DailyTask dailyTaskFromJson(String str) => DailyTask.fromJson(json.decode(str));
String dailyTaskToJson(DailyTask data) => json.encode(data.toJson());

class DailyTask {
    final String? id;
    final int userId;
    final int assignedByUserId;
    final DateTime taskDate;
    final String visitType;
    final String? relatedDealerId;
    final String? siteName;
    final String? description;
    final String status;
    final String? pjpId;
    final DateTime? createdAt;
    final DateTime? updatedAt;

    DailyTask({
        this.id,
        required this.userId,
        required this.assignedByUserId,
        required this.taskDate,
        required this.visitType,
        this.relatedDealerId,
        this.siteName,
        this.description,
        required this.status,
        this.pjpId,
        this.createdAt,
        this.updatedAt,
    });

    factory DailyTask.fromJson(Map<String, dynamic> json) => DailyTask(
        id: json["id"],
        userId: json["userId"],
        assignedByUserId: json["assignedByUserId"],
        taskDate: DateTime.parse(json["taskDate"]),
        visitType: json["visitType"],
        relatedDealerId: json["relatedDealerId"],
        siteName: json["siteName"],
        description: json["description"],
        status: json["status"],
        pjpId: json["pjpId"],
        createdAt: json["createdAt"] == null ? null : DateTime.parse(json["createdAt"]),
        updatedAt: json["updatedAt"] == null ? null : DateTime.parse(json["updatedAt"]),
    );

    /// Converts the object into a Map for creating a new task.
    Map<String, dynamic> toJson() => {
        "userId": userId,
        "assignedByUserId": assignedByUserId,
        "taskDate": taskDate.toIso8601String(),
        "visitType": visitType,
        "relatedDealerId": relatedDealerId,
        "siteName": siteName,
        "description": description,
        "status": status,
        "pjpId": pjpId,
    };
}