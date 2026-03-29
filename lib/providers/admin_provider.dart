// ignore_for_file: avoid_print

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../models/admin.dart';
import '../models/mall_manager_account.dart';
import '../models/mall_subscription.dart';

class AdminProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Admin? _currentAdmin;
  List<MallSubscription> _malls = [];
  bool _isLoading = false;
  String? _error;

  Admin? get currentAdmin => _currentAdmin;
  List<MallSubscription> get malls => _malls;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Stream<List<Map<String, dynamic>>> watchAnnouncements() {
    return _firestore
        .collection('announcements')
        .orderBy('createdAt', descending: true)
        .limit(10)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList(),
        );
  }

  Future<bool> createAnnouncement({
    required String title,
    required String message,
    String audience = 'all',
  }) async {
    try {
      await _firestore.collection('announcements').add({
        'title': title.trim(),
        'message': message.trim(),
        'audience': audience,
        'createdBy': _currentAdmin?.email ?? _currentAdmin?.name ?? 'admin',
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      _error = 'Error creating announcement: $e';
      notifyListeners();
      return false;
    }
  }

  Stream<List<Map<String, dynamic>>> watchSupportRequests() {
    return _firestore
        .collection('support_requests')
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList(),
        );
  }

  Future<bool> updateSupportRequestStatus({
    required String requestId,
    required String status,
  }) async {
    try {
      await _firestore.collection('support_requests').doc(requestId).set({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return true;
    } catch (e) {
      _error = 'Error updating support request: $e';
      notifyListeners();
      return false;
    }
  }

  Stream<List<Map<String, dynamic>>> watchRecentMallPayments() {
    return _firestore
        .collectionGroup('payments')
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .where((doc) => doc.reference.parent.parent?.parent.id == 'malls')
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList(),
        );
  }

  Future<int> getMallManagerCount(String mallId) async {
    try {
      final query = _firestore
          .collection('malls')
          .doc(mallId)
          .collection('managers');

      try {
        final aggregate = await query.count().get();
        return aggregate.count ?? 0;
      } catch (_) {
        final snapshot = await query.get();
        return snapshot.size;
      }
    } catch (_) {
      return 0;
    }
  }

  Future<Map<String, int>> getMallManagerCounts(List<String> mallIds) async {
    final results = <String, int>{};
    await Future.wait(
      mallIds.map((mallId) async {
        results[mallId] = await getMallManagerCount(mallId);
      }),
    );
    return results;
  }

  Stream<List<MallManagerAccount>> watchMallManagers(String mallId) {
    return _firestore
        .collection('malls')
        .doc(mallId)
        .collection('managers')
        .orderBy('managerId')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            final merged = <String, dynamic>{
              ...data,
              'managerId': data['managerId'] ?? doc.id,
            };
            return MallManagerAccount.fromMap(mallId, merged);
          }).toList();
        });
  }

  Future<bool> createMallManager({
    required String mallId,
    required String managerId,
    required String password,
  }) async {
    _error = null;
    notifyListeners();

    try {
      final normalizedMallId = mallId.trim().toUpperCase();
      final normalizedManagerId = managerId.trim().toUpperCase();
      final trimmedPassword = password.trim();

      if (normalizedMallId.isEmpty ||
          normalizedManagerId.isEmpty ||
          trimmedPassword.isEmpty) {
        _error = 'Please enter mall ID, manager ID, and password';
        notifyListeners();
        return false;
      }

      if (trimmedPassword.length < 6) {
        _error = 'Password must be at least 6 characters';
        notifyListeners();
        return false;
      }

      final mallDoc = await _firestore
          .collection('malls')
          .doc(normalizedMallId)
          .get();
      if (!mallDoc.exists) {
        _error = 'Mall not found';
        notifyListeners();
        return false;
      }

      final managerIndexRef = _firestore
          .collection('manager_index')
          .doc(normalizedManagerId);
      final existingIndex = await managerIndexRef.get();
      if (existingIndex.exists) {
        final existingMall = (existingIndex.data()?['mallId'] ?? '')
            .toString()
            .trim();
        _error = existingMall.isEmpty
            ? 'Manager ID already exists'
            : 'Manager ID already exists in mall $existingMall';
        notifyListeners();
        return false;
      }

      final managerRef = _firestore
          .collection('malls')
          .doc(normalizedMallId)
          .collection('managers')
          .doc(normalizedManagerId);

      final existing = await managerRef.get();
      if (existing.exists) {
        _error = 'Manager ID already exists';
        notifyListeners();
        return false;
      }

      await managerRef.set({
        'mallId': normalizedMallId,
        'managerId': normalizedManagerId,
        'isActive': true,
        'assignedUid': null,
        'assignedEmail': null,
        'passwordHash': sha256.convert(utf8.encode(trimmedPassword)).toString(),
        'passwordUpdatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await managerIndexRef.set({
        'mallId': normalizedMallId,
        'managerId': normalizedManagerId,
        'isActive': true,
        'passwordHash': sha256.convert(utf8.encode(trimmedPassword)).toString(),
        'passwordUpdatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      _error = 'Error creating manager: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> resetMallManagerPassword({
    required String mallId,
    required String managerId,
    required String newPassword,
  }) async {
    _error = null;
    notifyListeners();

    try {
      final normalizedMallId = mallId.trim().toUpperCase();
      final normalizedManagerId = managerId.trim().toUpperCase();
      final trimmedPassword = newPassword.trim();

      if (trimmedPassword.length < 6) {
        _error = 'Password must be at least 6 characters';
        notifyListeners();
        return false;
      }

      await _firestore
          .collection('malls')
          .doc(normalizedMallId)
          .collection('managers')
          .doc(normalizedManagerId)
          .set({
            'passwordHash': sha256
                .convert(utf8.encode(trimmedPassword))
                .toString(),
            'passwordUpdatedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      await _firestore
          .collection('manager_index')
          .doc(normalizedManagerId)
          .set({
            'mallId': normalizedMallId,
            'managerId': normalizedManagerId,
            'passwordHash': sha256
                .convert(utf8.encode(trimmedPassword))
                .toString(),
            'passwordUpdatedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
      return true;
    } catch (e) {
      _error = 'Error resetting password: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> unlinkMallManager({
    required String mallId,
    required String managerId,
  }) async {
    _error = null;
    notifyListeners();

    try {
      final normalizedMallId = mallId.trim().toUpperCase();
      final normalizedManagerId = managerId.trim().toUpperCase();

      await _firestore
          .collection('malls')
          .doc(normalizedMallId)
          .collection('managers')
          .doc(normalizedManagerId)
          .set({
            'assignedUid': FieldValue.delete(),
            'assignedEmail': FieldValue.delete(),
            'linkedAt': FieldValue.delete(),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      return true;
    } catch (e) {
      _error = 'Error unlinking manager: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> setMallManagerActive({
    required String mallId,
    required String managerId,
    required bool isActive,
  }) async {
    _error = null;
    notifyListeners();

    try {
      final normalizedMallId = mallId.trim().toUpperCase();
      final normalizedManagerId = managerId.trim().toUpperCase();
      await _firestore
          .collection('malls')
          .doc(normalizedMallId)
          .collection('managers')
          .doc(normalizedManagerId)
          .set({
            'isActive': isActive,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      await _firestore
          .collection('manager_index')
          .doc(normalizedManagerId)
          .set({
            'mallId': normalizedMallId,
            'managerId': normalizedManagerId,
            'isActive': isActive,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
      return true;
    } catch (e) {
      _error = 'Error updating manager: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> adminLogin(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('=== ADMIN LOGIN ===');
      print('Email: $email');

      // Hash password
      final hashedPassword = sha256.convert(utf8.encode(password)).toString();

      // Query by email field
      final query = await _firestore
          .collection('admins')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        _error = 'Admin not found';
        _isLoading = false;
        print('ERROR: Admin not found');
        notifyListeners();
        return false;
      }

      final data = query.docs.first.data();
      if (data['passwordHash'] != hashedPassword) {
        _error = 'Invalid credentials';
        _isLoading = false;
        print('ERROR: Invalid password hash');
        notifyListeners();
        return false;
      }

      _currentAdmin = Admin.fromMap(data);
      print('✓ Admin authenticated: ${_currentAdmin?.name}');

      print('Fetching malls...');
      await _fetchMalls();

      _isLoading = false;
      print('✓ Login successful, malls count: ${_malls.length}');
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Login error: $e';
      print('ERROR during login: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  String _generateUniqueMallId({
    required String areaCode,
    required String mallNumber,
    required String mallCode,
    required String estYear,
  }) {
    // Format: AREACODE(6) + MALLNUMBER(2) + MALLCODE(2) + YEAR(2)
    // Ensure year is 2 digits
    String yearCode = estYear.length == 4 ? estYear.substring(2) : estYear;

    // Construct mall ID: 6 digits + 2 digits + 2 letters + 2 digits
    String mallId = '$areaCode$mallNumber${mallCode.toUpperCase()}$yearCode';

    return mallId;
  }

  Future<String?> generateNewMallId({
    required String areaCode,
    required String mallNumber,
    required String mallCode,
    required String estYear,
  }) async {
    try {
      String mallId;
      bool exists = true;

      do {
        mallId = _generateUniqueMallId(
          areaCode: areaCode,
          mallNumber: mallNumber,
          mallCode: mallCode,
          estYear: estYear,
        );
        final doc = await _firestore.collection('malls').doc(mallId).get();
        exists = doc.exists;
      } while (exists);

      return mallId;
    } catch (e) {
      _error = 'Error generating mall ID: $e';
      notifyListeners();
      return null;
    }
  }

  Future<bool> addNewMall(MallSubscription mall) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('=== ADDING NEW MALL ===');
      print('Mall ID: ${mall.mallId}');
      print('Mall Name: ${mall.name}');
      print('Subscription Start: ${mall.subscriptionStartDate}');
      print('Subscription End: ${mall.subscriptionEndDate}');

      // Update or create the mall document with subscription fields
      final mallData = {
        'mallId': mall.mallId,
        'name': mall.name,
        'ownerName': mall.ownerName,
        'ownerEmail': mall.ownerEmail,
        'city': mall.city,
        'state': mall.state,
        'subscriptionStartDate': mall.subscriptionStartDate,
        'subscriptionEndDate': mall.subscriptionEndDate,
        'planType': mall.planType,
        'maxProducts': mall.maxProducts,
        'isActive': mall.isActive,
        // Preserve existing fields if they exist
        if (mall.areaCode != null) 'areaCode': mall.areaCode,
        if (mall.estYear != null) 'estYear': mall.estYear,
        if (mall.mallCode != null) 'mallCode': mall.mallCode,
        if (mall.mallNumber != null) 'mallNumber': mall.mallNumber,
        if (mall.active != null) 'active': mall.active,
      };

      print('Saving mall data to Firestore...');

      // Update malls collection
      await _firestore
          .collection('malls')
          .doc(mall.mallId)
          .set(
            mallData,
            SetOptions(merge: true), // Merge with existing data
          );

      print('✓ Saved to malls collection');

      // Also save to mall_subscriptions for quick access
      await _firestore
          .collection('mall_subscriptions')
          .doc(mall.mallId)
          .set(mall.toMap());

      print('✓ Saved to mall_subscriptions collection');

      // Verify the mall was saved by fetching it back
      final savedDoc = await _firestore
          .collection('malls')
          .doc(mall.mallId)
          .get();
      if (!savedDoc.exists) {
        throw Exception('Mall was not saved to Firestore');
      }
      print('✓ Verified mall exists in Firestore');

      // Refresh the local list from Firestore to ensure consistency
      await _fetchMalls();

      _isLoading = false;
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error adding mall: $e';
      print('ERROR adding mall: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateMallSubscription(MallSubscription mall) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Update malls collection
      final updateData = {
        'name': mall.name,
        'ownerName': mall.ownerName,
        'ownerEmail': mall.ownerEmail,
        'city': mall.city,
        'state': mall.state,
        'subscriptionStartDate': mall.subscriptionStartDate,
        'subscriptionEndDate': mall.subscriptionEndDate,
        'planType': mall.planType,
        'maxProducts': mall.maxProducts,
        'isActive': mall.isActive,
      };

      await _firestore.collection('malls').doc(mall.mallId).update(updateData);

      // Also update mall_subscriptions
      await _firestore
          .collection('mall_subscriptions')
          .doc(mall.mallId)
          .set(mall.toMap(), SetOptions(merge: true));

      final index = _malls.indexWhere((m) => m.mallId == mall.mallId);
      if (index != -1) {
        _malls[index] = mall;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error updating subscription: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deactivateMall(String mallId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Update both collections
      await _firestore.collection('malls').doc(mallId).update({
        'isActive': false,
      });

      await _firestore.collection('mall_subscriptions').doc(mallId).update({
        'isActive': false,
      });

      final index = _malls.indexWhere((m) => m.mallId == mallId);
      if (index != -1) {
        final oldMall = _malls[index];
        _malls[index] = MallSubscription(
          mallId: oldMall.mallId,
          name: oldMall.name,
          ownerName: oldMall.ownerName,
          ownerEmail: oldMall.ownerEmail,
          city: oldMall.city,
          state: oldMall.state,
          subscriptionStartDate: oldMall.subscriptionStartDate,
          subscriptionEndDate: oldMall.subscriptionEndDate,
          planType: oldMall.planType,
          maxProducts: oldMall.maxProducts,
          isActive: false,
          createdAt: oldMall.createdAt,
          areaCode: oldMall.areaCode,
          estYear: oldMall.estYear,
          mallCode: oldMall.mallCode,
          mallNumber: oldMall.mallNumber,
          active: oldMall.active,
        );
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error deactivating mall: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> _fetchMalls() async {
    try {
      // Fetch all malls from the malls collection (your main collection)
      final mallsSnapshot = await _firestore.collection('malls').get();

      print('=== FETCHING MALLS ===');
      print('Found ${mallsSnapshot.docs.length} malls in Firestore');

      final mallsList = <MallSubscription>[];

      for (final doc in mallsSnapshot.docs) {
        final mallData = doc.data();

        print('Processing mall: ${doc.id}, data: $mallData');

        try {
          // Directly create MallSubscription from the data
          // The fromMap method now handles Timestamp conversion properly
          final mall = MallSubscription.fromMap(mallData);
          mallsList.add(mall);
          print('✓ Successfully parsed mall: ${mall.name}');
        } catch (parseError) {
          print('ERROR parsing mall ${doc.id}: $parseError');
          // Skip malformed malls but continue processing others
        }
      }

      _malls = mallsList;
      _error = null;
      print('✓ Successfully loaded ${mallsList.length} malls');
      notifyListeners();
    } catch (e) {
      _error = 'Error fetching malls: $e';
      print('ERROR fetching malls: $e');
      notifyListeners();
    }
  }

  void logout() {
    _currentAdmin = null;
    _malls = [];
    _error = null;
    notifyListeners();
  }

  Future<void> refreshMalls() async {
    await _fetchMalls();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
