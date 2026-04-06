// ignore_for_file: use_null_aware_elements

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/mall_manager_account.dart';
import '../models/mall_subscription.dart';
import '../providers/admin_provider.dart';
import 'mall_manager_details_screen.dart';
import 'manage_subscription_screen.dart';

class MallDetailsScreen extends StatelessWidget {
  final MallSubscription mall;

  const MallDetailsScreen({super.key, required this.mall});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(mall.name), elevation: 0),
      body: StreamBuilder<List<MallManagerAccount>>(
        stream: context.read<AdminProvider>().watchMallManagers(mall.mallId),
        builder: (context, snapshot) {
          final managers = snapshot.data ?? const <MallManagerAccount>[];
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SectionCard(
                title: 'Mall Details',
                child: Column(
                  children: [
                    _DetailRow(label: 'Mall ID', value: mall.mallId),
                    _DetailRow(label: 'Mall Name', value: mall.name),
                    _DetailRow(
                      label: 'Owner Name',
                      value: mall.ownerName?.trim().isNotEmpty == true
                          ? mall.ownerName!
                          : '-',
                    ),
                    _DetailRow(
                      label: 'Owner Email',
                      value: mall.ownerEmail?.trim().isNotEmpty == true
                          ? mall.ownerEmail!
                          : '-',
                    ),
                    _DetailRow(
                      label: 'Location',
                      value:
                          '${mall.city?.trim().isNotEmpty == true ? mall.city : '-'}, ${mall.state?.trim().isNotEmpty == true ? mall.state : '-'}',
                    ),
                    _DetailRow(
                      label: 'Created',
                      value: _formatDate(mall.createdAt),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Subscription',
                child: Column(
                  children: [
                    _DetailRow(
                      label: 'Plan',
                      value: mall.planType.toUpperCase(),
                    ),
                    _DetailRow(
                      label: 'Status',
                      value: mall.isExpired
                          ? 'Expired'
                          : (mall.isActive ? 'Active' : 'Inactive'),
                    ),
                    _DetailRow(
                      label: 'Start Date',
                      value: _formatDate(mall.subscriptionStartDate),
                    ),
                    _DetailRow(
                      label: 'End Date',
                      value: _formatDate(mall.subscriptionEndDate),
                    ),
                    _DetailRow(
                      label: 'Days Until Expiry',
                      value: '${mall.daysUntilExpiry}',
                    ),
                    _DetailRow(
                      label: 'Max Products',
                      value: '${mall.maxProducts}',
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                ManageSubscriptionScreen(mall: mall),
                          ),
                        ),
                        icon: const Icon(Icons.manage_accounts_outlined),
                        label: const Text('Manage Subscription'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Mall Managers',
                action: FilledButton.tonalIcon(
                  onPressed: () => _showAddManagerDialog(context),
                  icon: const Icon(Icons.person_add_alt_1_outlined),
                  label: const Text('Add Manager'),
                ),
                child: managers.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text('No managers created for this mall yet.'),
                      )
                    : Column(
                        children: [
                          for (final manager in managers) ...[
                            _ManagerTile(mall: mall, manager: manager),
                            if (manager != managers.last)
                              const SizedBox(height: 10),
                          ],
                        ],
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showAddManagerDialog(BuildContext context) async {
    final managerIdCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Mall Manager'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: managerIdCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Manager ID',
                hintText: 'e.g. MGR01',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'After creation, link the manager email from the admin panel. The manager will sign in using email OTP.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final ok = await context.read<AdminProvider>().createMallManager(
                mallId: mall.mallId,
                managerId: managerIdCtrl.text,
              );
              if (!context.mounted) return;
              if (ok) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Manager created')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      context.read<AdminProvider>().error ??
                          'Failed to create manager',
                    ),
                  ),
                );
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? action;

  const _SectionCard({required this.title, required this.child, this.action});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (action != null) action!,
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

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
                color: Color(0xFF5F6C7C),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _ManagerTile extends StatelessWidget {
  final MallSubscription mall;
  final MallManagerAccount manager;

  const _ManagerTile({required this.mall, required this.manager});

  @override
  Widget build(BuildContext context) {
    final linkedEmail = manager.assignedEmail?.trim().isNotEmpty == true
        ? manager.assignedEmail!
        : 'Not linked yet';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  manager.managerId,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: manager.isActive ? Colors.green[100] : Colors.red[100],
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  manager.isActive ? 'Active' : 'Disabled',
                  style: TextStyle(
                    color: manager.isActive
                        ? Colors.green.shade800
                        : Colors.red.shade800,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(linkedEmail, style: const TextStyle(color: Color(0xFF5F6C7C))),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => MallManagerDetailsScreen(
                      mallId: mall.mallId,
                      managerId: manager.managerId,
                    ),
                  ),
                ),
                child: const Text('View Details'),
              ),
              TextButton(
                onPressed: () async {
                  final ok = await context
                      .read<AdminProvider>()
                      .setMallManagerActive(
                        mallId: mall.mallId,
                        managerId: manager.managerId,
                        isActive: !manager.isActive,
                      );
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        ok
                            ? (manager.isActive
                                  ? 'Manager disabled'
                                  : 'Manager enabled')
                            : context.read<AdminProvider>().error ??
                                  'Update failed',
                      ),
                    ),
                  );
                },
                child: Text(manager.isActive ? 'Disable' : 'Enable'),
              ),
              TextButton(
                onPressed: () async {
                  final ok = await context
                      .read<AdminProvider>()
                      .unlinkMallManager(
                        mallId: mall.mallId,
                        managerId: manager.managerId,
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
                child: const Text('Unlink'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
