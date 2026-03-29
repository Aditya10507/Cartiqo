import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/admin_provider.dart';

class MallManagerDetailsScreen extends StatelessWidget {
  final String mallId;
  final String managerId;

  const MallManagerDetailsScreen({
    super.key,
    required this.mallId,
    required this.managerId,
  });

  @override
  Widget build(BuildContext context) {
    final ref = FirebaseFirestore.instance
        .collection('malls')
        .doc(mallId)
        .collection('managers')
        .doc(managerId);

    return Scaffold(
      appBar: AppBar(title: Text('Manager • $managerId'), elevation: 0),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: ref.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final doc = snapshot.data!;
          if (!doc.exists) {
            return const Center(child: Text('Manager not found'));
          }

          final data = doc.data() ?? {};
          final assignedEmail = (data['assignedEmail'] ?? '').toString();
          final fullName = (data['fullName'] ?? '').toString();
          final phoneNumber = (data['phoneNumber'] ?? '').toString();
          final isActive = data['isActive'] == null
              ? true
              : data['isActive'] == true;
          final doj = data['dateOfJoining'];
          DateTime? joiningDate;
          if (doj is Timestamp) {
            joiningDate = doj.toDate();
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Personal Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _InfoRow(label: 'Mall ID', value: mallId),
                      _InfoRow(label: 'Manager ID', value: managerId),
                      _InfoRow(
                        label: 'Email',
                        value: assignedEmail.isEmpty ? '-' : assignedEmail,
                      ),
                      _InfoRow(
                        label: 'Full Name',
                        value: fullName.isEmpty ? '-' : fullName,
                      ),
                      _InfoRow(
                        label: 'Phone Number',
                        value: phoneNumber.isEmpty ? '-' : phoneNumber,
                      ),
                      _InfoRow(
                        label: 'Date of Joining',
                        value: joiningDate == null
                            ? '-'
                            : _formatDate(joiningDate),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Card(
                elevation: 0,
                color: Colors.blueGrey.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _StatusChip(active: isActive),
                      TextButton.icon(
                        onPressed: () async {
                          final passwordCtrl = TextEditingController();
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('Reset $managerId Password'),
                              content: TextField(
                                controller: passwordCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'New password',
                                  hintText: 'At least 6 characters',
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Reset'),
                                ),
                              ],
                            ),
                          );
                          if (confirmed != true) return;

                          final ok = await context
                              .read<AdminProvider>()
                              .resetMallManagerPassword(
                                mallId: mallId,
                                managerId: managerId,
                                newPassword: passwordCtrl.text,
                              );
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                ok
                                    ? 'Password reset successfully'
                                    : context.read<AdminProvider>().error ??
                                          'Password reset failed',
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.password_outlined),
                        label: const Text('Reset Password'),
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          final ok = await context
                              .read<AdminProvider>()
                              .unlinkMallManager(
                                mallId: mallId,
                                managerId: managerId,
                              );
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                ok
                                    ? 'Manager unlinked'
                                    : context.read<AdminProvider>().error ??
                                          'Unlink failed',
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.link_off_outlined),
                        label: const Text('Unlink Email'),
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          final ok = await context
                              .read<AdminProvider>()
                              .setMallManagerActive(
                                mallId: mallId,
                                managerId: managerId,
                                isActive: !isActive,
                              );
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                ok
                                    ? (!isActive
                                          ? 'Manager enabled'
                                          : 'Manager disabled')
                                    : context.read<AdminProvider>().error ??
                                          'Update failed',
                              ),
                            ),
                          );
                        },
                        icon: Icon(
                          isActive
                              ? Icons.pause_circle_outline
                              : Icons.play_circle_outline,
                        ),
                        label: Text(isActive ? 'Disable' : 'Enable'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static String _formatDate(DateTime date) {
    final mm = date.month.toString().padLeft(2, '0');
    final dd = date.day.toString().padLeft(2, '0');
    return '${date.year}-$mm-$dd';
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF526075),
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontFamily: 'monospace')),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool active;

  const _StatusChip({required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: active ? Colors.green[100] : Colors.red[100],
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        active ? 'Active' : 'Disabled',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: active ? Colors.green[800] : Colors.red[800],
        ),
      ),
    );
  }
}
