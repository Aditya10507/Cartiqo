import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/mall_manager_account.dart';
import '../models/mall_subscription.dart';
import '../providers/admin_provider.dart';
import 'mall_manager_details_screen.dart';

class MallManagersScreen extends StatelessWidget {
  final MallSubscription mall;

  const MallManagersScreen({super.key, required this.mall});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Managers • ${mall.name}'), elevation: 0),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddManagerDialog(context),
        icon: const Icon(Icons.person_add_alt_1_outlined),
        label: const Text('Add Manager'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    const Icon(Icons.store_outlined),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mall.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Mall ID: ${mall.mallId}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'All Managers',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<List<MallManagerAccount>>(
                stream: context.read<AdminProvider>().watchMallManagers(
                  mall.mallId,
                ),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final managers = snapshot.data!;
                  if (managers.isEmpty) {
                    return const Center(child: Text('No managers created yet'));
                  }

                  return ListView.separated(
                    itemCount: managers.length,
                    separatorBuilder: (_, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final m = managers[index];
                      final linkedEmail = (m.assignedEmail ?? '').trim();
                      final subtitle = linkedEmail.isEmpty
                          ? 'Not linked yet'
                          : 'Linked: $linkedEmail';

                      return Card(
                        elevation: 1,
                        child: ListTile(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => MallManagerDetailsScreen(
                                mallId: mall.mallId,
                                managerId: m.managerId,
                              ),
                            ),
                          ),
                          leading: CircleAvatar(
                            backgroundColor: m.isActive
                                ? Colors.green[50]
                                : Colors.red[50],
                            child: Icon(
                              Icons.badge_outlined,
                              color: m.isActive ? Colors.green : Colors.red,
                            ),
                          ),
                          title: Text(
                            m.managerId,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          subtitle: Text(subtitle),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _StatusChip(active: m.isActive),
                              const SizedBox(width: 8),
                              PopupMenuButton<String>(
                                tooltip: 'Actions',
                                onSelected: (value) async {
                                  if (value == 'unlink') {
                                    final adminProvider =
                                        context.read<AdminProvider>();
                                    final messenger =
                                        ScaffoldMessenger.of(context);
                                    final shouldUnlink = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Unlink Manager ID'),
                                        content: Text(
                                          linkedEmail.isEmpty
                                              ? 'This Manager ID is not linked to any email.'
                                              : 'Unlink ${m.managerId} from $linkedEmail?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            child: const Text(
                                              'Unlink',
                                              style: TextStyle(
                                                color: Colors.red,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (shouldUnlink != true) return;

                                    final ok = await adminProvider
                                        .unlinkMallManager(
                                      mallId: mall.mallId,
                                      managerId: m.managerId,
                                    );
                                    if (!context.mounted) return;
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          ok
                                              ? 'Manager unlinked'
                                              : adminProvider.error ??
                                                  'Unlink failed',
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  if (value == 'toggle') {
                                    final ok = await context
                                        .read<AdminProvider>()
                                        .setMallManagerActive(
                                          mallId: mall.mallId,
                                          managerId: m.managerId,
                                          isActive: !m.isActive,
                                        );
                                    if (!context.mounted) return;
                                    if (!ok) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            context
                                                    .read<AdminProvider>()
                                                    .error ??
                                                'Update failed',
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                },
                                itemBuilder: (_) => [
                                  const PopupMenuItem(
                                    value: 'unlink',
                                    child: ListTile(
                                      dense: true,
                                      leading: Icon(Icons.link_off_outlined),
                                      title: Text('Unlink Email'),
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'toggle',
                                    child: ListTile(
                                      dense: true,
                                      leading: Icon(
                                        m.isActive
                                            ? Icons.pause_circle_outline
                                            : Icons.play_circle_outline,
                                      ),
                                      title: Text(
                                        m.isActive ? 'Disable' : 'Enable',
                                      ),
                                    ),
                                  ),
                                ],
                                child: const Icon(Icons.more_vert),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddManagerDialog(BuildContext context) async {
    final managerIdCtrl = TextEditingController();
    final adminProvider = context.read<AdminProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add Mall Manager'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: managerIdCtrl,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Manager ID',
                  hintText: 'e.g., MGR01',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Tip: After creation, link the manager email from the admin panel. The mall manager will sign in using email OTP.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final ok = await adminProvider.createMallManager(
                mallId: mall.mallId,
                managerId: managerIdCtrl.text,
              );
              if (!ok) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      adminProvider.error ?? 'Failed to add manager',
                    ),
                  ),
                );
                return;
              }
              navigator.pop();
            },
            child: const Text('Create'),
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
