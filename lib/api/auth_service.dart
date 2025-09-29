import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'package:http/http.dart' as http;
import '../models/employee_model.dart';

class AuthService {
  static const String _baseUrl = 'https://myserverbymycoco.onrender.com';

  /// Fetches the full user profile from the /api/users/:id endpoint.
  /// This is now a private helper method called after a successful login.
  Future<Employee> _fetchUserProfile(String userId) async {
    // The endpoint is now '/api/users/' (plural) to match your server code.
    final url = Uri.parse('$_baseUrl/api/users/$userId');
    dev.log('--- Step 2: Fetching User Profile ---', name: 'AuthService');
    dev.log('URL: $url', name: 'AuthService');

    try {
      final response = await http
          .get(url, headers: {'Content-Type': 'application/json; charset=UTF-8'})
          .timeout(const Duration(seconds: 30));

      dev.log('--- Received Profile Response ---', name: 'AuthService');
      dev.log('Status Code: ${response.statusCode}', name: 'AuthService');
      dev.log('Response Body: ${response.body}', name: 'AuthService');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // The server nests the user object under a 'data' key in this endpoint.
        if (data.containsKey('data')) {
          return Employee.fromJson(data['data']);
        } else {
          throw Exception('Profile "data" key is missing in the response.');
        }
      } else {
        throw Exception('Failed to load user profile. Status: ${response.statusCode}');
      }
    } on TimeoutException {
      throw Exception('Server timed out while fetching user profile.');
    } catch (e) {
      // Re-throw the error to be caught by the main login handler.
      rethrow;
    }
  }

  /// The main login function. It now performs a two-step authentication and profile fetch.
  Future<Employee> login(String loginId, String password) async {
    final url = Uri.parse('$_baseUrl/api/auth/login');
    final requestBody = jsonEncode({
      'loginId': loginId.trim(),
      'password': password,
    });

    dev.log('--- Step 1: Sending Login Request ---', name: 'AuthService');
    dev.log('URL: $url', name: 'AuthService');
    dev.log('Body: $requestBody', name: 'AuthService');

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: requestBody,
          )
          .timeout(const Duration(seconds: 45));

      dev.log('--- Received Login Response ---', name: 'AuthService');
      dev.log('Status Code: ${response.statusCode}', name: 'AuthService');
      dev.log('Response Body: ${response.body}', name: 'AuthService');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        if (data.containsKey('user') && data['user']['id'] != null) {
          // Login was successful, now use the ID to fetch the full profile.
          final userId = data['user']['id'].toString();
          final fullProfile = await _fetchUserProfile(userId);
          return fullProfile;
        } else {
          throw Exception('Login successful but user ID is missing.');
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'An unknown server error occurred.');
      }
    } on TimeoutException {
      dev.log('--- API Request Timed Out ---', name: 'AuthService');
      throw Exception('Server is taking too long to respond. Please try again.');
    } catch (e, stackTrace) {
      dev.log(
        'AuthService Login/Profile Process Error',
        error: e,
        stackTrace: stackTrace,
        name: 'AuthService',
      );
      // Provide a clean error message to the UI.
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }
}

