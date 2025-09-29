import 'dart:convert';

/// A function to decode a JSON string into an Employee object.
Employee employeeFromJson(String str) => Employee.fromJson(json.decode(str));

/// A function to encode an Employee object into a JSON string.
String employeeToJson(Employee data) => json.encode(data.toJson());

/// Represents the user/employee data structure received from the API.
/// This model is designed to hold the user information after a successful login.
class Employee {
  final int id;
  // These fields are based on standard user objects.
  // Add or remove fields to match your actual API response for the 'user' object.
  final String? name;
  final String? email;
  final String? loginId;

  Employee({
    required this.id,
    this.name,
    this.email,
    this.loginId,
  });

  /// A factory constructor to create an Employee instance from a JSON map.
  /// This is used to parse the server's response.
  factory Employee.fromJson(Map<String, dynamic> json) => Employee(
        id: json["id"],
        name: json["name"],
        email: json["email"],
        loginId: json["loginId"],
      );

  /// Converts the Employee instance into a JSON map.
  /// This is useful for storing the user data in local storage (e.g., shared_preferences).
  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "email": email,
        "loginId": loginId,
      };
}
