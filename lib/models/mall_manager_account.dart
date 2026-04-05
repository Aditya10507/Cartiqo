class MallManagerAccount {
  final String mallId;
  final String managerId;
  final String? assignedUid;
  final String? assignedEmail;
  final bool isActive;
  final String fullName;
  final String phoneNumber;
  final DateTime? dateOfJoining;

  MallManagerAccount({
    required this.mallId,
    required this.managerId,
    required this.assignedUid,
    required this.assignedEmail,
    required this.isActive,
    this.fullName = '',
    this.phoneNumber = '',
    this.dateOfJoining,
  });

  factory MallManagerAccount.fromMap(String mallId, Map<String, dynamic> map) {
    DateTime? parseDate(dynamic value) {
      if (value is DateTime) return value;
      if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
      return null;
    }

    return MallManagerAccount(
      mallId: mallId,
      managerId: (map['managerId'] ?? '').toString(),
      assignedUid: map['assignedUid'] == null ? null : map['assignedUid'].toString(),
      assignedEmail:
          map['assignedEmail'] == null ? null : map['assignedEmail'].toString(),
      isActive: map['isActive'] == null ? true : map['isActive'] == true,
      fullName: (map['fullName'] ?? '').toString(),
      phoneNumber: (map['phoneNumber'] ?? '').toString(),
      dateOfJoining: parseDate(map['dateOfJoining']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'mallId': mallId,
      'managerId': managerId,
      'assignedUid': assignedUid,
      'assignedEmail': assignedEmail,
      'isActive': isActive,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'dateOfJoining': dateOfJoining?.toIso8601String(),
    };
  }
}
