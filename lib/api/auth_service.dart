// lib/api/auth_service.dart

import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../models/employee_model.dart'; // Make sure this path is correct for your project

class AuthService {
  static const String _baseUrl = 'https://myserverbymycoco.onrender.com';
  final _storage = const FlutterSecureStorage();

  /// Saves the JWT to the device's secure storage.
  Future<void> _saveToken(String token) async {
    await _storage.write(key: 'jwt_token', value: token);
    dev.log('Token saved to secure storage.', name: 'AuthService');
  }

  /// Reads the JWT from the device's secure storage.
  Future<String?> _getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  /// Deletes the JWT from storage to log the user out.
  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
    dev.log('Token deleted. User logged out.', name: 'AuthService');
  }

  /// Main login function.
  /// It now gets a JWT, saves it, and then fetches the user's profile.
  Future<Employee> login(String loginId, String password) async {
    final url = Uri.parse('$_baseUrl/api/auth/login');
    final requestBody = jsonEncode({
      'loginId': loginId.trim(),
      'password': password
    });

    dev.log('--- Sending Login Request ---', name: 'AuthService');
    try {
      final response = await http
          .post(url, headers: {'Content-Type': 'application/json'}, body: requestBody)
          .timeout(const Duration(seconds: 45));

      dev.log('--- Received Login Response ---', name: 'AuthService');
      dev.log('Status Code: ${response.statusCode}', name: 'AuthService');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String? token = data['token'];
        final int? userId = data['userId'];

        if (token != null && userId != null) {
          // 1. Save the token
          await _saveToken(token);

          // 2. Use the token to fetch the protected profile data
          return await _fetchUserProfile(userId.toString(), token);
        } else {
          throw Exception('Login response is missing token or userId.');
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'An unknown server error occurred.');
      }
    } on TimeoutException {
      throw Exception('Server is taking too long to respond.');
    } catch (e) {
      dev.log('AuthService Login Error', error: e, name: 'AuthService');
      rethrow; // Rethrow to be caught by the UI
    }
  }

  /// Fetches the user profile from the protected /api/users/:id endpoint.
  /// It now requires a token to be sent in the headers.
  Future<Employee> _fetchUserProfile(String userId, String token) async {
    final url = Uri.parse('$_baseUrl/api/users/$userId');
    dev.log('--- Fetching User Profile with Token ---', name: 'AuthService');
    try {
      final response = await http.get(
        url,
        // This Authorization header is what authenticates the request
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30));

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
        final errorData = jsonDecode(response.body);
        if (response.statusCode == 403) {
          throw Exception("Session expired. Please log in again.");
        }
        throw Exception(errorData['error'] ?? 'Failed to load user profile.');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// A new method to be called on app startup.
  /// It checks for a saved token and tries to log the user in automatically.
  Future<Employee?> tryAutoLogin() async {
    dev.log('--- Attempting Auto-Login ---', name: 'AuthService');
    final token = await _getToken();

    if (token == null) {
      dev.log('No token found. Auto-login skipped.', name: 'AuthService');
      return null; // No token, no auto-login.
    }

    try {
      // Decode the user ID directly from the token payload to be efficient
      final payload = json.decode(
        ascii.decode(base64.decode(base64.normalize(token.split('.')[1])))
      );
      final String userId = payload['id'].toString();

      // Use the existing token to fetch the user's profile
      final employee = await _fetchUserProfile(userId, token);
      dev.log('Auto-login successful!', name: 'AuthService');
      return employee;

    } catch (e) {
      // If the token is expired or invalid, it will fail.
      // Clear the bad token and return null.
      dev.log('Auto-login failed: ${e.toString()}', name: 'AuthService');
      await logout();
      return null;
    }
  }
}