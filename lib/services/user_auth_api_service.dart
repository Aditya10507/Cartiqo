import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/app_user_session.dart';
import 'api_config.dart';

class UserOtpRequestResult {
  const UserOtpRequestResult({
    required this.message,
    required this.expiresAtUtc,
    this.debugOtp,
  });

  final String message;
  final DateTime expiresAtUtc;
  final String? debugOtp;
}

class UserOtpVerifyResult {
  const UserOtpVerifyResult({
    required this.token,
    required this.user,
    required this.expiresAtUtc,
  });

  final String token;
  final AppUserSession user;
  final DateTime expiresAtUtc;
}

class UserAuthApiService {
  Uri _uri(String path) => Uri.parse('${ApiConfig.baseUrl}$path');

  Future<UserOtpRequestResult> requestEmailOtp({
    required String firstName,
    required String lastName,
    required String username,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      _uri('/api/auth/users/register/request-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'firstName': firstName.trim(),
        'lastName': lastName.trim(),
        'username': username.trim(),
        'email': email.trim(),
        'password': password,
      }),
    );
    final body = _decodeJson(response.body);

    if (response.statusCode != 200) {
      throw Exception(_extractMessage(body, fallback: 'Failed to send OTP.'));
    }

    final map = Map<String, dynamic>.from(body as Map);
    return UserOtpRequestResult(
      message: (map['message'] ?? 'OTP sent.').toString(),
      expiresAtUtc: DateTime.tryParse((map['expiresAtUtc'] ?? '').toString()) ??
          DateTime.now().toUtc().add(const Duration(minutes: 10)),
      debugOtp: (map['debugOtp'] ?? '').toString().trim().isEmpty
          ? null
          : (map['debugOtp'] ?? '').toString(),
    );
  }

  Future<UserOtpVerifyResult> verifyEmailOtp({
    required String email,
    required String otp,
  }) async {
    final response = await http.post(
      _uri('/api/auth/users/register/verify-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email.trim(),
        'otp': otp.trim(),
      }),
    );
    final body = _decodeJson(response.body);

    if (response.statusCode != 200) {
      throw Exception(_extractMessage(body, fallback: 'Failed to verify OTP.'));
    }

    final map = Map<String, dynamic>.from(body as Map);
    final userMap = Map<String, dynamic>.from(map['user'] as Map);

    return UserOtpVerifyResult(
      token: (map['token'] ?? '').toString(),
      expiresAtUtc: DateTime.tryParse((map['expiresAtUtc'] ?? '').toString()) ??
          DateTime.now().toUtc().add(const Duration(hours: 2)),
      user: AppUserSession(
        uid: (userMap['uid'] ?? '').toString(),
        username: (userMap['username'] ?? '').toString(),
        fullName: (userMap['fullName'] ?? '').toString(),
        displayName: (userMap['displayName'] ?? '').toString(),
        email: (userMap['email'] ?? '').toString(),
        phoneNumber: (userMap['phoneNumber'] ?? '').toString(),
        photoURL: (userMap['photoUrl'] ?? '').toString(),
        emailVerified: userMap['emailVerified'] == true,
        provider: (userMap['provider'] ?? '').toString(),
        token: (map['token'] ?? '').toString(),
      ),
    );
  }

  Future<UserOtpVerifyResult> login({
    required String username,
    required String password,
  }) async {
    final response = await http.post(
      _uri('/api/auth/users/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username.trim(),
        'password': password,
      }),
    );
    final body = _decodeJson(response.body);

    if (response.statusCode != 200) {
      throw Exception(_extractMessage(body, fallback: 'Failed to sign in.'));
    }

    final map = Map<String, dynamic>.from(body as Map);
    final userMap = Map<String, dynamic>.from(map['user'] as Map);

    return UserOtpVerifyResult(
      token: (map['token'] ?? '').toString(),
      expiresAtUtc: DateTime.tryParse((map['expiresAtUtc'] ?? '').toString()) ??
          DateTime.now().toUtc().add(const Duration(hours: 2)),
      user: AppUserSession(
        uid: (userMap['uid'] ?? '').toString(),
        username: (userMap['username'] ?? '').toString(),
        fullName: (userMap['fullName'] ?? '').toString(),
        displayName: (userMap['displayName'] ?? '').toString(),
        email: (userMap['email'] ?? '').toString(),
        phoneNumber: (userMap['phoneNumber'] ?? '').toString(),
        photoURL: (userMap['photoUrl'] ?? '').toString(),
        emailVerified: userMap['emailVerified'] == true,
        provider: (userMap['provider'] ?? '').toString(),
        token: (map['token'] ?? '').toString(),
      ),
    );
  }

  Future<UserOtpRequestResult> requestPasswordResetOtp({
    required String email,
  }) async {
    final response = await http.post(
      _uri('/api/auth/users/password/request-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email.trim(),
      }),
    );
    final body = _decodeJson(response.body);

    if (response.statusCode != 200) {
      throw Exception(_extractMessage(body, fallback: 'Failed to send reset OTP.'));
    }

    final map = Map<String, dynamic>.from(body as Map);
    return UserOtpRequestResult(
      message: (map['message'] ?? 'OTP sent.').toString(),
      expiresAtUtc: DateTime.tryParse((map['expiresAtUtc'] ?? '').toString()) ??
          DateTime.now().toUtc().add(const Duration(minutes: 10)),
      debugOtp: (map['debugOtp'] ?? '').toString().trim().isEmpty
          ? null
          : (map['debugOtp'] ?? '').toString(),
    );
  }

  Future<String> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    final response = await http.post(
      _uri('/api/auth/users/password/reset'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email.trim(),
        'otp': otp.trim(),
        'newPassword': newPassword,
      }),
    );
    final body = _decodeJson(response.body);

    if (response.statusCode != 200) {
      throw Exception(_extractMessage(body, fallback: 'Failed to reset password.'));
    }

    if (body is Map && body['message'] != null) {
      return body['message'].toString();
    }
    return 'Password reset successful.';
  }

  dynamic _decodeJson(String body) {
    if (body.trim().isEmpty) {
      return <String, dynamic>{};
    }
    return jsonDecode(body);
  }

  String _extractMessage(dynamic body, {required String fallback}) {
    if (body is Map && body['message'] != null) {
      return body['message'].toString();
    }
    return fallback;
  }
}
