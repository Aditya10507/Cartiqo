import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/app.dart';
import '../models/mall_subscription.dart';
import '../providers/admin_provider.dart';
import '../services/csv_service.dart';
import '../services/file_download_service.dart';
import '../widgets/swiftcart_logo.dart';
import 'add_mall_screen.dart';
import 'mall_details_screen.dart';
import 'mall_managers_screen.dart';
import 'mall_qr_library_screen.dart';
import 'manage_subscription_screen.dart';

class WebAdminDashboardScreen extends StatefulWidget {
  const WebAdminDashboardScreen({super.key});

  @override
  State<WebAdminDashboardScreen> createState() =>
      _WebAdminDashboardScreenState();
}

class _WebAdminDashboardScreenState extends State<WebAdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().refreshMalls();
    });
  }

  Future<void> _exportMallReport(
    BuildContext context,
    AdminProvider provider,
  ) async {
    final malls = provider.malls;
    if (malls.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No mall data to export')));
      return;
    }

    final managerCounts = await provider.getMallManagerCounts(
      malls.map((mall) => mall.mallId).toList(),
    );
    final csv = CsvService.exportMallSubscriptionsToCsv(malls, managerCounts);
    final now = DateTime.now();
    final filename =
        'cartiqo_mall_report_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}.csv';

    final ok = await downloadTextFile(
      filename: filename,
      content: csv,
      mimeType: 'text/csv;charset=utf-8',
    );

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'CSV report download started'
              : 'CSV download is only supported in web browsers',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, provider, _) {
        final malls = provider.malls;
        final active = malls.where((mall) => mall.isActive).length;
        final expiring = malls
            .where((mall) => mall.daysUntilExpiry < 30 && !mall.isExpired)
            .length;
        final expired = malls.where((mall) => mall.isExpired).length;
        final basicPlans = malls
            .where((mall) => mall.planType.toLowerCase() == 'basic')
            .length;
        final wide = MediaQuery.of(context).size.width >= 1180;

        return Scaffold(
          backgroundColor: const Color(0xFFF5F8FC),
          drawer: wide
              ? null
              : Drawer(
                  child: _AdminSidebar(
                    compact: true,
                    onAddMall: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AddMallScreen()),
                    ),
                    onOpenQr: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const MallQrLibraryScreen(),
                      ),
                    ),
                    onBackHome: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => const AppModeSelector(),
                      ),
                    ),
                  ),
                ),
          body: SafeArea(
            child: Row(
              children: [
                if (wide)
                  _AdminSidebar(
                    onAddMall: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AddMallScreen()),
                    ),
                    onOpenQr: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const MallQrLibraryScreen(),
                      ),
                    ),
                    onBackHome: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => const AppModeSelector(),
                      ),
                    ),
                  ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      _AdminHeader(
                        wide: wide,
                        adminName: provider.currentAdmin?.name ?? 'Admin',
                        onMenuTap: wide
                            ? null
                            : () => Scaffold.of(context).openDrawer(),
                        onOpenQr: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const MallQrLibraryScreen(),
                          ),
                        ),
                        onAddMall: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AddMallScreen(),
                          ),
                        ),
                        onLogout: () {
                          provider.logout();
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => const AppModeSelector(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      GridView.count(
                        crossAxisCount: wide ? 4 : 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: wide ? 1.55 : 1.25,
                        children: [
                          _StatCard(
                            label: 'Total malls',
                            value: '${malls.length}',
                            icon: Icons.storefront_outlined,
                            accent: const Color(0xFF0B5ED7),
                          ),
                          _StatCard(
                            label: 'Active malls',
                            value: '$active',
                            icon: Icons.check_circle_outline,
                            accent: const Color(0xFF12B886),
                          ),
                          _StatCard(
                            label: 'Expiring soon',
                            value: '$expiring',
                            icon: Icons.warning_amber_outlined,
                            accent: const Color(0xFFFF9F1C),
                          ),
                          _StatCard(
                            label: 'Basic plan malls',
                            value: '$basicPlans',
                            icon: Icons.stacked_line_chart_outlined,
                            accent: const Color(0xFF6C5CE7),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _ActionStrip(
                        actions: [
                          _ActionData(
                            icon: Icons.add_business_outlined,
                            label: 'Add mall',
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const AddMallScreen(),
                              ),
                            ),
                          ),
                          _ActionData(
                            icon: Icons.qr_code_2_outlined,
                            label: 'QR labels',
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const MallQrLibraryScreen(),
                              ),
                            ),
                          ),
                          _ActionData(
                            icon: Icons.file_download_outlined,
                            label: 'Export report',
                            onTap: () => _exportMallReport(context, provider),
                          ),
                          _ActionData(
                            icon: Icons.notifications_active_outlined,
                            label: 'Send reminder',
                            onTap: () => showDialog(
                              context: context,
                              builder: (_) =>
                                  _AnnouncementDialog(provider: provider),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      wide
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 7,
                                  child: _DirectoryPanel(
                                    malls: malls,
                                    loading: provider.isLoading,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  flex: 4,
                                  child: Column(
                                    children: [
                                      _ActivityPanel(malls: malls),
                                      const SizedBox(height: 16),
                                      _SubscriptionHealthPanel(
                                        active: active,
                                        expiring: expiring,
                                        expired: expired,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              children: [
                                _DirectoryPanel(
                                  malls: malls,
                                  loading: provider.isLoading,
                                ),
                                const SizedBox(height: 16),
                                _ActivityPanel(malls: malls),
                                const SizedBox(height: 16),
                                _SubscriptionHealthPanel(
                                  active: active,
                                  expiring: expiring,
                                  expired: expired,
                                ),
                              ],
                            ),
                      const SizedBox(height: 20),
                      wide
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Expanded(child: _AnnouncementsPanel()),
                                SizedBox(width: 16),
                                Expanded(child: _SupportPanel()),
                                SizedBox(width: 16),
                                Expanded(child: _ReportsPanel()),
                              ],
                            )
                          : const Column(
                              children: [
                                _AnnouncementsPanel(),
                                SizedBox(height: 16),
                                _SupportPanel(),
                                SizedBox(height: 16),
                                _ReportsPanel(),
                              ],
                            ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AdminSidebar extends StatelessWidget {
  final bool compact;
  final VoidCallback onAddMall;
  final VoidCallback onOpenQr;
  final VoidCallback onBackHome;

  const _AdminSidebar({
    this.compact = false,
    required this.onAddMall,
    required this.onOpenQr,
    required this.onBackHome,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: compact ? double.infinity : 280,
      color: const Color(0xFF0F172A),
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SwiftCartLogo(
            size: 64,
            showWordmark: false,
            primaryColor: Color(0xFFEAF3FF),
            accentColor: Color(0xFFD8FFF0),
            backgroundColor: Colors.white,
          ),
          const SizedBox(height: 16),
          const Text(
            'Admin Portal',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Platform operations',
            style: TextStyle(color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 28),
          _SideTile(
            icon: Icons.dashboard_outlined,
            label: 'Dashboard',
            onTap: () {},
          ),
          _SideTile(
            icon: Icons.add_business_outlined,
            label: 'Add Malls',
            onTap: onAddMall,
          ),
          _SideTile(
            icon: Icons.qr_code_2_outlined,
            label: 'Mall QR Labels',
            onTap: onOpenQr,
          ),
          const Spacer(),
          _SideTile(
            icon: Icons.arrow_back_outlined,
            label: 'Back Home',
            onTap: onBackHome,
            filled: true,
          ),
        ],
      ),
    );
  }
}

class _AdminHeader extends StatelessWidget {
  final bool wide;
  final String adminName;
  final VoidCallback? onMenuTap;
  final VoidCallback onOpenQr;
  final VoidCallback onAddMall;
  final VoidCallback onLogout;

  const _AdminHeader({
    required this.wide,
    required this.adminName,
    this.onMenuTap,
    required this.onOpenQr,
    required this.onAddMall,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome back, $adminName',
          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        const Text(
          'Manage malls, subscriptions, QR operations, platform health, and reports from one browser dashboard.',
          style: TextStyle(fontSize: 15, color: Color(0xFF5F6C7C)),
        ),
      ],
    );

    final actions = Wrap(
      spacing: 12,
      runSpacing: 10,
      children: [
        OutlinedButton.icon(
          onPressed: onOpenQr,
          icon: const Icon(Icons.print_outlined),
          label: const Text('QR Labels'),
        ),
        ElevatedButton.icon(
          onPressed: onAddMall,
          icon: const Icon(Icons.add),
          label: const Text('Add Mall'),
        ),
        IconButton(
          onPressed: onLogout,
          icon: const Icon(Icons.logout),
          tooltip: 'Logout',
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE4EBF3)),
      ),
      child: wide
          ? Row(
              children: [
                Expanded(child: title),
                actions,
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: onMenuTap,
                      icon: const Icon(Icons.menu),
                    ),
                    const SizedBox(width: 6),
                    Expanded(child: title),
                  ],
                ),
                const SizedBox(height: 12),
                actions,
              ],
            ),
    );
  }
}

class _DirectoryPanel extends StatefulWidget {
  final List<MallSubscription> malls;
  final bool loading;

  const _DirectoryPanel({required this.malls, required this.loading});

  @override
  State<_DirectoryPanel> createState() => _DirectoryPanelState();
}

class _DirectoryPanelState extends State<_DirectoryPanel> {
  late final ScrollController _verticalController;
  late final ScrollController _horizontalController;

  @override
  void initState() {
    super.initState();
    _verticalController = ScrollController();
    _horizontalController = ScrollController();
  }

  @override
  void dispose() {
    _verticalController.dispose();
    _horizontalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AdminProvider>();
    return _Panel(
      title: 'Mall Performance Table',
      subtitle:
          'Review registered malls and jump directly into manager or subscription workflows.',
      child: widget.loading
          ? const SizedBox(
              height: 260,
              child: Center(child: CircularProgressIndicator()),
            )
          : widget.malls.isEmpty
          ? const SizedBox(
              height: 220,
              child: Center(child: Text('No malls added yet')),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: const [
                    _GridHint(label: 'Scroll down for more rows'),
                    _GridHint(label: 'Scroll right for more columns'),
                    _GridHint(label: 'Click Mall ID for full details'),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  height: 400,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FBFF),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE4EBF3)),
                  ),
                  child: Scrollbar(
                    controller: _verticalController,
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      controller: _verticalController,
                      padding: const EdgeInsets.all(12),
                      child: Scrollbar(
                        controller: _horizontalController,
                        thumbVisibility: true,
                        notificationPredicate: (notification) =>
                            notification.metrics.axis == Axis.horizontal,
                        child: SingleChildScrollView(
                          controller: _horizontalController,
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minWidth: 1120),
                            child: DataTable(
                              horizontalMargin: 18,
                              columnSpacing: 28,
                              dataRowMinHeight: 76,
                              dataRowMaxHeight: 92,
                              headingRowHeight: 58,
                              headingRowColor: WidgetStateProperty.all(
                                const Color(0xFFEFF5FC),
                              ),
                              border: TableBorder(
                                horizontalInside: BorderSide(
                                  color: const Color(0xFFDCE6F3),
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              columns: const [
                                DataColumn(label: Text('Mall Name')),
                                DataColumn(label: Text('Mall ID')),
                                DataColumn(label: Text('Location')),
                                DataColumn(label: Text('Plan')),
                                DataColumn(label: Text('Health')),
                                DataColumn(label: Text('Managers')),
                                DataColumn(label: Text('Actions')),
                              ],
                              rows: widget.malls.map((mall) {
                                final health = mall.isExpired
                                    ? 'Expired'
                                    : mall.daysUntilExpiry < 30
                                    ? 'Renew soon'
                                    : 'Healthy';
                                final location =
                                    '${mall.city ?? '-'}, ${mall.state ?? '-'}';
                                return DataRow(
                                  cells: [
                                    DataCell(
                                      SizedBox(
                                        width: 210,
                                        child: Text(
                                          mall.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      SizedBox(
                                        width: 160,
                                        child: InkWell(
                                          onTap: () => Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  MallDetailsScreen(mall: mall),
                                            ),
                                          ),
                                          child: Text(
                                            mall.mallId,
                                            style: const TextStyle(
                                              fontFamily: 'monospace',
                                              color: Color(0xFF0B5ED7),
                                              decoration:
                                                  TextDecoration.underline,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      SizedBox(
                                        width: 220,
                                        child: Text(location),
                                      ),
                                    ),
                                    DataCell(
                                      _PlanBadge(plan: mall.planType),
                                    ),
                                    DataCell(
                                      _HealthBadge(label: health),
                                    ),
                                    DataCell(
                                      FutureBuilder<int>(
                                        future: provider.getMallManagerCount(
                                          mall.mallId,
                                        ),
                                        builder: (context, snapshot) => Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEAF3FF),
                                            borderRadius:
                                                BorderRadius.circular(999),
                                          ),
                                          child: Text(
                                            '${snapshot.data ?? 0}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF194067),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      SizedBox(
                                        width: 260,
                                        child: Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: [
                                            OutlinedButton(
                                              onPressed: () =>
                                                  Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      MallDetailsScreen(
                                                    mall: mall,
                                                  ),
                                                ),
                                              ),
                                              child: const Text('Details'),
                                            ),
                                            OutlinedButton(
                                              onPressed: () =>
                                                  Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      MallManagersScreen(
                                                    mall: mall,
                                                  ),
                                                ),
                                              ),
                                              child: const Text('Managers'),
                                            ),
                                            FilledButton.tonal(
                                              onPressed: () =>
                                                  Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      ManageSubscriptionScreen(
                                                    mall: mall,
                                                  ),
                                                ),
                                              ),
                                              child: const Text('Subscription'),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _GridHint extends StatelessWidget {
  final String label;

  const _GridHint({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F7FC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFDCE6F3)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF5F6C7C),
        ),
      ),
    );
  }
}

class _PlanBadge extends StatelessWidget {
  final String plan;

  const _PlanBadge({required this.plan});

  @override
  Widget build(BuildContext context) {
    final normalized = plan.toLowerCase();
    final accent = switch (normalized) {
      'enterprise' => const Color(0xFF6C5CE7),
      'pro' => const Color(0xFF0B5ED7),
      _ => const Color(0xFF12B886),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        normalized.toUpperCase(),
        style: TextStyle(
          color: accent,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _HealthBadge extends StatelessWidget {
  final String label;

  const _HealthBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    final accent = switch (label) {
      'Expired' => const Color(0xFFE03131),
      'Renew soon' => const Color(0xFFFF9F1C),
      _ => const Color(0xFF12B886),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: accent,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ActivityPanel extends StatelessWidget {
  final List<MallSubscription> malls;

  const _ActivityPanel({required this.malls});

  @override
  Widget build(BuildContext context) {
    final recent = [...malls]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final items = recent.take(4).map((mall) {
      final message = mall.isExpired
          ? 'Subscription expired'
          : mall.daysUntilExpiry < 30
          ? 'Renewal window active'
          : 'Mall created and active';
      return _MiniRow(title: mall.name, subtitle: '$message • ${mall.mallId}');
    }).toList();

    return _Panel(
      title: 'Recent Activity Feed',
      subtitle: 'Surface quick status changes so admins can act faster.',
      child: items.isEmpty
          ? const Text(
              'Recent mall activity will appear here once records are available.',
            )
          : Column(children: items),
    );
  }
}

class _SubscriptionHealthPanel extends StatelessWidget {
  final int active;
  final int expiring;
  final int expired;

  const _SubscriptionHealthPanel({
    required this.active,
    required this.expiring,
    required this.expired,
  });

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Subscription Health',
      subtitle: 'Highlight the accounts that need immediate attention.',
      child: Column(
        children: [
          _MiniRow(title: 'Healthy accounts', subtitle: '$active active malls'),
          _MiniRow(
            title: 'Renewal reminders',
            subtitle: '$expiring malls expiring within 30 days',
          ),
          _MiniRow(
            title: 'Expired subscriptions',
            subtitle: '$expired malls need intervention',
          ),
        ],
      ),
    );
  }
}

class _AnnouncementsPanel extends StatelessWidget {
  const _AnnouncementsPanel();

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AdminProvider>();
    return _Panel(
      title: 'Announcements',
      subtitle:
          'Publish platform notices for mall teams from the web dashboard.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => _AnnouncementDialog(provider: provider),
              ),
              icon: const Icon(Icons.campaign_outlined),
              label: const Text('New announcement'),
            ),
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: provider.watchAnnouncements(),
            builder: (context, snapshot) {
              final items = snapshot.data ?? const [];
              if (items.isEmpty) {
                return const Text('No announcements published yet.');
              }
              return Column(
                children: items.take(4).map((item) {
                  final audience = (item['audience'] ?? 'all').toString();
                  return _MiniRow(
                    title: (item['title'] ?? 'Announcement').toString(),
                    subtitle:
                        '${(item['message'] ?? '').toString()} • audience: $audience',
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SupportPanel extends StatelessWidget {
  const _SupportPanel();

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AdminProvider>();
    return _Panel(
      title: 'Support Requests',
      subtitle:
          'Review demo requests and update their status from the dashboard.',
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: provider.watchSupportRequests(),
        builder: (context, snapshot) {
          final items = snapshot.data ?? const [];
          if (items.isEmpty) {
            return const Text('No support requests yet.');
          }
          return Column(
            children: items.take(4).map((item) {
              final id = (item['id'] ?? '').toString();
              final status = (item['status'] ?? 'new').toString();
              final type = (item['type'] ?? 'support').toString();
              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FBFF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${(item['name'] ?? 'Visitor').toString()} • $type',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(item['email'] ?? '').toString()} • ${(item['message'] ?? '').toString()}',
                      style: const TextStyle(
                        color: Color(0xFF5F6C7C),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        Text('Status: $status'),
                        TextButton(
                          onPressed: () => provider.updateSupportRequestStatus(
                            requestId: id,
                            status: 'in_progress',
                          ),
                          child: const Text('Start'),
                        ),
                        TextButton(
                          onPressed: () => provider.updateSupportRequestStatus(
                            requestId: id,
                            status: 'resolved',
                          ),
                          child: const Text('Resolve'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class _ReportsPanel extends StatelessWidget {
  const _ReportsPanel();

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AdminProvider>();
    return _Panel(
      title: 'Downloadable Reports',
      subtitle: 'See recent platform revenue and report-oriented summaries.',
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: provider.watchRecentMallPayments(),
        builder: (context, snapshot) {
          final items = snapshot.data ?? const [];
          final revenue = items.fold<double>(
            0,
            (sum, item) => sum + ((item['amount'] as num?)?.toDouble() ?? 0),
          );
          return Column(
            children: [
              _MiniRow(
                title: 'Recent mall payments',
                subtitle:
                    '${items.length} payment records • Rs ${revenue.toStringAsFixed(2)} tracked',
              ),
              _MiniRow(
                title: 'Monthly mall growth',
                subtitle:
                    '${context.watch<AdminProvider>().malls.length} total malls in directory',
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ActionStrip extends StatelessWidget {
  final List<_ActionData> actions;

  const _ActionStrip({required this.actions});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE4EBF3)),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: actions
            .map(
              (action) => OutlinedButton.icon(
                onPressed: action.onTap,
                icon: Icon(action.icon),
                label: Text(action.label),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _ActionData {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionData({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}

class _SideTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool filled;

  const _SideTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: filled
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE4EBF3)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: accent.withValues(alpha: 0.12),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(label, style: const TextStyle(color: Color(0xFF607084))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _Panel({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE4EBF3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(color: Color(0xFF5F6C7C))),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _MiniRow extends StatelessWidget {
  final String title;
  final String subtitle;

  const _MiniRow({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: Color(0xFF5F6C7C), height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _AnnouncementDialog extends StatefulWidget {
  final AdminProvider provider;

  const _AnnouncementDialog({required this.provider});

  @override
  State<_AnnouncementDialog> createState() => _AnnouncementDialogState();
}

class _AnnouncementDialogState extends State<_AnnouncementDialog> {
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  String _audience = 'all';
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Announcement'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _messageController,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Message'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _audience,
              decoration: const InputDecoration(labelText: 'Audience'),
              items: const ['all', 'managers', 'admins']
                  .map(
                    (value) =>
                        DropdownMenuItem(value: value, child: Text(value)),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _audience = value);
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Publish'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty ||
        _messageController.text.trim().isEmpty) {
      return;
    }
    setState(() => _saving = true);
    final success = await widget.provider.createAnnouncement(
      title: _titleController.text,
      message: _messageController.text,
      audience: _audience,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (success) {
      Navigator.pop(context);
    }
  }
}
