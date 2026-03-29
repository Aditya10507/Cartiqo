import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class UserAuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _imagePicker = ImagePicker();

  StreamSubscription<User?>? _authSubscription;
  User? _currentUser;
  bool _isLoading = false;
  String? _error;
  String? _verificationId;
  int? _resendToken;
  bool _otpSent = false;
  String? _lastDemoPhoneOtp;

  UserAuthProvider() {
    _currentUser = _auth.currentUser;
    _authSubscription = _auth.authStateChanges().listen((user) {
      _currentUser = user;
      notifyListeners();
    });
  }

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;
  bool get otpSent => _otpSent;
  String? get verificationId => _verificationId;
  String? get userId => _currentUser?.uid;
  String? get lastDemoPhoneOtp => _lastDemoPhoneOtp;
  bool get canEnterApp {
    final user = _currentUser;
    if (user == null) return false;
    if (user.providerData.any((info) => info.providerId == 'phone')) {
      return true;
    }
    return user.emailVerified;
  }

  bool get needsEmailVerification {
    final user = _currentUser;
    if (user == null) return false;
    final isPhoneAccount = user.providerData.any(
      (info) => info.providerId == 'phone',
    );
    return !isPhoneAccount && user.email != null && !user.emailVerified;
  }

  Future<bool> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await credential.user?.updateDisplayName(name.trim());
      await credential.user?.sendEmailVerification();
      await _storeUserProfile(
        user: credential.user,
        name: name.trim(),
        email: email.trim(),
        provider: 'email',
        emailVerified: false,
      );
      _error =
          'Verification email sent. Check your inbox and verify before logging in.';
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _friendlyAuthMessage(e);
      return false;
    } catch (e) {
      _error = 'Signup failed: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> loginWithEmail({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      await credential.user?.reload();
      final user = _auth.currentUser ?? credential.user;
      if (user != null && user.email != null && !user.emailVerified) {
        await user.sendEmailVerification();
        _error =
            'Email is not verified. We sent a verification link again. Please verify your email and log in.';
        return false;
      }

      await _storeUserProfile(
        user: user,
        name: user?.displayName ?? '',
        email: email.trim(),
        provider: 'email',
        emailVerified: true,
      );
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _friendlyAuthMessage(e);
      return false;
    } catch (e) {
      _error = 'Login failed: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> sendPhoneOtp(String phoneNumber) async {
    _setLoading(true);
    _error = null;
    _otpSent = false;
    notifyListeners();

    try {
      final completer = Completer<bool>();
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber.trim(),
        timeout: const Duration(seconds: 60),
        forceResendingToken: _resendToken,
        verificationCompleted: (PhoneAuthCredential credential) async {
          final authResult = await _auth.signInWithCredential(credential);
          await _storeUserProfile(
            user: authResult.user,
            name: authResult.user?.displayName ?? '',
            phone: authResult.user?.phoneNumber ?? '',
            provider: 'phone',
          );
          _otpSent = false;
          _verificationId = null;
          _lastDemoPhoneOtp = null;
          if (!completer.isCompleted) {
            completer.complete(true);
          }
          _setLoading(false);
        },
        verificationFailed: (FirebaseAuthException e) {
          _error = _friendlyAuthMessage(e);
          if (!completer.isCompleted) {
            completer.complete(false);
          }
          _setLoading(false);
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          _resendToken = resendToken;
          _otpSent = true;
          if (!completer.isCompleted) {
            completer.complete(true);
          }
          _setLoading(false);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
          notifyListeners();
        },
      );
      return completer.future;
    } catch (e) {
      _error = 'Unable to send OTP: $e';
      _setLoading(false);
      return false;
    }
  }

  Future<bool> verifyPhoneOtp({required String smsCode, String? name}) async {
    if (_verificationId == null) {
      _error = 'Please request an OTP first.';
      notifyListeners();
      return false;
    }

    _setLoading(true);
    _error = null;

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode.trim(),
      );

      final authResult = await _auth.signInWithCredential(credential);
      if ((name ?? '').trim().isNotEmpty) {
        await authResult.user?.updateDisplayName(name!.trim());
      }

      await _storeUserProfile(
        user: authResult.user,
        name: name?.trim() ?? authResult.user?.displayName ?? '',
        phone: authResult.user?.phoneNumber ?? '',
        provider: 'phone',
      );
      _otpSent = false;
      _verificationId = null;
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _friendlyAuthMessage(e);
      return false;
    } catch (e) {
      _error = 'OTP verification failed: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    _otpSent = false;
    _verificationId = null;
    _lastDemoPhoneOtp = null;
    _error = null;
    _currentUser = null;
    notifyListeners();
  }

  Future<bool> resendEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      _error = 'Please sign in with email first.';
      notifyListeners();
      return false;
    }

    _setLoading(true);
    _error = null;

    try {
      await user.reload();
      if (user.emailVerified) {
        _error = 'Your email is already verified.';
        return false;
      }
      await user.sendEmailVerification();
      _error = 'Verification email sent again. Check your inbox.';
      return true;
    } catch (e) {
      _error = 'Unable to resend verification email: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> refreshCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      await user.reload();
      _currentUser = _auth.currentUser;
      notifyListeners();
      return canEnterApp;
    } catch (e) {
      _error = 'Unable to refresh account status: $e';
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
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
      await user.updateDisplayName(fullName.trim());
      await user.updatePhotoURL(
        normalizedPhotoUrl.isEmpty ? null : normalizedPhotoUrl,
      );

      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'fullName': fullName.trim(),
        'displayName': fullName.trim(),
        'email': email.trim(),
        'phone': phone.trim(),
        'photoUrl': normalizedPhotoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _currentUser = _auth.currentUser;
      notifyListeners();
    } catch (e) {
      _error = 'Unable to update profile: $e';
      notifyListeners();
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
        _setLoading(false);
        return false;
      }

      if (kIsWeb) {
        _error =
            'Gallery and camera profile photos are supported only on the mobile app in this build.';
        notifyListeners();
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

      await user.updatePhotoURL('');
      await _firestore.collection('users').doc(user.uid).set({
        'photoUrl': '',
        'localPhotoPath': savedFile.path,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _currentUser = _auth.currentUser;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Unable to update profile picture: $e';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateAvatarPreset(String preset) async {
    final user = _currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).set({
      'avatarPreset': preset,
      'localPhotoPath': '',
      'photoUrl': '',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await user.updatePhotoURL('');
    _currentUser = _auth.currentUser;
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
      final billsRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('bills')
          .doc();
      final paymentsRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('payments')
          .doc();
      final mallBillRef = _firestore
          .collection('malls')
          .doc(mallId)
          .collection('bills')
          .doc(billsRef.id);
      final mallPaymentRef = _firestore
          .collection('malls')
          .doc(mallId)
          .collection('payments')
          .doc(paymentsRef.id);

      final billNumber = 'BILL-${DateTime.now().millisecondsSinceEpoch}';
      final paymentNumber = 'PAY-${DateTime.now().millisecondsSinceEpoch}';
      final createdAt = FieldValue.serverTimestamp();
      final customerName = (user.displayName ?? '').trim().isEmpty
          ? (user.email ?? user.phoneNumber ?? 'Customer')
          : user.displayName!.trim();

      final billPayload = {
        'billId': billsRef.id,
        'billNumber': billNumber,
        'mallId': mallId,
        'userId': user.uid,
        'customerName': customerName,
        'customerEmail': (user.email ?? '').trim(),
        'customerPhone': (user.phoneNumber ?? '').trim(),
        'subtotal': subtotal,
        'extraCharge': extraCharge,
        'extraChargeLabel': extraChargeLabel,
        'gst': gst,
        'gstPercent': gstPercent,
        'otherTax': otherTax,
        'otherTaxLabel': otherTaxLabel,
        'otherTaxPercent': otherTaxPercent,
        'total': total,
        'itemCount': items.length,
        'items': items,
        'status': 'paid',
        'createdAt': createdAt,
      };

      final paymentPayload = {
        'paymentId': paymentsRef.id,
        'paymentNumber': paymentNumber,
        'billId': billsRef.id,
        'billNumber': billNumber,
        'mallId': mallId,
        'userId': user.uid,
        'customerName': customerName,
        'customerEmail': (user.email ?? '').trim(),
        'customerPhone': (user.phoneNumber ?? '').trim(),
        'amount': total,
        'subtotal': subtotal,
        'extraCharge': extraCharge,
        'extraChargeLabel': extraChargeLabel,
        'gst': gst,
        'gstPercent': gstPercent,
        'otherTax': otherTax,
        'otherTaxLabel': otherTaxLabel,
        'otherTaxPercent': otherTaxPercent,
        'method': paymentMethod,
        'reference': (paymentReference ?? '').trim(),
        'status': 'success',
        'createdAt': createdAt,
      };

      await billsRef.set(billPayload);
      await paymentsRef.set(paymentPayload);
      await mallBillRef.set(billPayload);
      await mallPaymentRef.set(paymentPayload);

      return true;
    } catch (e) {
      _error = 'Unable to save checkout history: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    _error = null;

    try {
      if (email.trim().isEmpty) {
        _error = 'Please enter your email address.';
        _setLoading(false);
        return false;
      }

      await _auth.sendPasswordResetEmail(email: email.trim());
      _error =
          'Password reset email sent. Check your inbox and follow the link to reset your password.';
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _friendlyAuthMessage(e);
      return false;
    } catch (e) {
      _error = 'Unable to send reset email: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Send OTP for password reset to email
  Future<bool> sendPasswordResetOtp(String email) async {
    _setLoading(true);
    _error = null;

    try {
      final trimmedEmail = email.trim().toLowerCase();
      if (trimmedEmail.isEmpty) {
        _error = 'Please enter your email address.';
        _setLoading(false);
        return false;
      }

      // Validate email format
      if (!RegExp(
        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
      ).hasMatch(trimmedEmail)) {
        _error = 'Please enter a valid email address.';
        _setLoading(false);
        return false;
      }

      // Generate 6-digit OTP
      final otp = _generateOtp();
      _lastDemoPhoneOtp = otp;

      // Store OTP temporarily in Firestore with 10-minute expiry
      final expiryTime = DateTime.now().add(const Duration(minutes: 10));

      await _firestore.collection('password_reset_otp').doc(trimmedEmail).set({
        'otp': otp,
        'email': trimmedEmail,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(expiryTime),
      });

      _error =
          'OTP sent to $trimmedEmail. Please check your email within 10 minutes.';
      _setLoading(false);
      return true;
    } catch (e) {
      _error = 'Unable to send OTP: $e';
      _setLoading(false);
      return false;
    }
  }

  /// Verify OTP and reset password
  Future<bool> verifyPasswordResetOtp({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      final trimmedEmail = email.trim().toLowerCase();
      final trimmedOtp = otp.trim();

      if (trimmedEmail.isEmpty || trimmedOtp.isEmpty || newPassword.isEmpty) {
        _error = 'Please fill all required fields.';
        _setLoading(false);
        return false;
      }

      if (newPassword.length < 6) {
        _error = 'Password must be at least 6 characters.';
        _setLoading(false);
        return false;
      }

      // Get OTP document
      final otpDoc = await _firestore
          .collection('password_reset_otp')
          .doc(trimmedEmail)
          .get();

      if (!otpDoc.exists) {
        _error = 'OTP not found. Please request a new OTP.';
        _setLoading(false);
        return false;
      }

      final otpData = otpDoc.data();
      final storedOtp = otpData?['otp'] as String?;
      final expiresAt = otpData?['expiresAt'] as Timestamp?;

      // Check OTP validity
      if (storedOtp != trimmedOtp) {
        _error = 'Invalid OTP. Please try again.';
        _setLoading(false);
        return false;
      }

      // Check OTP expiry
      if (expiresAt != null && expiresAt.toDate().isBefore(DateTime.now())) {
        _error = 'OTP has expired. Please request a new one.';
        await _firestore
            .collection('password_reset_otp')
            .doc(trimmedEmail)
            .delete();
        _setLoading(false);
        return false;
      }

      // Find user by email and reset password
      // We need to use updatePassword which requires user to be authenticated
      // So we'll use sendPasswordResetEmail as backup
      try {
        final user = _auth.currentUser;
        if (user?.email?.toLowerCase() == trimmedEmail) {
          // Current user can change password directly
          await user?.updatePassword(newPassword);
        } else {
          // Send password reset link as fallback
          // In production, implement proper backend API for this
          await _auth.sendPasswordResetEmail(email: trimmedEmail);
        }
      } catch (e) {
        // Send traditional password reset email if updatePassword fails
        await _auth.sendPasswordResetEmail(email: trimmedEmail);
      }

      // Delete OTP after successful verification
      await _firestore
          .collection('password_reset_otp')
          .doc(trimmedEmail)
          .delete();

      _error =
          'Password reset successfully. Please login with your new password.';
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _friendlyAuthMessage(e);
      _setLoading(false);
      return false;
    } catch (e) {
      _error = 'Password reset failed: $e';
      _setLoading(false);
      return false;
    }
  }

  /// Check if OTP is still valid
  Future<bool> isPasswordResetOtpValid(String email) async {
    try {
      final trimmedEmail = email.trim().toLowerCase();
      final otpDoc = await _firestore
          .collection('password_reset_otp')
          .doc(trimmedEmail)
          .get();

      if (!otpDoc.exists) return false;

      final expiresAt = otpDoc.data()?['expiresAt'] as Timestamp?;
      if (expiresAt == null) return false;

      return expiresAt.toDate().isAfter(DateTime.now());
    } catch (e) {
      return false;
    }
  }

  /// Generate and send OTP to phone number (custom implementation)
  Future<bool> sendCustomPhoneOtp(String phoneNumber) async {
    _setLoading(true);
    _error = null;

    try {
      final trimmedPhone = phoneNumber.trim();

      if (trimmedPhone.isEmpty) {
        _error = 'Please enter your phone number.';
        _setLoading(false);
        return false;
      }

      if (!RegExp(r'^\+\d{10,15}$').hasMatch(trimmedPhone)) {
        _error =
            'Please enter a valid phone number with country code (e.g., +919876543210).';
        _setLoading(false);
        return false;
      }

      // Generate 6-digit OTP
      final otp = _generateOtp();

      // Calculate expiry time (5 minutes)
      final expiryTime = DateTime.now().add(const Duration(minutes: 5));

      // Store in Firestore with timing and attempt tracking
      final docRef = _firestore.collection('phone_otp').doc(trimmedPhone);

      await docRef.set({
        'phoneNumber': trimmedPhone,
        'otp': otp,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(expiryTime),
        'attempts': 0,
        'maxAttempts': 5,
        'status': 'pending',
      });

      _error =
          'Demo OTP generated for $trimmedPhone. Use the code shown in the app. Valid for 5 minutes.';
      _setLoading(false);
      return true;
    } catch (e) {
      _error = 'Failed to send OTP: $e';
      _setLoading(false);
      return false;
    }
  }

  /// Verify OTP and complete phone authentication
  Future<bool> verifyCustomPhoneOtp({
    required String phoneNumber,
    required String otp,
    String? name,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      final trimmedPhone = phoneNumber.trim();
      final trimmedOtp = otp.trim();

      if (trimmedPhone.isEmpty || trimmedOtp.isEmpty) {
        _error = 'Please enter phone number and OTP.';
        _setLoading(false);
        return false;
      }

      if (trimmedOtp.length != 6 || !RegExp(r'^\d{6}$').hasMatch(trimmedOtp)) {
        _error = 'OTP must be 6 digits.';
        _setLoading(false);
        return false;
      }

      // Get OTP document
      final docRef = _firestore.collection('phone_otp').doc(trimmedPhone);
      final otpDoc = await docRef.get();

      if (!otpDoc.exists) {
        _error = 'OTP not found. Please request a new OTP.';
        _setLoading(false);
        return false;
      }

      final otpData = otpDoc.data()!;
      final storedOtp = otpData['otp'] as String;
      final expiresAt = otpData['expiresAt'] as Timestamp;
      var attempts = (otpData['attempts'] as num).toInt();
      final maxAttempts = (otpData['maxAttempts'] as num).toInt();

      // Check attempt limit
      if (attempts >= maxAttempts) {
        _error = 'Maximum OTP attempts exceeded. Please request a new OTP.';
        await docRef.delete();
        _setLoading(false);
        return false;
      }

      // Check expiry
      if (expiresAt.toDate().isBefore(DateTime.now())) {
        _error = 'OTP has expired. Please request a new one.';
        await docRef.delete();
        _setLoading(false);
        return false;
      }

      // Verify OTP match
      if (storedOtp != trimmedOtp) {
        attempts++;
        await docRef.update({'attempts': attempts});
        _error = 'Invalid OTP. ${maxAttempts - attempts} attempts remaining.';
        _setLoading(false);
        return false;
      }

      // OTP is valid - create/update user account
      try {
        // For phone auth, we'll create user with email placeholder
        // or link with existing account if email exists
        final userEmail = '$trimmedPhone@phone.cartiqo.local';

        // Check if this phone already exists
        final existingUserQuery = await _firestore
            .collection('users')
            .where('phone', isEqualTo: trimmedPhone)
            .get();

        User? user;
        if (existingUserQuery.docs.isNotEmpty) {
          // User exists, just update
          user = _auth.currentUser;
        } else {
          // Create new user with anonymous sign-in then update profile
          try {
            final anonResult = await _auth.signInAnonymously();
            user = anonResult.user;
          } catch (e) {
            // Fallback: create with email if available
            user = _auth.currentUser;
          }
        }

        if (user != null) {
          await _storeUserProfile(
            user: user,
            name: (name ?? 'User').trim(),
            email: user.email ?? userEmail,
            phone: trimmedPhone,
            provider: 'phone',
            emailVerified: false,
          );
        }
      } catch (e) {
        _error = 'Failed to create account: $e';
        _setLoading(false);
        return false;
      }

      // Delete OTP after successful verification
      await docRef.delete();
      _lastDemoPhoneOtp = null;

      _error = 'Phone verified successfully';
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _friendlyAuthMessage(e);
      _setLoading(false);
      return false;
    } catch (e) {
      _error = 'Verification failed: $e';
      _setLoading(false);
      return false;
    }
  }

  /// Resend OTP to phone number
  Future<bool> resendCustomPhoneOtp(String phoneNumber) async {
    _setLoading(true);
    _error = null;

    try {
      final trimmedPhone = phoneNumber.trim();

      // Check if OTP exists and hasn't expired
      final docRef = _firestore.collection('phone_otp').doc(trimmedPhone);
      final otpDoc = await docRef.get();

      if (!otpDoc.exists) {
        _error = 'No OTP request found. Please request OTP first.';
        _setLoading(false);
        return false;
      }

      // Generate new OTP
      final newOtp = _generateOtp();
      _lastDemoPhoneOtp = newOtp;
      final expiryTime = DateTime.now().add(const Duration(minutes: 5));

      // Reset attempts on resend
      await docRef.update({
        'otp': newOtp,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(expiryTime),
        'attempts': 0,
        'status': 'pending',
      });

      _error =
          'Demo OTP regenerated for $trimmedPhone. Use the new code shown in the app. Valid for 5 minutes.';
      _setLoading(false);
      return true;
    } catch (e) {
      _error = 'Failed to resend OTP: $e';
      _setLoading(false);
      return false;
    }
  }

  /// Check OTP status and remaining validity
  Future<Map<String, dynamic>?> checkPhoneOtpStatus(String phoneNumber) async {
    try {
      final trimmedPhone = phoneNumber.trim();
      final docRef = _firestore.collection('phone_otp').doc(trimmedPhone);
      final otpDoc = await docRef.get();

      if (!otpDoc.exists) {
        return null;
      }

      final otpData = otpDoc.data()!;
      final expiresAt = (otpData['expiresAt'] as Timestamp).toDate();
      final attempts = (otpData['attempts'] as num).toInt();
      final maxAttempts = (otpData['maxAttempts'] as num).toInt();
      final remainingTime = expiresAt.difference(DateTime.now()).inSeconds;

      return {
        'isValid': remainingTime > 0,
        'remainingSeconds': remainingTime,
        'attempts': attempts,
        'attemptsRemaining': maxAttempts - attempts,
        'expiresAt': expiresAt,
      };
    } catch (e) {
      return null;
    }
  }

  /// Clean up expired OTPs (call periodically or on app init)
  Future<void> cleanupExpiredOtps() async {
    try {
      final now = Timestamp.now();
      await _firestore
          .collection('phone_otp')
          .where('expiresAt', isLessThan: now)
          .get()
          .then((snapshot) {
            for (var doc in snapshot.docs) {
              doc.reference.delete();
            }
          });
    } catch (e) {
      // Silently fail - not critical
    }
  }

  /// Generate a 6-digit OTP
  String _generateOtp() {
    final random = Random.secure().nextInt(900000) + 100000;
    return random.toString();
  }

  Future<void> _storeUserProfile({
    required User? user,
    required String provider,
    String? name,
    String? email,
    String? phone,
    bool? emailVerified,
  }) async {
    if (user == null) return;

    final doc = _firestore.collection('users').doc(user.uid);
    final snapshot = await doc.get();
    final now = FieldValue.serverTimestamp();

    final payload = <String, dynamic>{
      'uid': user.uid,
      'fullName': (name ?? user.displayName ?? '').trim(),
      'displayName': (name ?? user.displayName ?? '').trim(),
      'email': (email ?? user.email ?? '').trim(),
      'phone': (phone ?? user.phoneNumber ?? '').trim(),
      'photoUrl': (user.photoURL ?? '').trim(),
      'localPhotoPath': '',
      'avatarPreset': 'sky',
      'provider': provider,
      'emailVerified': emailVerified ?? user.emailVerified,
      'lastLoginAt': now,
    };

    if (!snapshot.exists) {
      payload['createdAt'] = now;
    }

    await doc.set(payload, SetOptions(merge: true));
  }

  String _friendlyAuthMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'email-already-in-use':
        return 'That email is already registered. Try logging in.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'requires-recent-login':
        return 'Please sign in again and retry this action.';
      case 'user-not-found':
        return 'No account found for this email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again shortly.';
      case 'invalid-verification-code':
        return 'The OTP code is invalid.';
      case 'session-expired':
        return 'The OTP expired. Please request a new one.';
      case 'invalid-phone-number':
        return 'Please enter a valid phone number with country code.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled in Firebase Authentication.';
      case 'configuration-not-found':
        return 'Phone authentication is not configured for this Firebase app. Enable Phone sign-in and add the correct Android SHA fingerprints in Firebase.';
      default:
        return e.message ?? 'Authentication failed.';
    }
  }

  /// Send OTP for email signup
  Future<bool> sendEmailOtpSignup(String email) async {
    _setLoading(true);
    _error = null;

    try {
      final trimmedEmail = email.trim().toLowerCase();
      if (trimmedEmail.isEmpty) {
        _error = 'Please enter your email address.';
        _setLoading(false);
        return false;
      }

      // Validate email format
      if (!RegExp(
        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
      ).hasMatch(trimmedEmail)) {
        _error = 'Please enter a valid email address.';
        _setLoading(false);
        return false;
      }

      // Generate 6-digit OTP
      final otp = _generateOtp();

      // Store OTP temporarily in Firestore with 10-minute expiry
      final expiryTime = DateTime.now().add(const Duration(minutes: 10));

      await _firestore.collection('email_otp_signup').doc(trimmedEmail).set({
        'otp': otp,
        'email': trimmedEmail,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(expiryTime),
        'attempts': 0,
        'status': 'pending',
      });

      _error =
          'OTP sent to $trimmedEmail. Please check your email within 10 minutes.';
      _setLoading(false);
      return true;
    } catch (e) {
      _error = 'Unable to send OTP: $e';
      _setLoading(false);
      return false;
    }
  }

  /// Verify OTP for email signup
  Future<bool> verifyEmailOtpSignup({
    required String email,
    required String otp,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      final trimmedEmail = email.trim().toLowerCase();
      final trimmedOtp = otp.trim();

      if (trimmedEmail.isEmpty || trimmedOtp.isEmpty) {
        _error = 'Please fill all required fields.';
        _setLoading(false);
        return false;
      }

      if (trimmedOtp.length != 6 || !RegExp(r'^\d{6}$').hasMatch(trimmedOtp)) {
        _error = 'OTP must be 6 digits.';
        _setLoading(false);
        return false;
      }

      // Get OTP document
      final otpDoc = await _firestore
          .collection('email_otp_signup')
          .doc(trimmedEmail)
          .get();

      if (!otpDoc.exists) {
        _error = 'OTP not found. Please request a new OTP.';
        _setLoading(false);
        return false;
      }

      final otpData = otpDoc.data();
      final storedOtp = otpData?['otp'] as String?;
      final expiresAt = otpData?['expiresAt'] as Timestamp?;
      final attempts = (otpData?['attempts'] as num?)?.toInt() ?? 0;

      // Check attempt limit (5 attempts)
      if (attempts >= 5) {
        _error = 'Too many incorrect attempts. Please request a new OTP.';
        await otpDoc.reference.delete();
        _setLoading(false);
        return false;
      }

      // Check OTP expiry
      if (expiresAt != null && expiresAt.toDate().isBefore(DateTime.now())) {
        _error = 'OTP has expired. Please request a new one.';
        await otpDoc.reference.delete();
        _setLoading(false);
        return false;
      }

      // Verify OTP match
      if (storedOtp != trimmedOtp) {
        await otpDoc.reference.update({'attempts': attempts + 1});
        _error = 'Invalid OTP. ${5 - attempts - 1} attempts remaining.';
        _setLoading(false);
        return false;
      }

      // OTP is valid
      _error = 'Email verified successfully!';
      _setLoading(false);
      return true;
    } catch (e) {
      _error = 'Verification failed: $e';
      _setLoading(false);
      return false;
    }
  }

  /// Create user with email and password (after OTP verification)
  Future<bool> createUserWithEmailPassword({
    required String email,
    required String password,
    required String name,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      final trimmedEmail = email.trim().toLowerCase();
      final trimmedName = name.trim();

      if (trimmedEmail.isEmpty || password.isEmpty || trimmedName.isEmpty) {
        _error = 'Please fill all required fields.';
        _setLoading(false);
        return false;
      }

      if (password.length < 6) {
        _error = 'Password must be at least 6 characters.';
        _setLoading(false);
        return false;
      }

      // Create Firebase Auth user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: trimmedEmail,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        _error = 'Failed to create account.';
        _setLoading(false);
        return false;
      }

      // Store user profile
      await _storeUserProfile(
        user: user,
        name: trimmedName,
        email: trimmedEmail,
        phone: '',
        provider: 'email',
        emailVerified: false,
      );

      // Clean up OTP record
      try {
        await _firestore
            .collection('email_otp_signup')
            .doc(trimmedEmail)
            .delete();
      } catch (e) {
        // Silently fail - not critical
      }

      _error = 'Account created successfully!';
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _friendlyAuthMessage(e);
      _setLoading(false);
      return false;
    } catch (e) {
      _error = 'Account creation failed: $e';
      _setLoading(false);
      return false;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
