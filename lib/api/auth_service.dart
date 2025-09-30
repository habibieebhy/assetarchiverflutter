import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'package:http/http.dart' as http;
import '../models/employee_model.dart';

class AuthService {
  static const String _baseUrl = 'https://myserverbymycoco.onrender.com';

  /// The main login function. It now performs a two-step authentication and profile fetch.
  Future<Employee> login(String loginId, String password) async {
    final url = Uri.parse('$_baseUrl/api/auth/login');
    final requestBody = jsonEncode({
      'loginId': loginId.trim(),
      'password': password,
    });

    dev.log('--- Step 1: Sending Login Request ---', name: 'AuthService');
    dev.log('URL: $url', name: 'AuthService');

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

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        if (data.containsKey('user') && data['user']['id'] != null) {
          // Create an initial employee object from the login response.
          // This object CONTAINS the companyName.
          final initialEmployee = Employee.fromJson(data['user']);

          // Now use the ID to fetch the full profile (which has the full name).
          final fullProfile = await _fetchUserProfile(initialEmployee.id);

          // --- THE FIX ---
          // Merge the data. Start with the full profile, and use `copyWith`
          // to add the companyName from the initial login.
          return fullProfile.copyWith(
            companyName: initialEmployee.companyName,
          );
        } else {
          throw Exception('Login successful but user ID is missing.');
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'An unknown server error occurred.');
      }
    } on TimeoutException {
      throw Exception('Server is taking too long to respond.');
    } catch (e) {
      dev.log('AuthService Process Error', error: e, name: 'AuthService');
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  /// Fetches the full user profile from the /api/users/:id endpoint.
  Future<Employee> _fetchUserProfile(String userId) async {
    final url = Uri.parse('$_baseUrl/api/users/$userId');
    dev.log('--- Step 2: Fetching User Profile ---', name: 'AuthService');
    try {
      final response = await http
          .get(url, headers: {'Content-Type': 'application/json; charset=UTF-8'})
          .timeout(const Duration(seconds: 30));

      dev.log('--- Received Profile Response ---', name: 'AuthService');
      dev.log('Status Code: ${response.statusCode}', name: 'AuthService');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data.containsKey('data')) {
          return Employee.fromJson(data['data']);
        } else {
          throw Exception('Profile "data" key is missing in the response.');
        }
      } else {
        throw Exception('Failed to load user profile. Status: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }
}

