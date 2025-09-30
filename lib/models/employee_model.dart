import 'dart:convert';

Employee employeeFromJson(String str) => Employee.fromJson(json.decode(str));
String employeeToJson(Employee data) => json.encode(data.toJson());

class Employee {
  final String id;
  // UPDATED: Added fields to hold the user's full name from the profile endpoint.
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? loginId;
  final String? companyName;

  /// A computed property to get the best possible display name.
  /// It prioritizes a full name, then falls back to first name, last name, or login ID.
  String get displayName {
    if (firstName != null && lastName != null && firstName!.isNotEmpty && lastName!.isNotEmpty) {
      return '$firstName $lastName';
    }
    return firstName ?? lastName ?? loginId ?? 'Employee';
  }

  Employee({
    required this.id,
    this.firstName,
    this.lastName,
    this.email,
    this.loginId,
    this.companyName,
  });

  /// This factory constructor is now robust enough to handle data from
  /// both the /login (minimal) and /users/:id (full profile) server responses.
  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json["id"]?.toString() ?? '',
      // UPDATED: Now parses the first and last name fields from the profile endpoint.
      firstName: json["firstName"] as String?,
      lastName: json["lastName"] as String?,
      email: json["email"] as String?,
      // The login response has 'salesmanLoginId', the profile endpoint might too.
      loginId: json["salesmanLoginId"] as String?,
      // The login response provides this.
      companyName: json["companyName"] as String?,
    );
  }

  // --- ADDED: The copyWith method to allow merging data from the two API calls ---
  Employee copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    String? loginId,
    String? companyName,
  }) {
    return Employee(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      loginId: loginId ?? this.loginId,
      companyName: companyName ?? this.companyName,
    );
  }

  /// Converts the Employee instance into a JSON map for local storage.
  Map<String, dynamic> toJson() => {
        "id": id,
        "firstName": firstName,
        "lastName": lastName,
        "email": email,
        "loginId": loginId,
        "companyName": companyName,
      };
}

