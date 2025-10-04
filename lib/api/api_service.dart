import 'dart:convert';
import 'dart:developer' as dev;
import 'package:http/http.dart' as http;

// Import all model files
import '../models/dealer_model.dart';
import '../models/pjp_model.dart';
import '../models/daily_task_model.dart';
import '../models/leave_application_model.dart';
import '../models/attendance_model.dart';
import '../models/daily_visit_report_model.dart';
import '../models/technical_visit_report_model.dart';

class ApiService {
  static const String _baseUrl = 'https://myserverbymycoco.onrender.com';

  // --- GENERIC HELPERS ---

  Future<T> _get<T>(String endpoint, T Function(dynamic json) fromJson) async {
    final url = Uri.parse('$_baseUrl/api/$endpoint');
    dev.log('GET: $url', name: 'ApiService');
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 45));
      final jsonData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (jsonData['success'] == true && jsonData['data'] != null) {
          return fromJson(jsonData['data']);
        } else {
          throw Exception(jsonData['error'] ?? 'API returned success: false');
        }
      } else {
        throw Exception(jsonData['error'] ?? 'Failed to load data. Status: ${response.statusCode}');
      }
    } catch (e) {
      dev.log('API Error on GET $endpoint', error: e, name: 'ApiService');
      rethrow;
    }
  }

  Future<T> _post<T>(String endpoint, Map<String, dynamic> body, T Function(dynamic json) fromJson) async {
    final url = Uri.parse('$_baseUrl/api/$endpoint');
    dev.log('POST: $url', name: 'ApiService');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 45));
      
      final jsonData = jsonDecode(response.body);
      if (response.statusCode == 201 || response.statusCode == 200) {
        if (jsonData['success'] == true && jsonData['data'] != null) {
          return fromJson(jsonData['data']);
        } else {
          throw Exception(jsonData['error'] ?? 'API returned success: false');
        }
      } else {
        throw Exception(jsonData['error'] ?? 'Failed to create item. Status: ${response.statusCode}');
      }
    } catch (e) {
      dev.log('API Error on POST $endpoint', error: e, name: 'ApiService');
      rethrow;
    }
  }
  
  // --- NEW: GENERIC PATCH HELPER ---
  Future<T> _patch<T>(String endpoint, Map<String, dynamic> body, T Function(dynamic json) fromJson) async {
    final url = Uri.parse('$_baseUrl/api/$endpoint');
    dev.log('PATCH: $url', name: 'ApiService');
    try {
      final response = await http.patch(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 45));
      
      final jsonData = jsonDecode(response.body);
      if (response.statusCode == 200) {
        if (jsonData['success'] == true && jsonData['data'] != null) {
          return fromJson(jsonData['data']);
        } else {
          throw Exception(jsonData['error'] ?? 'API returned success: false');
        }
      } else {
        throw Exception(jsonData['error'] ?? 'Failed to update item. Status: ${response.statusCode}');
      }
    } catch (e) {
      dev.log('API Error on PATCH $endpoint', error: e, name: 'ApiService');
      rethrow;
    }
  }

  Future<void> _delete(String endpoint) async {
    final url = Uri.parse('$_baseUrl/api/$endpoint');
    dev.log('DELETE: $url', name: 'ApiService');
    try {
      final response = await http.delete(url).timeout(const Duration(seconds: 45));
      if (response.statusCode != 200 && response.statusCode != 204) {
        final jsonData = jsonDecode(response.body);
        throw Exception(jsonData['error'] ?? 'Failed to delete item. Status: ${response.statusCode}');
      }
    } catch (e) {
      dev.log('API Error on DELETE $endpoint', error: e, name: 'ApiService');
      rethrow;
    }
  }

  // --- GET METHODS ---

  Future<List<Dealer>> fetchDealers({String? region, String? area, String? type, int? userId}) async {
    final queryParams = <String, String>{
      if (region != null) 'region': region,
      if (area != null) 'area': area,
      if (type != null) 'type': type,
      if (userId != null) 'userId': userId.toString(),
    };
    final endpoint = Uri(path: 'dealers', queryParameters: queryParams.isEmpty ? null : queryParams).toString();
    return _get(endpoint, (json) => (json as List).map((item) => Dealer.fromJson(item)).toList());
  }

  Future<Dealer> fetchDealerById(String dealerId) {
    return _get('dealers/$dealerId', (json) => Dealer.fromJson(json));
  }
  
  Future<List<Pjp>> fetchPjpsForUser(int userId, {String? startDate, String? endDate, String? status}) async {
    final queryParams = <String, String>{
      if (startDate != null) 'startDate': startDate,
      if (endDate != null) 'endDate': endDate,
      if (status != null) 'status': status,
    };
    final endpoint = Uri(path: 'pjp/user/$userId', queryParameters: queryParams.isEmpty ? null : queryParams).toString();
    return _get(endpoint, (json) => (json as List).map((item) => Pjp.fromJson(item)).toList());
  }
  
  Future<List<DailyTask>> fetchDailyTasksForUser(int userId, {String? startDate, String? endDate, String? status}) async {
    final queryParams = <String, String>{
      if (startDate != null) 'startDate': startDate,
      if (endDate != null) 'endDate': endDate,
      if (status != null) 'status': status,
    };
    final endpoint = Uri(path: 'daily-tasks/user/$userId', queryParameters: queryParams.isEmpty ? null : queryParams).toString();
    return _get(endpoint, (json) => (json as List).map((item) => DailyTask.fromJson(item)).toList());
  }

  Future<List<LeaveApplication>> fetchLeaveApplicationsForUser(int userId, {String? startDate, String? endDate, String? status}) async {
    final queryParams = <String, String>{
      if (startDate != null) 'startDate': startDate,
      if (endDate != null) 'endDate': endDate,
      if (status != null) 'status': status,
    };
    final endpoint = Uri(path: 'leave-applications/user/$userId', queryParameters: queryParams.isEmpty ? null : queryParams).toString();
    return _get(endpoint, (json) => (json as List).map((item) => LeaveApplication.fromJson(item)).toList());
  }

  Future<List<Attendance>> fetchAttendanceForUser(int userId, {String? startDate, String? endDate}) async {
    final queryParams = <String, String>{
      if (startDate != null) 'startDate': startDate,
      if (endDate != null) 'endDate': endDate,
    };
    final endpoint = Uri(path: 'attendance/user/$userId', queryParameters: queryParams.isEmpty ? null : queryParams).toString();
    return _get(endpoint, (json) => (json as List).map((item) => Attendance.fromJson(item)).toList());
  }
  
  Future<Attendance> fetchTodaysAttendance(int userId) {
    return _get('attendance/user/$userId/today', (json) => Attendance.fromJson(json));
  }
  
  Future<List<DailyVisitReport>> fetchDvrsForUser(int userId, {String? startDate, String? endDate, String? dealerType, String? visitType}) async {
    final queryParams = <String, String>{
      if (startDate != null) 'startDate': startDate,
      if (endDate != null) 'endDate': endDate,
      if (dealerType != null) 'dealerType': dealerType,
      if (visitType != null) 'visitType': visitType,
    };
    final endpoint = Uri(path: 'daily-visit-reports/user/$userId', queryParameters: queryParams.isEmpty ? null : queryParams).toString();
    return _get(endpoint, (json) => (json as List).map((item) => DailyVisitReport.fromJson(item)).toList());
  }
  
  Future<List<TechnicalVisitReport>> fetchTvrsForUser(int userId, {String? startDate, String? endDate, String? visitType, String? serviceType}) async {
    final queryParams = <String, String>{
      if (startDate != null) 'startDate': startDate,
      if (endDate != null) 'endDate': endDate,
      if (visitType != null) 'visitType': visitType,
      if (serviceType != null) 'serviceType': serviceType,
    };
    final endpoint = Uri(path: 'technical-visit-reports/user/$userId', queryParameters: queryParams.isEmpty ? null : queryParams).toString();
    return _get(endpoint, (json) => (json as List).map((item) => TechnicalVisitReport.fromJson(item)).toList());
  }

  // --- POST METHODS ---
  
  Future<Dealer> createDealer(Dealer dealer, {required double latitude, required double longitude}) async {
    final body = dealer.toJson();
    body['latitude'] = latitude;
    body['longitude'] = longitude;
    return _post('dealers', body, (json) => Dealer.fromJson(json));
  }
  
  Future<Attendance> checkIn(Map<String, dynamic> checkInData) async {
    return _post('attendance/check-in', checkInData, (json) => Attendance.fromJson(json));
  }
  
  Future<Attendance> checkOut(Map<String, dynamic> checkOutData) async {
    return _post('attendance/check-out', checkOutData, (json) => Attendance.fromJson(json));
  }

  Future<Pjp> createPjp(Pjp pjp) async {
    return _post('pjp', pjp.toJson(), (json) => Pjp.fromJson(json));
  }

  Future<DailyTask> createDailyTask(DailyTask task) async {
    return _post('daily-tasks', task.toJson(), (json) => DailyTask.fromJson(json));
  }

  Future<DailyVisitReport> createDvr(DailyVisitReport dvr) async {
    return _post('daily-visit-reports', dvr.toJson(), (json) => DailyVisitReport.fromJson(json));
  }

  Future<TechnicalVisitReport> createTvr(TechnicalVisitReport tvr) async {
    return _post('technical-visit-reports', tvr.toJson(), (json) => TechnicalVisitReport.fromJson(json));
  }

  Future<LeaveApplication> createLeaveApplication(LeaveApplication leaveApp) async {
    return _post('leave-applications', leaveApp.toJson(), (json) => LeaveApplication.fromJson(json));
  }
  
  // --- PATCH METHODS ---
  
  // --- NEW: This is the missing function ---
  Future<Pjp> updatePjp(String pjpId, Map<String, dynamic> data) async {
    return _patch('pjp/$pjpId', data, (json) => Pjp.fromJson(json));
  }


  // --- DELETE METHODS ---
  
  Future<void> deleteDealer(String dealerId) => _delete('dealers/$dealerId');
  Future<void> deletePjp(String pjpId) => _delete('pjp/$pjpId');
  Future<void> deleteDailyTask(String taskId) => _delete('daily-tasks/$taskId');
  Future<void> deleteDvr(String dvrId) => _delete('daily-visit-reports/$dvrId');
  Future<void> deleteTvr(String tvrId) => _delete('technical-visit-reports/$tvrId');
  Future<void> deleteLeaveApplication(String leaveId) => _delete('leave-applications/$leaveId');
  Future<void> deleteSalesOrder(String orderId) => _delete('sales-orders/$orderId');
}
