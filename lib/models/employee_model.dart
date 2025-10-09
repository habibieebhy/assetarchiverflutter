import 'dart:convert';

Employee employeeFromJson(String str) => Employee.fromJson(json.decode(str));
String employeeToJson(Employee data) => json.encode(data.toJson());

class Employee {
  final String id;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? loginId;
  final String? companyName;
  // HIGHLIGHT: ADDED THE ROLE PROPERTY
  final String? role;

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
    // HIGHLIGHT: ADDED ROLE TO THE CONSTRUCTOR
    this.role,
  });

  // HIGHLIGHT: THE fromJson FACTORY IS NOW SMARTER
  factory Employee.fromJson(Map<String, dynamic> json) {
    // This logic handles both the nested structure from the profile endpoint
    // and the flat structure from the initial login response.
    final companyData = json['company'];
    String? extractedCompanyName;
    if (companyData is Map<String, dynamic>) {
      extractedCompanyName = companyData['companyName'];
    } else {
      extractedCompanyName = json['companyName'];
    }

    return Employee(
      id: json["id"]?.toString() ?? '',
      firstName: json["firstName"] as String?,
      lastName: json["lastName"] as String?,
      email: json["email"] as String?,
      loginId: json["salesmanLoginId"] as String?,
      // Use the correctly extracted company name
      companyName: extractedCompanyName,
      // Parse the role from the JSON
      role: json["role"] as String?,
    );
  }

  // HIGHLIGHT: UPDATED copyWith
  Employee copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    String? loginId,
    String? companyName,
    String? role,
  }) {
    return Employee(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      loginId: loginId ?? this.loginId,
      companyName: companyName ?? this.companyName,
      role: role ?? this.role,
    );
  }

  // HIGHLIGHT: UPDATED toJson
  Map<String, dynamic> toJson() => {
        "id": id,
        "firstName": firstName,
        "lastName": lastName,
        "email": email,
        "loginId": loginId,
        "companyName": companyName,
        "role": role,
      };
}

