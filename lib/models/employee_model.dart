import 'dart:convert';

Employee employeeFromJson(String str) => Employee.fromJson(json.decode(str));
String employeeToJson(Employee data) => json.encode(data.toJson());

class Employee {
  final String id;
  final String? name; // This will now be populated with the salesmanLoginId
  final String? email;
  final String? loginId; // This will also be the salesmanLoginId

  Employee({
    required this.id,
    this.name,
    this.email,
    this.loginId,
  });

  /// A factory constructor to create an Employee instance from a JSON map.
  /// This now matches the structure of your server's login response.
  factory Employee.fromJson(Map<String, dynamic> json) {
    // The server sends 'salesmanLoginId', so we use that.
    final serverLoginId = json["salesmanLoginId"] as String?;

    return Employee(
      id: json["id"]?.toString() ?? '',
      // Use the server's login ID as the display name, since firstName is not available.
      name: serverLoginId,
      email: json["email"] as String?,
      // Map the server's ID to our model's loginId field.
      loginId: serverLoginId,
    );
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "email": email,
        "loginId": loginId,
      };
}

