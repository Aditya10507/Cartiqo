import 'package:flutter/material.dart';

import '../services/admin_api_service.dart';
import '../widgets/swiftcart_logo.dart';
import 'admin_login_screen.dart';
import 'mall_manager_login_screen.dart';

class WebPortalHomeScreen extends StatefulWidget {
  const WebPortalHomeScreen({super.key});

  @override
  State<WebPortalHomeScreen> createState() => _WebPortalHomeScreenState();
}

class _WebPortalHomeScreenState extends State<WebPortalHomeScreen> {
  final _scrollController = ScrollController();
  final _howItWorksKey = GlobalKey();
  final _plansKey = GlobalKey();
  final _faqKey = GlobalKey();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _scrollToSection(GlobalKey key) async {
    final context = key.currentContext;
    if (context == null) {
      return;
    }

    await Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOutCubic,
      alignment: 0.08,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF7FBFF), Color(0xFFEEF4FF), Color(0xFFFFF7EE)],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth > 1180
                  ? 1180.0
                  : constraints.maxWidth;
              final isWide = width >= 960;

              return SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: width),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _TopBar(
                          isWide: isWide,
                          onHowItWorksTap: () => _scrollToSection(
                            _howItWorksKey,
                          ),
                          onPlansTap: () => _scrollToSection(_plansKey),
                          onFaqTap: () => _scrollToSection(_faqKey),
                        ),
                        const SizedBox(height: 18),
                        _HeroSection(isWide: isWide),
                        const SizedBox(height: 18),
                        _PortalSection(isWide: isWide),
                        const SizedBox(height: 18),
                        _SectionShell(
                          key: _howItWorksKey,
                          title: 'How It Works',
                          subtitle:
                              'Show the scan-to-bill journey clearly on the website.',
                          child: _AdaptiveList(
                            isWide: isWide,
                            children: const [
                              _InfoCard(
                                icon: Icons.qr_code_scanner_outlined,
                                title: 'Scan products',
                                subtitle:
                                    'Identify items fast with barcode-first checkout.',
                              ),
                              _InfoCard(
                                icon: Icons.receipt_long_outlined,
                                title: 'Build the bill',
                                subtitle:
                                    'Apply GST, charges, and billing rules consistently.',
                              ),
                              _InfoCard(
                                icon: Icons.inventory_2_outlined,
                                title: 'Manage operations',
                                subtitle:
                                    'Keep products, labels, and settings in sync from the web portal.',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        _SectionShell(
                          title: 'Who It Is For',
                          subtitle: 'Make the homepage useful for each role.',
                          child: GridView.count(
                            crossAxisCount: isWide ? 4 : 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            childAspectRatio: isWide ? 1.0 : 0.95,
                            children: const [
                              _InfoCard(
                                icon: Icons.apartment_outlined,
                                title: 'Mall Admins',
                                subtitle:
                                    'Manage malls, subscriptions, managers, and reports.',
                              ),
                              _InfoCard(
                                icon: Icons.badge_outlined,
                                title: 'Managers',
                                subtitle:
                                    'Handle stock, products, pricing, and labels.',
                              ),
                              _InfoCard(
                                icon: Icons.point_of_sale_outlined,
                                title: 'Billing Teams',
                                subtitle:
                                    'Produce cleaner, faster bills at checkout.',
                              ),
                              _InfoCard(
                                icon: Icons.shopping_bag_outlined,
                                title: 'Customers',
                                subtitle:
                                    'Get quicker checkout and clearer payment records.',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        _DemoSection(isWide: isWide),
                        const SizedBox(height: 18),
                        _SectionShell(
                          title: 'Benefits',
                          subtitle:
                              'Position Cartiqo as a serious retail operations product.',
                          child: _AdaptiveList(
                            isWide: isWide,
                            children: const [
                              _InfoCard(
                                icon: Icons.flash_on_outlined,
                                title: 'Faster checkout',
                                subtitle:
                                    'Reduce billing friction with scan-first workflows.',
                              ),
                              _InfoCard(
                                icon: Icons.verified_outlined,
                                title: 'Fewer mistakes',
                                subtitle:
                                    'Keep products, labels, and pricing rules controlled in one place.',
                              ),
                              _InfoCard(
                                icon: Icons.insights_outlined,
                                title: 'Better visibility',
                                subtitle:
                                    'Give admins and managers useful dashboard sections and actions.',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        _PricingSection(
                          key: _plansKey,
                          isWide: isWide,
                        ),
                        const SizedBox(height: 18),
                        _SectionShell(
                          key: _faqKey,
                          title: 'Testimonials And FAQ',
                          subtitle:
                              'Add proof and trust-building content to the marketing surface.',
                          child: _AdaptiveList(
                            isWide: isWide,
                            children: const [
                              _InfoCard(
                                icon: Icons.format_quote_outlined,
                                title: 'Retail operations lead',
                                subtitle:
                                    'The manager portal now feels like a real operations desk, not just a login page.',
                              ),
                              _InfoCard(
                                icon: Icons.help_outline,
                                title:
                                    'Can managers print labels from the website?',
                                subtitle:
                                    'Yes. The manager portal is built around barcode and inventory workflows.',
                              ),
                              _InfoCard(
                                icon: Icons.support_agent_outlined,
                                title: 'Is the web UI responsive?',
                                subtitle:
                                    'Yes. The layout now works across wide and smaller browser sizes.',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        _CtaSection(isWide: isWide),
                        const SizedBox(height: 18),
                        const _FooterSection(),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final bool isWide;
  final VoidCallback onHowItWorksTap;
  final VoidCallback onPlansTap;
  final VoidCallback onFaqTap;

  const _TopBar({
    required this.isWide,
    required this.onHowItWorksTap,
    required this.onPlansTap,
    required this.onFaqTap,
  });

  @override
  Widget build(BuildContext context) {
    final links = [
      _Pill(label: 'How it works', onTap: onHowItWorksTap),
      _Pill(label: 'Plans', onTap: onPlansTap),
      _Pill(label: 'FAQ', onTap: onFaqTap),
    ];

    final content = isWide
        ? Row(
            children: [
              const SwiftCartLogo(
                size: 48,
                showWordmark: false,
                primaryColor: Color(0xFF0B5ED7),
                accentColor: Color(0xFF12B886),
                backgroundColor: Colors.white,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cartiqo',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF111827),
                      ),
                    ),
                    Text(
                      'Retail checkout workspace',
                      style: TextStyle(color: Color(0xFF5B6677)),
                    ),
                  ],
                ),
              ),
              ...links,
              const SizedBox(width: 12),
              FilledButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const MallManagerLoginScreen(),
                  ),
                ),
                child: const Text('Open workspace'),
              ),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const SwiftCartLogo(
                    size: 44,
                    showWordmark: false,
                    primaryColor: Color(0xFF0B5ED7),
                    accentColor: Color(0xFF12B886),
                    backgroundColor: Colors.white,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Cartiqo',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const MallManagerLoginScreen(),
                      ),
                    ),
                    child: const Text('Open'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(spacing: 10, runSpacing: 10, children: links),
            ],
          );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white),
      ),
      child: content,
    );
  }
}

class _HeroSection extends StatelessWidget {
  final bool isWide;

  const _HeroSection({required this.isWide});

  @override
  Widget build(BuildContext context) {
    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFE6F0FF),
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Text(
            'Scan. Bill. Go.',
            style: TextStyle(
              color: Color(0xFF0B5ED7),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Run mall billing, products, labels, and checkout from one polished web workspace.',
          style: TextStyle(
            fontSize: isWide ? 50 : 36,
            fontWeight: FontWeight.w900,
            height: 1.03,
            color: const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Cartiqo gives mall admins and managers a faster way to handle products, barcode labels, subscription operations, and customer-ready billing records without jumping between tools.',
          style: TextStyle(fontSize: 16, height: 1.6, color: Color(0xFF526075)),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: const [
            _Pill(label: 'Barcode library + print'),
            _Pill(label: 'Mall QR onboarding'),
            _Pill(label: 'Billing settings'),
            _Pill(label: 'Bills and history'),
          ],
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const MallManagerLoginScreen(),
                ),
              ),
              icon: const Icon(Icons.storefront_outlined),
              label: const Text('Open manager portal'),
            ),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
              ),
              icon: const Icon(Icons.admin_panel_settings_outlined),
              label: const Text('Open admin portal'),
            ),
          ],
        ),
      ],
    );

    const panel = _DarkPanel(
      title: 'Live operations view',
      subtitle:
          'A modern control room for retail teams that need visibility without complexity.',
      items: [
        _DarkPanelItem(
          label: 'Checkout speed',
          value: 'Faster scan-to-bill flow',
        ),
        _DarkPanelItem(
          label: 'Catalog control',
          value: 'Products, stock, and labels in one place',
        ),
        _DarkPanelItem(
          label: 'Coverage',
          value: 'Admin, manager, and customer touchpoints',
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white),
      ),
      child: isWide
          ? Row(
              children: [
                Expanded(flex: 6, child: copy),
                const SizedBox(width: 20),
                const Expanded(flex: 5, child: panel),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [copy, const SizedBox(height: 18), panel],
            ),
    );
  }
}

class _PortalSection extends StatelessWidget {
  final bool isWide;

  const _PortalSection({required this.isWide});

  @override
  Widget build(BuildContext context) {
    final cards = [
      _PortalCard(
        title: 'Main Admin',
        subtitle:
            'Operate the platform, manage malls, track subscription health, and handle QR onboarding.',
        accent: const Color(0xFF0B5ED7),
        icon: Icons.admin_panel_settings_outlined,
        features: const [
          'Mall directory',
          'Subscription oversight',
          'Reports and actions',
        ],
        onPressed: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const AdminLoginScreen())),
      ),
      _PortalCard(
        title: 'Mall Manager',
        subtitle:
            'Control products, stock, label printing, pricing rules, and day-to-day retail operations.',
        accent: const Color(0xFF12B886),
        icon: Icons.storefront_outlined,
        features: const [
          'Inventory snapshot',
          'Barcode workflows',
          'Billing settings',
        ],
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const MallManagerLoginScreen()),
        ),
      ),
    ];

    return _SectionShell(
      title: 'Portal Access',
      subtitle:
          'Choose the workspace that matches your role and jump directly into the tools.',
      child: isWide
          ? Row(
              children: [
                Expanded(child: cards[0]),
                const SizedBox(width: 18),
                Expanded(child: cards[1]),
              ],
            )
          : Column(children: [cards[0], const SizedBox(height: 16), cards[1]]),
    );
  }
}

class _DemoSection extends StatelessWidget {
  final bool isWide;

  const _DemoSection({required this.isWide});

  @override
  Widget build(BuildContext context) {
    final left = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Live Demo Preview',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Show visitors exactly what the app does without needing a login first.',
            style: TextStyle(color: Color(0xFFD8E4F7), height: 1.55),
          ),
          SizedBox(height: 18),
          _PreviewRow(label: 'Scanned barcode', value: '8901450012768'),
          SizedBox(height: 10),
          _PreviewRow(label: 'Product found', value: 'Organic Rice 5kg'),
          SizedBox(height: 10),
          _PreviewRow(label: 'Bill status', value: 'GST + charges applied'),
        ],
      ),
    );

    final right = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBFF),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFDCE6F6)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mock Bill Preview',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Color(0xFF111827),
            ),
          ),
          SizedBox(height: 14),
          _BillLine(label: 'Organic Rice 5kg', value: 'Rs 480.00'),
          _BillLine(label: 'Fresh Milk 1L', value: 'Rs 62.00'),
          _BillLine(label: 'Snacks Combo', value: 'Rs 145.00'),
          Divider(height: 28),
          _BillLine(label: 'Subtotal', value: 'Rs 687.00'),
          _BillLine(label: 'GST', value: 'Rs 34.35'),
          _BillLine(label: 'Service charge', value: 'Rs 10.00'),
          Divider(height: 28),
          _BillLine(label: 'Total', value: 'Rs 731.35', emphasis: true),
        ],
      ),
    );

    return _SectionShell(
      title: 'Live Demo And Bill Preview',
      subtitle:
          'A visible demo section helps first-time visitors understand the product in seconds.',
      child: isWide
          ? Row(
              children: [
                Expanded(child: left),
                const SizedBox(width: 18),
                Expanded(child: right),
              ],
            )
          : Column(children: [left, const SizedBox(height: 16), right]),
    );
  }
}

class _PricingSection extends StatelessWidget {
  final bool isWide;

  const _PricingSection({super.key, required this.isWide});

  @override
  Widget build(BuildContext context) {
    final plans = const [
      _PlanCard(
        title: 'Basic',
        badge: 'Starter',
        accent: Color(0xFF0B5ED7),
        subtitle:
            'For smaller retail operations starting with digital billing and product control.',
        features: [
          'Product catalog',
          'Barcode printing',
          'Manual billing rules',
        ],
      ),
      _PlanCard(
        title: 'Growth',
        badge: 'Recommended',
        accent: Color(0xFF12B886),
        subtitle:
            'For busy mall teams that need stronger reporting, workflow control, and visibility.',
        features: [
          'Reports and alerts',
          'Manager workflows',
          'Bulk operations',
        ],
      ),
      _PlanCard(
        title: 'Enterprise',
        badge: 'Advanced',
        accent: Color(0xFFFF9F1C),
        subtitle:
            'For larger retail groups that want stronger admin control and multi-location oversight.',
        features: [
          'Platform oversight',
          'Subscription controls',
          'Priority onboarding',
        ],
      ),
    ];

    return _SectionShell(
      title: 'Pricing And Plans',
      subtitle:
          'Even placeholder pricing cards make the website feel more complete and easier to sell.',
      child: isWide
          ? Row(
              children: [
                Expanded(child: plans[0]),
                const SizedBox(width: 16),
                Expanded(child: plans[1]),
                const SizedBox(width: 16),
                Expanded(child: plans[2]),
              ],
            )
          : Column(
              children: [
                plans[0],
                const SizedBox(height: 14),
                plans[1],
                const SizedBox(height: 14),
                plans[2],
              ],
            ),
    );
  }
}

class _CtaSection extends StatelessWidget {
  final bool isWide;

  const _CtaSection({required this.isWide});

  @override
  Widget build(BuildContext context) {
    final actions = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.tonal(
          onPressed: () => showDialog(
            context: context,
            builder: (_) => const _SupportRequestDialog(type: 'demo'),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF0B5ED7),
          ),
          child: const Text('Book admin demo'),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const MallManagerLoginScreen()),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: Colors.white),
          ),
          child: const Text('Open manager portal'),
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0B5ED7), Color(0xFF12B886)],
        ),
        borderRadius: BorderRadius.circular(30),
      ),
      child: isWide
          ? Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ready to turn the website into a stronger product experience?',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Use this section as the final call to action for demos, onboarding, and portal access.',
                        style: TextStyle(color: Color(0xFFEAF8F4), height: 1.6),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 18),
                SizedBox(width: 220, child: actions),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ready to turn the website into a stronger product experience?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Use this section as the final call to action for demos, onboarding, and portal access.',
                  style: TextStyle(color: Color(0xFFEAF8F4), height: 1.6),
                ),
                const SizedBox(height: 18),
                actions,
              ],
            ),
    );
  }
}

class _SectionShell extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _SectionShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(color: Color(0xFF5B6677), height: 1.55),
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _AdaptiveList extends StatelessWidget {
  final bool isWide;
  final List<Widget> children;

  const _AdaptiveList({required this.isWide, required this.children});

  @override
  Widget build(BuildContext context) {
    if (isWide) {
      return Row(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            Expanded(child: children[i]),
            if (i != children.length - 1) const SizedBox(width: 16),
          ],
        ],
      );
    }

    return Column(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          children[i],
          if (i != children.length - 1) const SizedBox(height: 14),
        ],
      ],
    );
  }
}

class _PortalCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color accent;
  final IconData icon;
  final List<String> features;
  final VoidCallback onPressed;

  const _PortalCard({
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.icon,
    required this.features,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: accent.withValues(alpha: 0.14),
                child: Icon(icon, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 14,
              height: 1.55,
              color: Color(0xFF526075),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: features.map((item) => _Pill(label: item)).toList(),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Open Portal',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DarkPanel extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<_DarkPanelItem> items;

  const _DarkPanel({
    required this.title,
    required this.subtitle,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), Color(0xFF173A74)],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(color: Color(0xFFDCE9FF), height: 1.55),
          ),
          const SizedBox(height: 18),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.10),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.label,
                      style: const TextStyle(
                        color: Color(0xFFB7FFD9),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.value,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DarkPanelItem {
  final String label;
  final String value;

  const _DarkPanelItem({required this.label, required this.value});
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBFF),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2EAF6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFFE8F0FF),
            child: Icon(icon, color: const Color(0xFF0B5ED7)),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(color: Color(0xFF526075), height: 1.55),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String title;
  final String badge;
  final Color accent;
  final String subtitle;
  final List<String> features;

  const _PlanCard({
    required this.title,
    required this.badge,
    required this.accent,
    required this.subtitle,
    required this.features,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              badge,
              style: TextStyle(color: accent, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: const TextStyle(color: Color(0xFF526075), height: 1.6),
          ),
          const SizedBox(height: 16),
          ...features.map(
            (feature) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline, color: accent, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      feature,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  final String label;
  final String value;

  const _PreviewRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(color: Color(0xFF9DB2D0))),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _BillLine extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasis;

  const _BillLine({
    required this.label,
    required this.value,
    this.emphasis = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontWeight: emphasis ? FontWeight.w900 : FontWeight.w600,
      fontSize: emphasis ? 18 : 14,
      color: emphasis ? const Color(0xFF111827) : const Color(0xFF526075),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(value, style: style),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _Pill({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFD6E4FF)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF194067),
          ),
        ),
      ),
    );
  }
}

class _FooterSection extends StatelessWidget {
  const _FooterSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.70),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white),
      ),
      child: const Text(
        'Cartiqo now presents itself as both a product website and an operational web portal for retail teams.',
        style: TextStyle(
          fontSize: 13,
          height: 1.6,
          color: Color(0xFF526075),
          fontWeight: FontWeight.w600,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _SupportRequestDialog extends StatefulWidget {
  final String type;

  const _SupportRequestDialog({required this.type});

  @override
  State<_SupportRequestDialog> createState() => _SupportRequestDialogState();
}

class _SupportRequestDialogState extends State<_SupportRequestDialog> {
  final _adminApiService = AdminApiService();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.type == 'demo' ? 'Book Demo' : 'Contact Support'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _messageController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: widget.type == 'demo'
                    ? 'Tell us about your mall'
                    : 'How can we help?',
              ),
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
              : const Text('Submit'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _messageController.text.trim().isEmpty) {
      return;
    }
    setState(() => _saving = true);
    try {
      await _adminApiService.createSupportRequest(
        type: widget.type,
        name: _nameController.text,
        email: _emailController.text,
        message: _messageController.text,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit request: $error')),
      );
      return;
    }
    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Request submitted successfully')),
    );
  }
}
