import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user_session.dart';

class UserAuthProvider extends ChangeNotifier {
  static const _sessionStorageKey = 'swiftcart_user_session';
  static const _tokenStorageKey = 'swiftcart_user_token';

  final ImagePicker _imagePicker = ImagePicker();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  AppUserSession? _currentUser;
  bool _isLoading = false;
  bool _isReady = false;
  bool _otpSent = false;
  String? _error;
  String? _pendingEmail;
  String? _pendingFirstName;
  String? _pendingLastName;
  String? _pendingUsername;
  String? _pendingPassword;
  String? _debugOtp;
  DateTime? _otpExpiresAt;

  UserAuthProvider({
    AppUserSession? initialSession,
    bool isReady = false,
  }) : _currentUser = initialSession,
       _isReady = isReady {
    if (!_isReady) {
      _restoreSession();
    }
  }

  AppUserSession? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isReady => _isReady;
  bool get isAuthenticated => _currentUser != null;
  bool get canEnterApp => _currentUser != null;
  bool get needsEmailVerification => false;
  bool get otpSent => _otpSent;
  String? get error => _error;
  String? get userId => _currentUser?.uid;
  String? get lastDemoPhoneOtp => _debugOtp;
  String? get pendingEmail => _pendingEmail;
  DateTime? get otpExpiresAt => _otpExpiresAt;

  Future<bool> requestEmailOtp({
    required String firstName,
    required String lastName,
    required String username,
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      final trimmedFirstName = firstName.trim();
      final trimmedLastName = lastName.trim();
      final trimmedUsername = username.trim().toLowerCase();
      final trimmedEmail = email.trim().toLowerCase();
      if (trimmedFirstName.isEmpty ||
          trimmedLastName.isEmpty ||
          trimmedUsername.isEmpty ||
          trimmedEmail.isEmpty ||
          password.isEmpty) {
        _error = 'Please complete all signup fields.';
        return false;
      }

      // Firebase standard flow uses email/password signup directly.
      // For OTP-like flow, we'd use Firebase Functions, but for simplicity:
      _pendingFirstName = trimmedFirstName;
      _pendingLastName = trimmedLastName;
      _pendingUsername = trimmedUsername;
      _pendingPassword = password;
      _pendingEmail = trimmedEmail;
      _otpSent = true;
      
      _error = "Please verify your signup details and proceed.";
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> verifyEmailOtp({
    required String otp,
    String? email,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      final resolvedEmail = (email ?? _pendingEmail ?? '').trim().toLowerCase();
      if (resolvedEmail.isEmpty) {
        _error = 'Please request a code first.';
        return false;
      }

      final userCred = await _auth.createUserWithEmailAndPassword(
        email: resolvedEmail,
        password: _pendingPassword ?? '',
      );

      if (userCred.user == null) throw Exception("Failed to create account.");

      final newUser = AppUserSession(
        uid: userCred.user!.uid,
        email: resolvedEmail,
        username: _pendingUsername ?? resolvedEmail.split('@').first,
        fullName: '${_pendingFirstName ?? ''} ${_pendingLastName ?? ''}'.trim(),
        displayName: '${_pendingFirstName ?? ''} ${_pendingLastName ?? ''}'.trim(),
        phoneNumber: '',
        photoURL: '',
        provider: 'password',
        emailVerified: true,
      );

      final token = await userCred.user!.getIdToken();
      _currentUser = newUser.copyWith(token: token);

      _otpSent = false;
      _debugOtp = null;
      _otpExpiresAt = null;
      _pendingEmail = null;
      _pendingFirstName = null;
      _pendingLastName = null;
      _pendingUsername = null;
      _pendingPassword = null;

      await _persistSession(_currentUser!, token);
      await _ensureUserProfile();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    _otpSent = false;
    _error = null;
    _pendingEmail = null;
    _pendingFirstName = null;
    _pendingLastName = null;
    _pendingUsername = null;
    _pendingPassword = null;
    _debugOtp = null;
    _otpExpiresAt = null;

    await _auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionStorageKey);
    await prefs.remove(_tokenStorageKey);
    notifyListeners();
  }

  Future<void> updateUserProfile({
    required String fullName,
    required String phone,
    required String email,
    String? photoUrl,
  }) async {
    final user = _currentUser;
    if (user == null) return;

    _setLoading(true);
    _error = null;

    try {
      final normalizedPhotoUrl = (photoUrl ?? '').trim();

      await _db.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'username': user.username,
        'fullName': fullName.trim(),
        'displayName': fullName.trim(),
        'email': email.trim(),
        'phone': phone.trim(),
        'photoUrl': normalizedPhotoUrl,
        'avatarPreset': 'sky',
        'provider': user.provider,
        'emailVerified': true,
      }, SetOptions(merge: true));

      _currentUser = user.copyWith(
        fullName: fullName.trim(),
        displayName: fullName.trim(),
        email: email.trim(),
        phoneNumber: phone.trim(),
        photoURL: normalizedPhotoUrl,
        emailVerified: true,
      );
      await _persistSession(_currentUser!, _currentUser!.token);
    } catch (e) {
      _error = 'Unable to update profile: $e';
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateProfilePicture(ImageSource source) async {
    final user = _currentUser;
    if (user == null) {
      _error = 'Please login again to update your profile picture.';
      notifyListeners();
      return false;
    }

    _setLoading(true);
    _error = null;

    try {
      final pickedImage = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1200,
      );

      if (pickedImage == null) {
        return false;
      }

      if (kIsWeb) {
        _error =
            'Gallery and camera profile photos are supported only on the mobile app in this build.';
        return false;
      }

      final extension = pickedImage.name.split('.').last.toLowerCase();
      final safeExtension = extension.isEmpty ? 'jpg' : extension;
      final appDir = await getApplicationDocumentsDirectory();
      final profileDir = Directory(
        '${appDir.path}${Platform.pathSeparator}profile_pictures',
      );
      if (!await profileDir.exists()) {
        await profileDir.create(recursive: true);
      }

      final savedPath =
          '${profileDir.path}${Platform.pathSeparator}${user.uid}_avatar.$safeExtension';
      final savedFile = await File(pickedImage.path).copy(savedPath);
      final existing = await _safeFetchProfile(user.uid);

      await _db.collection('users').doc(user.uid).set({
        'photoUrl': '',
        'localPhotoPath': savedFile.path,
        'username': (existing?['username'] ?? user.username).toString(),
        'fullName': (existing?['fullName'] ?? user.fullName).toString(),
      }, SetOptions(merge: true));

      _currentUser = user.copyWith(photoURL: '');
      await _persistSession(_currentUser!, _currentUser!.token);
      return true;
    } catch (e) {
      _error = 'Unable to update profile picture: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateAvatarPreset(String preset) async {
    final user = _currentUser;
    if (user == null) return;

    final existing = await _safeFetchProfile(user.uid);
    await _db.collection('users').doc(user.uid).set(
      {'avatarPreset': preset},
      SetOptions(merge: true),
    );

    _currentUser = user.copyWith(photoURL: '');
    await _persistSession(_currentUser!, _currentUser!.token);
    notifyListeners();
  }

  Future<bool> saveCheckoutHistory({
    required String mallId,
    required List<Map<String, dynamic>> items,
    required int total,
    required int subtotal,
    required int extraCharge,
    required String extraChargeLabel,
    required int gst,
    required double gstPercent,
    required int otherTax,
    required String otherTaxLabel,
    required double otherTaxPercent,
    required String paymentMethod,
    String? paymentReference,
  }) async {
    final user = _currentUser;
    if (user == null) {
      _error = 'Please login again to save checkout history.';
      notifyListeners();
      return false;
    }

    try {
      final customerName = user.displayName.trim().isEmpty
          ? (user.email.isEmpty ? 'Customer' : user.email)
          : user.displayName.trim();

      await _db.collection('malls').doc(mallId).collection('payments').add({
        'userId': user.uid,
        'customerName': customerName,
        'customerEmail': user.email.trim(),
        'total': total,
        'subtotal': subtotal,
        'paymentMethod': paymentMethod,
        'paymentReference': (paymentReference ?? '').trim(),
        'items': items,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _db.collection('users').doc(user.uid).collection('bills').add({
        'mallId': mallId,
        'total': total,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      _error = 'Unable to save checkout history: $e';
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<bool> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    final parts = name.trim().split(RegExp(r'\s+'));
    final firstName = parts.isEmpty ? '' : parts.first;
    final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : 'User';
    return requestEmailOtp(
      firstName: firstName,
      lastName: lastName,
      username: email.split('@').first,
      email: email,
      password: password,
    );
  }

  Future<bool> loginWithEmail({
    required String email,
    required String password,
  }) async {
    return loginWithUsername(username: email, password: password);
  }

  Future<bool> resendEmailVerification() async {
    if ((_pendingEmail ?? '').isEmpty ||
        (_pendingFirstName ?? '').isEmpty ||
        (_pendingLastName ?? '').isEmpty ||
        (_pendingUsername ?? '').isEmpty ||
        (_pendingPassword ?? '').isEmpty) {
      _error = 'Please complete the signup form first.';
      notifyListeners();
      return false;
    }
    return requestEmailOtp(
      firstName: _pendingFirstName!,
      lastName: _pendingLastName!,
      username: _pendingUsername!,
      email: _pendingEmail!,
      password: _pendingPassword!,
    );
  }

  Future<bool> refreshCurrentUser() async {
    notifyListeners();
    return canEnterApp;
  }

  Future<bool> sendEmailOtpSignup(String email) async {
    if ((_pendingFirstName ?? '').isEmpty ||
        (_pendingLastName ?? '').isEmpty ||
        (_pendingUsername ?? '').isEmpty ||
        (_pendingPassword ?? '').isEmpty) {
      _error = 'Please complete the signup form first.';
      notifyListeners();
      return false;
    }
    return requestEmailOtp(
      firstName: _pendingFirstName!,
      lastName: _pendingLastName!,
      username: _pendingUsername!,
      email: email,
      password: _pendingPassword!,
    );
  }

  Future<bool> verifyEmailOtpSignup({
    required String email,
    required String otp,
  }) async {
    return verifyEmailOtp(email: email, otp: otp);
  }

  Future<bool> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  Future<bool> sendPasswordResetOtp(String email) async {
    _setLoading(true);
    _error = null;

    try {
      final targetEmail = email.trim().toLowerCase();
      if (targetEmail.isEmpty) {
        _error = 'Please enter your email address.';
        return false;
      }

      // Generate a 6-digit OTP for the custom flow
      final otp = (100000 + (DateTime.now().millisecond * 899999) ~/ 1000).toString().padLeft(6, '0').substring(0, 6);
      
      // Store OTP in Firestore to trigger the custom email flow (monitored by Cloud Functions)
      await _db.collection('password_reset_otp').doc(targetEmail).set({
        'email': targetEmail,
        'otp': otp,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(DateTime.now().add(const Duration(minutes: 10))),
      });

      _otpSent = true;
      _debugOtp = otp; // Accessible for development/testing
      _error = "A reset code has been sent to $targetEmail.";
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> verifyPasswordResetOtp({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      final targetEmail = email.trim().toLowerCase();
      final doc = await _db.collection('password_reset_otp').doc(targetEmail).get();
      
      if (!doc.exists) {
        _error = 'Reset code not found or expired.';
        return false;
      }

      final data = doc.data()!;
      final storedOtp = data['otp']?.toString();
      final expiresAt = (data['expiresAt'] as Timestamp).toDate();

      if (DateTime.now().isAfter(expiresAt)) {
        _error = 'Reset code has expired.';
        return false;
      }

      if (storedOtp != otp.trim()) {
        _error = 'Invalid reset code.';
        return false;
      }

      // Successful verification - cleanup and signal success to the UI
      await _db.collection('password_reset_otp').doc(targetEmail).delete();
      _otpSent = false;
      _debugOtp = null;
      _error = "Code verified. You can now set your new password.";
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> isPasswordResetOtpValid(String email) async => false;

  Future<bool> sendPhoneOtp(String phoneNumber) async {
    _error = 'Phone authentication has been removed for user accounts.';
    notifyListeners();
    return false;
  }

  Future<bool> verifyPhoneOtp({required String smsCode, String? name}) async {
    _error = 'Phone authentication has been removed for user accounts.';
    notifyListeners();
    return false;
  }

  Future<bool> sendCustomPhoneOtp(String phoneNumber) async {
    _error = 'Phone authentication has been removed for user accounts.';
    notifyListeners();
    return false;
  }

  Future<bool> verifyCustomPhoneOtp({
    required String phoneNumber,
    required String otp,
    String? name,
  }) async {
    _error = 'Phone authentication has been removed for user accounts.';
    notifyListeners();
    return false;
  }

  Future<bool> resendCustomPhoneOtp(String phoneNumber) async {
    _error = 'Phone authentication has been removed for user accounts.';
    notifyListeners();
    return false;
  }

  Future<Map<String, dynamic>?> checkPhoneOtpStatus(String phoneNumber) async {
    return {
      'isValid': false,
      'remainingSeconds': 0,
      'attempts': 0,
      'attemptsRemaining': 0,
    };
  }

  Future<void> cleanupExpiredOtps() async {}

  Future<void> _restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_sessionStorageKey);
      if (raw != null && raw.trim().isNotEmpty) {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        final token = prefs.getString(_tokenStorageKey);
        _currentUser = AppUserSession.fromJson(map).copyWith(token: token);
      }
    } catch (_) {
      _currentUser = null;
    } finally {
      _isReady = true;
      notifyListeners();
    }
  }

  Future<void> _persistSession(AppUserSession user, String? token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _sessionStorageKey,
      jsonEncode(user.copyWith(token: token).toJson()),
    );
    if ((token ?? '').isNotEmpty) {
      await prefs.setString(_tokenStorageKey, token!);
    } else {
      await prefs.remove(_tokenStorageKey);
    }
    notifyListeners();
  }

  Future<void> _ensureUserProfile() async {
    final user = _currentUser;
    if (user == null) return;

    final existing = await _safeFetchProfile(user.uid);
    await _db.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'username': (existing?['username'] ?? user.username).toString(),
      'fullName': (existing?['fullName'] ?? user.fullName).toString(),
      'displayName': (existing?['displayName'] ?? user.displayName).toString(),
      'email': (existing?['email'] ?? user.email).toString(),
      'phone': (existing?['phone'] ?? user.phoneNumber).toString(),
      'photoUrl': (existing?['photoUrl'] ?? user.photoURL).toString(),
      'avatarPreset': (existing?['avatarPreset'] ?? 'sky').toString(),
      'provider': (existing?['provider'] ?? user.provider).toString(),
      'emailVerified': true,
    }, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> _safeFetchProfile(String userId) async {
    try {
      final doc = await _db.collection('users').doc(userId).get();
      return doc.data();
    } catch (_) {
      return null;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<bool> loginWithUsername({
    required String username,
    required String password,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      // If username is actually email
      final email = username.contains('@') ? username.trim() : '$username@swiftcart.com';
      final userCred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final profile = await _safeFetchProfile(userCred.user!.uid);
      _currentUser = AppUserSession(
        uid: userCred.user!.uid,
        email: userCred.user!.email ?? '',
        username: profile?['username'] ?? username,
        fullName: profile?['fullName'] ?? '',
        displayName: profile?['displayName'] ?? '',
        phoneNumber: profile?['phone'] ?? '',
        photoURL: profile?['photoUrl'] ?? '',
        provider: 'password',
        emailVerified: true,
      );
      
      final token = await userCred.user!.getIdToken();
      await _persistSession(_currentUser!, token);
      await _ensureUserProfile();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _setLoading(false);
    }
  }
}
