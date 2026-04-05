class AppUserSession {
  const AppUserSession({
    required this.uid,
    required this.username,
    required this.fullName,
    required this.displayName,
    required this.email,
    required this.phoneNumber,
    required this.photoURL,
    required this.emailVerified,
    required this.provider,
    this.token,
  });

  final String uid;
  final String username;
  final String fullName;
  final String displayName;
  final String email;
  final String phoneNumber;
  final String photoURL;
  final bool emailVerified;
  final String provider;
  final String? token;

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'username': username,
      'fullName': fullName,
      'displayName': displayName,
      'email': email,
      'phoneNumber': phoneNumber,
      'photoURL': photoURL,
      'emailVerified': emailVerified,
      'provider': provider,
      'token': token ?? '',
    };
  }

  factory AppUserSession.fromJson(Map<String, dynamic> json) {
    return AppUserSession(
      uid: (json['uid'] ?? '').toString(),
      username: (json['username'] ?? '').toString(),
      fullName: (json['fullName'] ?? '').toString(),
      displayName: (json['displayName'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      phoneNumber: (json['phoneNumber'] ?? '').toString(),
      photoURL: (json['photoURL'] ?? '').toString(),
      emailVerified: json['emailVerified'] == true,
      provider: (json['provider'] ?? '').toString(),
      token: (json['token'] ?? '').toString().trim().isEmpty
          ? null
          : (json['token'] ?? '').toString(),
    );
  }

  AppUserSession copyWith({
    String? uid,
    String? username,
    String? fullName,
    String? displayName,
    String? email,
    String? phoneNumber,
    String? photoURL,
    bool? emailVerified,
    String? provider,
    String? token,
  }) {
    return AppUserSession(
      uid: uid ?? this.uid,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      photoURL: photoURL ?? this.photoURL,
      emailVerified: emailVerified ?? this.emailVerified,
      provider: provider ?? this.provider,
      token: token ?? this.token,
    );
  }
}
