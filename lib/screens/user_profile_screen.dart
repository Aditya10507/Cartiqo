import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../providers/user_auth_provider.dart';
import '../services/history_print_service.dart';
import '../services/user_profile_api_service.dart';

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<UserAuthProvider>();
    final user = authProvider.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('User not logged in')),
      );
    }

    final api = UserProfileApiService();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Profile'),
          centerTitle: false,
          backgroundColor: const Color(0xFFF4EFFD),
          surfaceTintColor: Colors.transparent,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Personal Info'),
              Tab(text: 'Previous Bills'),
              Tab(text: 'Payment History'),
            ],
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF4EFFD), Color(0xFFF9F7FF), Color(0xFFFFFFFF)],
            ),
          ),
          child: FutureBuilder<Map<String, dynamic>>(
            future: api.fetchProfile(user.uid),
            builder: (context, snapshot) {
              final data = snapshot.data ?? <String, dynamic>{};
              final fullName =
                  (data['fullName'] ?? user.displayName ?? 'Cartiqo User')
                      .toString();
              final email = (data['email'] ?? user.email ?? '').toString();
              final phone = (data['phone'] ?? user.phoneNumber ?? '').toString();
              final photoUrl =
                  (data['photoUrl'] ?? user.photoURL ?? '').toString();
              final localPhotoPath = (data['localPhotoPath'] ?? '').toString();
              final avatarPreset = (data['avatarPreset'] ?? 'sky').toString();
              final verified = (data['emailVerified'] ?? user.emailVerified) == true;

              return TabBarView(
                children: [
                  _PersonalInfoTab(
                    fullName: fullName,
                    email: email,
                    phone: phone,
                    photoUrl: photoUrl,
                    localPhotoPath: localPhotoPath,
                    avatarPreset: avatarPreset,
                    isVerified: verified,
                  ),
                  _BillsTab(userId: user.uid, customerName: fullName),
                  _PaymentsTab(userId: user.uid, customerName: fullName),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PersonalInfoTab extends StatelessWidget {
  final String fullName;
  final String email;
  final String phone;
  final String photoUrl;
  final String localPhotoPath;
  final String avatarPreset;
  final bool isVerified;

  const _PersonalInfoTab({
    required this.fullName,
    required this.email,
    required this.phone,
    required this.photoUrl,
    required this.localPhotoPath,
    required this.avatarPreset,
    required this.isVerified,
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<UserAuthProvider>();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0B5ED7), Color(0xFF12B886)],
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [
              BoxShadow(
                color: Color(0x220B5ED7),
                blurRadius: 24,
                offset: Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            children: [
              _ProfileAvatar(
                fullName: fullName,
                photoUrl: photoUrl,
                localPhotoPath: localPhotoPath,
                avatarPreset: avatarPreset,
                radius: 48,
              ),
              const SizedBox(height: 14),
              Text(
                fullName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                email.isEmpty ? 'No email added' : email,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  _StatusChip(
                    icon: isVerified ? Icons.verified_outlined : Icons.mail_outline,
                    label: isVerified ? 'Verified' : 'Pending verification',
                  ),
                  _StatusChip(
                    icon: Icons.phone_outlined,
                    label: phone.isEmpty ? 'No phone' : 'Phone linked',
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Customize your look',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Choose an avatar style or set a photo from your gallery or camera.',
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: _avatarPresets.map((preset) {
                    final isSelected = avatarPreset == preset.key &&
                        localPhotoPath.isEmpty &&
                        photoUrl.isEmpty;
                    return InkWell(
                      borderRadius: BorderRadius.circular(30),
                      onTap: () => _setAvatarPreset(context, preset.key),
                      child: CircleAvatar(
                        radius: isSelected ? 28 : 24,
                        backgroundColor: preset.color,
                        child: Text(
                          fullName.isEmpty ? 'U' : fullName[0].toUpperCase(),
                          style: TextStyle(
                            color: preset.textColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 24,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.deepPurple,
                        side: const BorderSide(color: Colors.deepPurple),
                      ),
                      onPressed: authProvider.isLoading
                          ? null
                          : () => _updateProfilePicture(
                                context,
                                ImageSource.gallery,
                              ),
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Gallery'),
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.deepPurple,
                        side: const BorderSide(color: Colors.deepPurple),
                      ),
                      onPressed: authProvider.isLoading
                          ? null
                          : () => _updateProfilePicture(
                                context,
                                ImageSource.camera,
                              ),
                      icon: const Icon(Icons.photo_camera_outlined),
                      label: const Text('Camera'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => _showEditDialog(context),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit Profile'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        const _SectionTitle(text: 'Personal Info'),
        _InfoCard(title: 'Full Name', value: fullName),
        _InfoCard(title: 'Phone Number', value: phone.isEmpty ? 'Not added' : phone),
        _InfoCard(title: 'Email Address', value: email.isEmpty ? 'Not added' : email),
      ],
    );
  }

  Future<void> _updateProfilePicture(
    BuildContext context,
    ImageSource source,
  ) async {
    final provider = context.read<UserAuthProvider>();
    final success = await provider.updateProfilePicture(source);

    if (!context.mounted) return;

    if (!success) {
      if (provider.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.error!)),
        );
      }
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          source == ImageSource.camera
              ? 'Profile picture updated from camera'
              : 'Profile picture updated from gallery',
        ),
      ),
    );
  }

  Future<void> _setAvatarPreset(BuildContext context, String preset) async {
    await context.read<UserAuthProvider>().updateAvatarPreset(preset);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Avatar updated')),
    );
  }

  Future<void> _showEditDialog(BuildContext context) async {
    final nameController = TextEditingController(text: fullName);
    final phoneController = TextEditingController(text: phone);
    final emailController = TextEditingController(text: email);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email Address'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await context.read<UserAuthProvider>().updateUserProfile(
                    fullName: nameController.text.trim(),
                    phone: phoneController.text.trim(),
                    email: emailController.text.trim(),
                    photoUrl: photoUrl,
                  );
              if (!context.mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile updated')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _BillsTab extends StatelessWidget {
  final String userId;
  final String customerName;

  const _BillsTab({required this.userId, required this.customerName});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: UserProfileApiService().fetchBills(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Unable to load bills: ${snapshot.error}'));
        }

        final docs = snapshot.data ?? [];
        if (docs.isEmpty) {
          return const Center(child: Text('No previous bills yet'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final bill = docs[index];
            final items = (bill['items'] as List<dynamic>? ?? []);
            final subtotal = (bill['subtotal'] ?? 0).toString();
            final extraCharge = (bill['extraCharge'] ?? bill['handlingFee'] ?? 0)
                .toString();
            final extraChargeLabel =
                (bill['extraChargeLabel'] ?? 'Extra Charges').toString();
            final gst = (bill['gst'] ?? 0).toString();
            final otherTax = (bill['otherTax'] ?? 0).toString();
            final otherTaxLabel = (bill['otherTaxLabel'] ?? 'Tax').toString();

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (bill['billNumber'] ?? 'Bill').toString(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text('Mall ID: ${(bill['mallId'] ?? '').toString()}'),
                    Text('Total: Rs ${(bill['total'] ?? 0).toString()}'),
                    Text('Items: ${items.length}'),
                    Text('Subtotal: Rs $subtotal'),
                    Text('$extraChargeLabel: Rs $extraCharge'),
                    Text('GST: Rs $gst'),
                    if (otherTax != '0') Text('$otherTaxLabel: Rs $otherTax'),
                    const SizedBox(height: 8),
                    ...items.take(4).map((item) {
                      final row = Map<String, dynamic>.from(item as Map);
                      return Text(
                        '${row['name']} x${row['qty']} - Rs ${row['lineTotal']}',
                        style: TextStyle(color: Colors.grey[700]),
                      );
                    }),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          try {
                            await HistoryPrintService.printBill(
                              bill: bill,
                              customerName: customerName,
                            );
                          } catch (_) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Unable to open the bill print dialog right now.',
                                ),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.print_outlined),
                        label: const Text('Print Bill'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _PaymentsTab extends StatelessWidget {
  final String userId;
  final String customerName;

  const _PaymentsTab({required this.userId, required this.customerName});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: UserProfileApiService().fetchPayments(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Unable to load payments: ${snapshot.error}'),
          );
        }

        final docs = snapshot.data ?? [];
        if (docs.isEmpty) {
          return const Center(child: Text('No payment history yet'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final payment = docs[index];
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: Colors.green[100],
                        child: Icon(Icons.receipt_long, color: Colors.green[700]),
                      ),
                      title: Text((payment['paymentNumber'] ?? 'Payment').toString()),
                      subtitle: Text(
                        'Method: ${(payment['method'] ?? '').toString()}\nBill: ${(payment['billNumber'] ?? '').toString()}',
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Rs ${(payment['amount'] ?? 0).toString()}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            (payment['status'] ?? 'success').toString(),
                            style: TextStyle(color: Colors.green[700], fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    if ((payment['gst'] ?? 0).toString() != '0' ||
                        (payment['otherTax'] ?? 0).toString() != '0' ||
                        (payment['extraCharge'] ?? 0).toString() != '0')
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          children: [
                            if ((payment['extraCharge'] ?? 0).toString() != '0')
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  '${(payment['extraChargeLabel'] ?? 'Extra Charges').toString()}: Rs ${(payment['extraCharge'] ?? 0).toString()}',
                                ),
                              ),
                            if ((payment['gst'] ?? 0).toString() != '0')
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text('GST: Rs ${(payment['gst'] ?? 0).toString()}'),
                              ),
                            if ((payment['otherTax'] ?? 0).toString() != '0')
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  '${(payment['otherTaxLabel'] ?? 'Tax').toString()}: Rs ${(payment['otherTax'] ?? 0).toString()}',
                                ),
                              ),
                          ],
                        ),
                      ),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          try {
                            await HistoryPrintService.printPayment(
                              payment: payment,
                              customerName: customerName,
                            );
                          } catch (_) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Unable to open the payment print dialog right now.',
                                ),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.print_outlined),
                        label: const Text('Print Receipt'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String value;

  const _InfoCard({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        title: Text(title),
        subtitle: Text(value),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatusChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18, color: Colors.white),
      label: Text(label),
      labelStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w700,
      ),
      backgroundColor: const Color(0xFF0B1220).withValues(alpha: 0.28),
      side: BorderSide(color: Colors.white.withValues(alpha: 0.20)),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final String fullName;
  final String photoUrl;
  final String localPhotoPath;
  final String avatarPreset;
  final double radius;

  const _ProfileAvatar({
    required this.fullName,
    required this.photoUrl,
    required this.localPhotoPath,
    required this.avatarPreset,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb && localPhotoPath.isNotEmpty && File(localPhotoPath).existsSync()) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: FileImage(File(localPhotoPath)),
      );
    }

    if (photoUrl.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(photoUrl),
      );
    }

    final initials = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();

    final preset = _avatarPresets.firstWhere(
      (item) => item.key == avatarPreset,
      orElse: () => _avatarPresets.first,
    );

    return CircleAvatar(
      radius: radius,
      backgroundColor: preset.color,
      child: Text(
        initials.isEmpty ? 'U' : initials,
        style: TextStyle(
          fontSize: radius * 0.55,
          fontWeight: FontWeight.w700,
          color: preset.textColor,
        ),
      ),
    );
  }
}

class _AvatarPreset {
  final String key;
  final Color color;
  final Color textColor;

  const _AvatarPreset({
    required this.key,
    required this.color,
    required this.textColor,
  });
}

const List<_AvatarPreset> _avatarPresets = [
  _AvatarPreset(
    key: 'sky',
    color: Color(0xFFB3D9FF),
    textColor: Color(0xFF0D47A1),
  ),
  _AvatarPreset(
    key: 'mint',
    color: Color(0xFFB8F2D6),
    textColor: Color(0xFF00695C),
  ),
  _AvatarPreset(
    key: 'sunset',
    color: Color(0xFFFFCCBC),
    textColor: Color(0xFFBF360C),
  ),
  _AvatarPreset(
    key: 'lavender',
    color: Color(0xFFDCCDFE),
    textColor: Color(0xFF4527A0),
  ),
  _AvatarPreset(
    key: 'slate',
    color: Color(0xFFCFD8DC),
    textColor: Color(0xFF263238),
  ),
];
