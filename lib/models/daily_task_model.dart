// file: lib/models/daily_task_model.dart

class DailyTask {
  final String id;
  final DateTime taskDate;
  final String? status;
  final int userId;
  final int assignedByUserId;
  final String? visitType;
  final String? relatedDealerId;
  final String? pjpId;
  final DateTime createdAt;
  final DateTime updatedAt;

  DailyTask({
    required this.id,
    required this.taskDate,
    this.status,
    required this.userId,
    required this.assignedByUserId,
    this.visitType,
    this.relatedDealerId,
    this.pjpId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DailyTask.fromJson(Map<String, dynamic> json) {
    return DailyTask(
      id: json['id'],
      taskDate: DateTime.parse(json['taskDate']),
      status: json['status'],
      userId: json['userId'],
      assignedByUserId: json['assignedByUserId'],
      visitType: json['visitType'],
      relatedDealerId: json['relatedDealerId'],
      pjpId: json['pjpId'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  // --- THIS IS THE MISSING PART ---
  /// Converts the DailyTask object into a Map for creating a new task.
  Map<String, dynamic> toJson() {
    return {
      'taskDate': taskDate.toIso8601String(),
      'status': status,
      'userId': userId,
      'assignedByUserId': assignedByUserId,
      'visitType': visitType,
      'relatedDealerId': relatedDealerId,
      'pjpId': pjpId,
    };
  }
}