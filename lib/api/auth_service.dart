import 'dart:async'; // Required for TimeoutException
import 'dart:convert';
import 'dart:developer'; // UPDATED: Import the developer log function.
import 'package:http/http.dart' as http;
import '../models/employee_model.dart';

class AuthService {
  static const String _baseUrl = 'https://myserverbymycoco.onrender.com';

  Future<Employee> login(String loginId, String password) async {
    final url = Uri.parse('$_baseUrl/api/auth/login');
    final requestBody = jsonEncode({
      'loginId': loginId,
      'password': password,
    });

    // UPDATED: Replaced print() with log() for better debugging.
    log('--- Sending API Request ---', name: 'AuthService');
    log('URL: $url', name: 'AuthService');
    log('Body: $requestBody', name: 'AuthService');
    log('---------------------------', name: 'AuthService');

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: requestBody,
          )
          .timeout(const Duration(seconds: 15));

      // UPDATED: Replaced print() with log().
      log('--- Received API Response ---', name: 'AuthService');
      log('Status Code: ${response.statusCode}', name: 'AuthService');
      log('Response Body: ${response.body}', name: 'AuthService');
      log('-----------------------------', name: 'AuthService');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        if (data.containsKey('user')) {
          return Employee.fromJson(data['user']);
        } else {
          throw Exception('Login successful, but user data is missing.');
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'An unknown server error occurred.');
      }
    } on TimeoutException {
      // UPDATED: Replaced print() with log().
      log('--- API Request Timed Out ---', name: 'AuthService');
      throw Exception('Server is taking too long to respond. Please try again.');
    } catch (e, stackTrace) {
      // UPDATED: Replaced print() with log() and included the stack trace.
      log(
        'AuthService Login Error',
        error: e,
        stackTrace: stackTrace,
        name: 'AuthService',
      );
      throw Exception('Failed to connect to the server. Please check your connection.');
    }
  }
}

