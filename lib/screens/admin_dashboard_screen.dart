import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import 'add_mall_screen.dart';
import 'mall_qr_library_screen.dart';
import 'mall_managers_screen.dart';
import 'manage_subscription_screen.dart';
import '../app/app.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Ensure malls are loaded when dashboard is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AdminProvider>();
      // Refetch malls if the list is empty to ensure data consistency
      if (provider.malls.isEmpty) {
        provider.refreshMalls();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Navigate to home instead of going back to login
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AppModeSelector()),
        );
        return false; // Prevent default back behavior
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
          elevation: 0,
          actions: [
            IconButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const MallQrLibraryScreen(),
                ),
              ),
              icon: const Icon(Icons.qr_code_2_outlined),
              tooltip: 'Mall QR library',
            ),
            IconButton(
              onPressed: _showLogoutDialog,
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
            ),
          ],
        ),
        body: Consumer<AdminProvider>(
          builder: (context, adminProvider, _) {
          if (adminProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final malls = adminProvider.malls;

          return RefreshIndicator(
            onRefresh: () async {
              // Refresh functionality - refetch malls from Firestore
              await context.read<AdminProvider>().refreshMalls();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome card
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome, ${adminProvider.currentAdmin?.name ?? 'Admin'}!',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Manage malls and subscriptions',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Stats row
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            title: 'Total Malls',
                            value: '${malls.length}',
                            icon: Icons.store_outlined,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            title: 'Active',
                            value: '${malls.where((m) => m.isActive).length}',
                            icon: Icons.check_circle_outline,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            title: 'Expiring Soon',
                            value: '${malls.where((m) => m.daysUntilExpiry < 30 && !m.isExpired).length}',
                            icon: Icons.warning_outlined,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AddMallScreen(),
                              ),
                            ).then((_) => setState(() {})),
                            icon: const Icon(Icons.add),
                            label: const Text('Add New Mall'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const MallQrLibraryScreen(),
                              ),
                            ),
                            icon: const Icon(Icons.print_outlined),
                            label: const Text('Mall QR Labels'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Malls list header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'All Malls',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (malls.isNotEmpty)
                          Text(
                            '${malls.length} total',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: Colors.grey),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Malls list
                    if (malls.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 48),
                          child: Column(
                            children: [
                              Icon(
                                Icons.store_outlined,
                                size: 48,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No malls yet',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: malls.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final mall = malls[index];
                          return _MallCard(
                            mall: mall,
                            onManage: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ManageSubscriptionScreen(mall: mall),
                              ),
                            ).then((_) => setState(() {})),
                            onManagers: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MallManagersScreen(mall: mall),
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<AdminProvider>().logout();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const AppModeSelector()),
              );
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _MallCard extends StatelessWidget {
  final dynamic mall;
  final VoidCallback onManage;
  final VoidCallback onManagers;

  const _MallCard({
    required this.mall,
    required this.onManage,
    required this.onManagers,
  });

  @override
  Widget build(BuildContext context) {
    final isExpired = mall.isExpired;
    final daysLeft = mall.daysUntilExpiry;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              mall.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: mall.isActive
                                  ? Colors.green[100]
                                  : Colors.red[100],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              mall.isActive ? 'Active' : 'Inactive',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: mall.isActive
                                    ? Colors.green[700]
                                    : Colors.red[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'ID: ${mall.mallId}',
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
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Plan: ${mall.planType.toUpperCase()}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Location: ${mall.city}, ${mall.state}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Subscription status
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isExpired
                    ? Colors.red[50]
                    : daysLeft < 30
                        ? Colors.orange[50]
                        : Colors.green[50],
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isExpired
                      ? Colors.red[200]!
                      : daysLeft < 30
                          ? Colors.orange[200]!
                          : Colors.green[200]!,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isExpired
                        ? Icons.cancel_outlined
                        : daysLeft < 30
                            ? Icons.warning_outlined
                            : Icons.check_circle_outline,
                    size: 16,
                    color: isExpired
                        ? Colors.red[700]
                        : daysLeft < 30
                            ? Colors.orange[700]
                            : Colors.green[700],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isExpired
                          ? 'Subscription Expired'
                          : 'Expires in $daysLeft days',
                      style: TextStyle(
                        fontSize: 12,
                        color: isExpired
                            ? Colors.red[700]
                            : daysLeft < 30
                                ? Colors.orange[700]
                                : Colors.green[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onManage,
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Manage Subscription'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onManagers,
                    icon: const Icon(Icons.group_outlined),
                    label: FutureBuilder<int>(
                      future: context
                          .read<AdminProvider>()
                          .getMallManagerCount(mall.mallId),
                      builder: (context, snapshot) {
                        final count = snapshot.data;
                        return Text(
                          count == null ? 'Managers' : 'Managers ($count)',
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onManage,
                    icon: const Icon(Icons.settings_outlined),
                    label: const Text('Manage Mall'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
          ],
        ),
      ),
    );
  }
}
