import 'package:cloud_firestore/cloud_firestore.dart';

class MallSubscription {
  final String mallId;
  final String name; // Mall name (matches your 'name' field)
  final String? ownerName;
  final String? ownerEmail;
  final String? city;
  final String? state;
  final DateTime subscriptionStartDate;
  final DateTime subscriptionEndDate;
  final String planType; // 'basic', 'pro', 'enterprise'
  final int maxProducts;
  final bool isActive;
  final DateTime createdAt;
  
  // Your existing fields
  final String? areaCode;
  final int? estYear;
  final String? mallCode;
  final int? mallNumber;
  final bool? active;

  MallSubscription({
    required this.mallId,
    required this.name,
    this.ownerName,
    this.ownerEmail,
    this.city,
    this.state,
    required this.subscriptionStartDate,
    required this.subscriptionEndDate,
    required this.planType,
    required this.maxProducts,
    required this.isActive,
    required this.createdAt,
    this.areaCode,
    this.estYear,
    this.mallCode,
    this.mallNumber,
    this.active,
  });

  bool get isExpired => subscriptionEndDate.isBefore(DateTime.now());
  int get daysUntilExpiry =>
      subscriptionEndDate.difference(DateTime.now()).inDays;

  Map<String, dynamic> toMap() {
    return {
      'mallId': mallId,
      'name': name,
      'ownerName': ownerName,
      'ownerEmail': ownerEmail,
      'city': city,
      'state': state,
      'subscriptionStartDate': subscriptionStartDate,
      'subscriptionEndDate': subscriptionEndDate,
      'planType': planType,
      'maxProducts': maxProducts,
      'isActive': isActive,
      'createdAt': createdAt,
      // Your existing fields
      'areaCode': areaCode,
      'estYear': estYear,
      'mallCode': mallCode,
      'mallNumber': mallNumber,
      'active': active,
    };
  }

  factory MallSubscription.fromMap(Map<String, dynamic> map) {
    // Helper function to parse dates from various formats
    DateTime parseDateTime(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is DateTime) return value;
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.parse(value);
      return DateTime.now();
    }

    return MallSubscription(
      mallId: map['mallId'] ?? '',
      name: map['name'] ?? '',
      ownerName: map['ownerName'],
      ownerEmail: map['ownerEmail'],
      city: map['city'],
      state: map['state'],
      subscriptionStartDate: parseDateTime(map['subscriptionStartDate']),
      subscriptionEndDate: parseDateTime(map['subscriptionEndDate']),
      planType: map['planType'] ?? 'basic',
      maxProducts: map['maxProducts'] ?? 1000,
      isActive: map['isActive'] ?? true,
      createdAt: parseDateTime(map['createdAt']),
      // Your existing fields
      areaCode: map['areaCode'],
      estYear: map['estYear'],
      mallCode: map['mallCode'],
      mallNumber: map['mallNumber'],
      active: map['active'],
    );
  }
}
