class MallManagerAccount {
  final String mallId;
  final String managerId;
  final String? assignedUid;
  final String? assignedEmail;
  final bool isActive;

  MallManagerAccount({
    required this.mallId,
    required this.managerId,
    required this.assignedUid,
    required this.assignedEmail,
    required this.isActive,
  });

  factory MallManagerAccount.fromMap(String mallId, Map<String, dynamic> map) {
    return MallManagerAccount(
      mallId: mallId,
      managerId: (map['managerId'] ?? '').toString(),
      assignedUid: map['assignedUid'] == null ? null : map['assignedUid'].toString(),
      assignedEmail:
          map['assignedEmail'] == null ? null : map['assignedEmail'].toString(),
      isActive: map['isActive'] == null ? true : map['isActive'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'mallId': mallId,
      'managerId': managerId,
      'assignedUid': assignedUid,
      'assignedEmail': assignedEmail,
      'isActive': isActive,
    };
  }
}
