import 'package:cloud_firestore/cloud_firestore.dart';

class Admin {
  final String adminId;
  final String email;
  final String name;
  final String role; // 'super_admin' or 'admin'
  final DateTime createdAt;

  Admin({
    required this.adminId,
    required this.email,
    required this.name,
    required this.role,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'adminId': adminId,
      'email': email,
      'name': name,
      'role': role,
      'createdAt': createdAt,
    };
  }

  factory Admin.fromMap(Map<String, dynamic> map) {
    DateTime parseCreatedAt() {
      final value = map['createdAt'];
      if (value is Timestamp) {
        return value.toDate();
      } else if (value is DateTime) {
        return value;
      } else if (value is String) {
        return DateTime.parse(value);
      }
      return DateTime.now();
    }

    return Admin(
      adminId: map['adminId'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      role: map['role'] ?? 'admin',
      createdAt: parseCreatedAt(),
    );
  }
}
