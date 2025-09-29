import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'package:http/http.dart' as http;
import '../models/employee_model.dart';

class AuthService {
  static const String _baseUrl = 'https://myserverbymycoco.onrender.com';

  Future<Employee> login(String loginId, String password) async {
    final url = Uri.parse('$_baseUrl/api/auth/login');
    final requestBody = jsonEncode({
      'loginId': loginId.trim(),
      'password': password,
    });

    dev.log('--- Sending API Request ---', name: 'AuthService');
    dev.log('URL: $url', name: 'AuthService');
    dev.log('Body: $requestBody', name: 'AuthService');

    try {
      // FIXED: Increased timeout to 45 seconds to allow the free server to wake up.
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: requestBody,
          )
          .timeout(const Duration(seconds: 45));

      dev.log('--- Received API Response ---', name: 'AuthService');
      dev.log('Status Code: ${response.statusCode}', name: 'AuthService');
      dev.log('Response Body: ${response.body}', name: 'AuthService');

      Map<String, dynamic>? data;
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          data = decoded;
        }
      } catch (_) {
        // Handle cases where the body is not valid JSON
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final userJson = (data != null && data.containsKey('user'))
            ? data['user']
            : data;

        if (userJson is Map<String, dynamic> && userJson.isNotEmpty) {
          return Employee.fromJson(userJson);
        }

        throw Exception('Login successful but user data missing or malformed.');
      } else {
        String message = 'An unknown server error occurred.';
        if (data != null) {
          message = data['error']?.toString() ??
              data['message']?.toString() ??
              message;
        } else if (response.body.isNotEmpty) {
          message = response.body;
        }
        throw Exception(message);
      }
    } on TimeoutException {
      dev.log('--- API Request Timed Out ---', name: 'AuthService');
      throw Exception('Server is taking too long to respond. Please try again.');
    } catch (e, stackTrace) {
      dev.log(
        'AuthService Login Error',
        error: e,
        stackTrace: stackTrace,
        name: 'AuthService',
      );
      throw Exception(
          'Failed to connect to the server. Please check your connection.');
    }
  }
}

