class MallManagerProfile {
  final String mallId;
  final String managerId;
  final String email;
  final String fullName;
  final String phoneNumber;
  final DateTime? dateOfJoining;

  const MallManagerProfile({
    required this.mallId,
    required this.managerId,
    required this.email,
    required this.fullName,
    required this.phoneNumber,
    required this.dateOfJoining,
  });

  MallManagerProfile copyWith({
    String? email,
    String? fullName,
    String? phoneNumber,
    DateTime? dateOfJoining,
  }) {
    return MallManagerProfile(
      mallId: mallId,
      managerId: managerId,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      dateOfJoining: dateOfJoining ?? this.dateOfJoining,
    );
  }

  static DateTime? _readDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
    return null;
  }

  factory MallManagerProfile.fromMap({
    required String mallId,
    required String managerId,
    required Map<String, dynamic> data,
  }) {
    return MallManagerProfile(
      mallId: mallId,
      managerId: managerId,
      email: (data['assignedEmail'] ?? '').toString(),
      fullName: (data['fullName'] ?? '').toString(),
      phoneNumber: (data['phoneNumber'] ?? '').toString(),
      dateOfJoining: _readDate(data['dateOfJoining']),
    );
  }
}
