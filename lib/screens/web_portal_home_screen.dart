import 'package:flutter/material.dart';

import '../services/admin_api_service.dart';
import '../services/external_link_opener.dart';
import '../widgets/swiftcart_logo.dart';
import 'admin_login_screen.dart' deferred as admin_login;
import 'mall_manager_login_screen.dart' deferred as mall_manager_login;

class WebPortalHomeScreen extends StatefulWidget {
  const WebPortalHomeScreen({super.key});

  @override
  State<WebPortalHomeScreen> createState() => _WebPortalHomeScreenState();
}

class _WebPortalHomeScreenState extends State<WebPortalHomeScreen> {
  static final Uri _instagramUri = Uri.parse(
    'https://www.instagram.com/aditya_singh_o5/',
  );
  static final Uri _linkedInUri = Uri.parse(
    'https://www.linkedin.com/in/aditya-singh-81as22/',
  );
  static final Uri _whatsAppUri = Uri.parse('https://wa.me/919795075062');
  static final Uri _emailUri = Uri(
    scheme: 'mailto',
    path: 'adityaws10507@gmail.com',
    queryParameters: {'subject': 'Cartiqo Inquiry'},
  );
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

  Future<void> _openAdminPortal() async {
    await admin_login.loadLibrary();
    if (!mounted) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => admin_login.AdminLoginScreen(),
      ),
    );
  }

  Future<void> _openManagerPortal() async {
    await mall_manager_login.loadLibrary();
    if (!mounted) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => mall_manager_login.MallManagerLoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1224),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF08101F), Color(0xFF101B33), Color(0xFF0B1530)],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth > 1180
                  ? 1180.0
                  : constraints.maxWidth;
              final isWide = width >= 960;

              return Stack(
                children: [
                  SingleChildScrollView(
                    controller: _scrollController,
                    padding: EdgeInsets.fromLTRB(
                      24,
                      24,
                      isWide ? 120 : 24,
                      24,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: width),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _TopBar(
                              isWide: isWide,
                              onHomeTap: () => _scrollController.animateTo(
                                0,
                                duration: const Duration(milliseconds: 450),
                                curve: Curves.easeInOutCubic,
                              ),
                              onHowItWorksTap: () => _scrollToSection(
                                _howItWorksKey,
                              ),
                              onPlansTap: () => _scrollToSection(_plansKey),
                              onFaqTap: () => _scrollToSection(_faqKey),
                              onOpenAdminPortal: _openAdminPortal,
                              onOpenWorkspaceTap: _openManagerPortal,
                            ),
                            const SizedBox(height: 18),
                            _HeroSection(
                              isWide: isWide,
                              onOpenManagerPortal: _openManagerPortal,
                              onOpenAdminPortal: _openAdminPortal,
                              onHowItWorksTap: () => _scrollToSection(_howItWorksKey),
                            ),
                            const SizedBox(height: 18),
                            _SectionShell(
                              title: 'What Is New In Cartiqo',
                              subtitle:
                                  'The platform now goes beyond barcode billing with smarter discovery, easier imports, and stronger mall operations.',
                              child: _AdaptiveList(
                                isWide: isWide,
                                children: const [
                                  _FeatureSceneCard(
                                    icon: Icons.document_scanner_outlined,
                                    title: 'Pack text product detection',
                                    subtitle:
                                        'Use the camera to read product text, recommend likely matches, and let the shopper choose the right item.',
                                    tags: ['OCR Read', 'Top Matches', 'No Image Save'],
                                  ),
                                  _FeatureSceneCard(
                                    icon: Icons.qr_code_scanner_outlined,
                                    title: 'Multi-mode item finding',
                                    subtitle:
                                        'Customers can use manual barcode entry, barcode scan, pack-text capture, or browse search in one journey.',
                                    tags: ['Manual Barcode', 'Scanner', 'Browse'],
                                  ),
                                  _FeatureSceneCard(
                                    icon: Icons.cloud_upload_outlined,
                                    title: 'Mall catalog import',
                                    subtitle:
                                        'Managers upload their own product list into their mall workspace and keep original barcodes wherever they already exist.',
                                    tags: ['CSV Import', 'Keep Barcodes', 'Mall Only'],
                                  ),
                                  _FeatureSceneCard(
                                    icon: Icons.admin_panel_settings_outlined,
                                    title: 'Manager account control',
                                    subtitle:
                                        'Managers can sign up with linked email, create a password, reset it with OTP, and stay locked to their own mall only.',
                                    tags: ['Email OTP', 'Reset Password', 'Role Locked'],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),
                            _SectionShell(
                          key: _howItWorksKey,
                          title: 'How It Works',
                          subtitle:
                              'Cartiqo keeps retail checkout simple for shoppers and operationally clean for malls.',
                          child: _AdaptiveList(
                            isWide: isWide,
                            children: const [
                              _InfoCard(
                                icon: Icons.store_mall_directory_outlined,
                                title: 'Enter the mall',
                                subtitle:
                                    'Customers open Cartiqo, scan the mall QR or enter the mall ID, and start a session instantly.',
                              ),
                              _InfoCard(
                                icon: Icons.qr_code_scanner_outlined,
                                title: 'Scan or search products',
                                subtitle:
                                    'Use barcode scan, pack text, or browse products to build the cart without queues.',
                              ),
                              _InfoCard(
                                icon: Icons.receipt_long_outlined,
                                title: 'Checkout and exit fast',
                                subtitle:
                                    'Review the cart, pay, and move through checkout with digital billing and clear records.',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        _SectionShell(
                          title: 'Why Retail Teams Choose Cartiqo',
                          subtitle:
                              'The platform is built for fast checkout, tighter control, and easier daily operations.',
                          child: GridView.count(
                            crossAxisCount: isWide ? 4 : 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            childAspectRatio: isWide ? 1.0 : 0.95,
                            children: const [
                              _InfoCard(
                                icon: Icons.flash_on_outlined,
                                title: 'Faster checkout',
                                subtitle:
                                    'Reduce queue time with scan-first shopping and a smoother billing flow.',
                              ),
                              _InfoCard(
                                icon: Icons.inventory_2_outlined,
                                title: 'Catalog control',
                                subtitle:
                                    'Keep products, stock, pricing, labels, and import workflows in one place.',
                              ),
                              _InfoCard(
                                icon: Icons.verified_outlined,
                                title: 'Mall-level security',
                                subtitle:
                                    'Every manager works only inside their own mall workspace and database.',
                              ),
                              _InfoCard(
                                icon: Icons.insights_outlined,
                                title: 'Business visibility',
                                subtitle:
                                    'Track billing, import activity, managers, and operational performance with clarity.',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        _DemoSection(isWide: isWide),
                        const SizedBox(height: 18),
                        _PortalSection(
                          isWide: isWide,
                          onOpenAdminPortal: _openAdminPortal,
                          onOpenManagerPortal: _openManagerPortal,
                        ),
                        const SizedBox(height: 18),
                        _SectionShell(
                          title: 'Built For Every Role In The Mall',
                          subtitle:
                              'One product experience outside, multiple operational workspaces inside.',
                          child: _AdaptiveList(
                            isWide: isWide,
                            children: const [
                              _InfoCard(
                                icon: Icons.admin_panel_settings_outlined,
                                title: 'Main Admin',
                                subtitle:
                                    'Manage malls, managers, subscriptions, support requests, and platform oversight.',
                              ),
                              _InfoCard(
                                icon: Icons.storefront_outlined,
                                title: 'Mall Manager',
                                subtitle:
                                    'Upload catalog data, manage products, billing settings, labels, and day-to-day retail operations.',
                              ),
                              _InfoCard(
                                icon: Icons.shopping_bag_outlined,
                                title: 'Customer',
                                subtitle:
                                    'Enter the mall, find products, scan items, build the cart, and check out faster.',
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
                          title: 'Reviews And FAQ',
                          subtitle:
                              'Answer the big product questions and reinforce trust at the same time.',
                          child: _AdaptiveList(
                            isWide: isWide,
                            children: const [
                              _InfoCard(
                                icon: Icons.format_quote_outlined,
                                title: 'Store operations team',
                                subtitle:
                                    'Cartiqo makes billing feel smoother for shoppers and gives our staff a much clearer product workflow.',
                              ),
                              _InfoCard(
                                icon: Icons.help_outline,
                                title:
                                    'Can malls keep their own barcodes?',
                                subtitle:
                                    'Yes. Cartiqo is designed to work with existing product barcodes and imported mall catalog data.',
                              ),
                              _InfoCard(
                                icon: Icons.support_agent_outlined,
                                title: 'Can managers upload their own product list?',
                                subtitle:
                                    'Yes. Managers can import their mall catalog into their own workspace and update it from there.',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        _CtaSection(
                          isWide: isWide,
                          onOpenManagerPortal: _openManagerPortal,
                        ),
                        const SizedBox(height: 18),
                        const _FooterSection(),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (isWide)
                    Positioned(
                      right: 28,
                      top: 180,
                      child: _FixedContactRail(
                        whatsAppUri: _whatsAppUri,
                        emailUri: _emailUri,
                        linkedInUri: _linkedInUri,
                        instagramUri: _instagramUri,
                      ),
                    ),
                ],
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
  final VoidCallback onHomeTap;
  final VoidCallback onHowItWorksTap;
  final VoidCallback onPlansTap;
  final VoidCallback onFaqTap;
  final VoidCallback onOpenAdminPortal;
  final VoidCallback onOpenWorkspaceTap;

  const _TopBar({
    required this.isWide,
    required this.onHomeTap,
    required this.onHowItWorksTap,
    required this.onPlansTap,
    required this.onFaqTap,
    required this.onOpenAdminPortal,
    required this.onOpenWorkspaceTap,
  });

  @override
  Widget build(BuildContext context) {
    final links = [
      _NavLink(label: 'Home', onTap: onHomeTap),
      _NavLink(label: 'Features', onTap: onHowItWorksTap),
      _NavLink(label: 'Plans', onTap: onPlansTap),
      _NavLink(label: 'FAQ', onTap: onFaqTap),
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
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Offline shopping app',
                      style: TextStyle(color: Color(0xFF93A4C4)),
                    ),
                  ],
                ),
              ),
              ...links,
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: onOpenAdminPortal,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFF3B82F6), width: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: const Text('Login'),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: onOpenWorkspaceTap,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: const Text('Register'),
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
                        color: Colors.white,
                      ),
                    ),
                  ),
                  FilledButton(
                    onPressed: onOpenWorkspaceTap,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                    ),
                    child: const Text('Register'),
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
        color: const Color(0xFF0F172A).withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF1F335B)),
      ),
      child: content,
    );
  }
}

class _HeroSection extends StatelessWidget {
  final bool isWide;
  final VoidCallback onOpenManagerPortal;
  final VoidCallback onOpenAdminPortal;
  final VoidCallback onHowItWorksTap;

  const _HeroSection({
    required this.isWide,
    required this.onOpenManagerPortal,
    required this.onOpenAdminPortal,
    required this.onHowItWorksTap,
  });

  @override
  Widget build(BuildContext context) {
    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1D4ED8).withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Text(
            'India-first offline shopping workflow',
            style: TextStyle(
              color: Color(0xFF7FB0FF),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'India’s Offline Shopping App for Malls and Modern Retail Teams',
          style: TextStyle(
            fontSize: isWide ? 50 : 36,
            fontWeight: FontWeight.w900,
            height: 1.02,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Cartiqo helps shoppers scan, pay, and move faster while malls manage products, imports, pricing, labels, and billing from a single connected system.',
          style: TextStyle(fontSize: 16, height: 1.7, color: Color(0xFFB3C2DD)),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: const [
            _Pill(label: 'Mall QR entry'),
            _Pill(label: 'Barcode + pack-text product find'),
            _Pill(label: 'Manager catalog imports'),
            _Pill(label: 'Digital billing and history'),
          ],
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton.icon(
              onPressed: onOpenManagerPortal,
              icon: const Icon(Icons.download_outlined),
              label: const Text('Register'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: onHowItWorksTap,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Watch How It Works'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFF2C4D8A)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ],
        ),
      ],
    );

    final panel = _PhoneShowcase(onOpenAdminPortal: onOpenAdminPortal);

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1528).withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFF16325E)),
      ),
      child: isWide
          ? Row(
              children: [
                Expanded(flex: 6, child: copy),
                const SizedBox(width: 20),
                Expanded(flex: 5, child: panel),
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
  final VoidCallback onOpenAdminPortal;
  final VoidCallback onOpenManagerPortal;

  const _PortalSection({
    required this.isWide,
    required this.onOpenAdminPortal,
    required this.onOpenManagerPortal,
  });

  @override
  Widget build(BuildContext context) {
    final cards = [
      _PortalCard(
        title: 'Main Admin',
        subtitle:
            'Operate the platform, onboard malls, manage linked managers, and oversee support and subscriptions.',
        accent: const Color(0xFF0B5ED7),
        icon: Icons.admin_panel_settings_outlined,
        features: const [
          'Mall directory',
          'Manager linking',
          'Platform oversight',
        ],
        onPressed: onOpenAdminPortal,
      ),
      _PortalCard(
        title: 'Mall Manager',
        subtitle:
            'Run your own mall catalog, billing settings, labels, imports, and inventory operations.',
        accent: const Color(0xFF12B886),
        icon: Icons.storefront_outlined,
        features: const [
          'Product imports',
          'Inventory control',
          'Billing settings',
        ],
        onPressed: onOpenManagerPortal,
      ),
    ];

    return _SectionShell(
      title: 'Portal Access',
      subtitle:
          'Each role gets a dedicated workspace without exposing the wrong tools or data.',
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
            'Customer Journey Preview',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Show visitors how the product feels before they ever sign in.',
            style: TextStyle(color: Color(0xFFD8E4F7), height: 1.55),
          ),
          SizedBox(height: 18),
          _PreviewRow(label: 'Mall session', value: 'Mall QR scanned'),
          SizedBox(height: 10),
          _PreviewRow(label: 'Product action', value: 'Scan or search item'),
          SizedBox(height: 10),
          _PreviewRow(label: 'Checkout status', value: 'Bill ready for payment'),
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
            'Billing Preview',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Color(0xFF111827),
            ),
          ),
          SizedBox(height: 14),
          _BillLine(label: 'Amul Masti Buttermilk 200ml', value: 'Rs 15.00'),
          _BillLine(label: 'Coca-Cola Original', value: 'Rs 40.00'),
          _BillLine(label: 'Ferrero Rocher 200g', value: 'Rs 425.00'),
          Divider(height: 28),
          _BillLine(label: 'Subtotal', value: 'Rs 480.00'),
          _BillLine(label: 'GST', value: 'Rs 12.00'),
          _BillLine(label: 'Extra charge', value: 'Rs 3.00'),
          Divider(height: 28),
          _BillLine(label: 'Total', value: 'Rs 495.00', emphasis: true),
        ],
      ),
    );

    return _SectionShell(
      title: 'See The Product In Action',
      subtitle:
          'A simple visual walkthrough helps the site feel like a real retail product, not a static brochure.',
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
      title: 'Plans',
      subtitle:
          'Simple positioning for different mall sizes makes the product easier to understand and pitch.',
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
  final VoidCallback onOpenManagerPortal;

  const _CtaSection({
    required this.isWide,
    required this.onOpenManagerPortal,
  });

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
          onPressed: onOpenManagerPortal,
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
                        'Ready to launch Cartiqo in your mall?',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Book a demo, onboard your mall team, and move your retail workflow into one cleaner system.',
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
                  'Ready to launch Cartiqo in your mall?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Book a demo, onboard your mall team, and move your retail workflow into one cleaner system.',
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
        color: const Color(0xFF0E172B).withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFF1A335F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(color: Color(0xFF9AAACC), height: 1.55),
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
    return _HoverLift(
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: const Color(0xFF101B31),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: accent.withValues(alpha: 0.26)),
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
                      color: Colors.white,
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
                color: Color(0xFFA3B2CD),
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
    return _HoverLift(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF101B31),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFF1A335F)),
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
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(color: Color(0xFFA3B2CD), height: 1.55),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureSceneCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<String> tags;

  const _FeatureSceneCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tags,
  });

  @override
  Widget build(BuildContext context) {
    return _HoverLift(
      scale: 1.018,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF111D35), Color(0xFF0B1730)],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF203E72)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 126,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                    ),
                  ),
                ),
                Positioned(
                  left: 18,
                  top: 18,
                  child: Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Icon(icon, color: Colors.white, size: 42),
                  ),
                ),
                Positioned(
                  right: 20,
                  bottom: 18,
                  child: Transform.rotate(
                    angle: -0.22,
                    child: Container(
                      width: 96,
                      height: 58,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0C1630),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF87A9FF)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x66000000),
                            blurRadius: 18,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tags.first,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              tags.length > 1 ? tags[1] : 'Cartiqo',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFFA8C3FF),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(color: Color(0xFFA8B7D3), height: 1.6),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tags
                  .map(
                    (tag) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF162644),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: const Color(0xFF294C87)),
                      ),
                      child: Text(
                        tag,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
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
        color: const Color(0xFF101B31),
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
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: const TextStyle(color: Color(0xFFA3B2CD), height: 1.6),
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
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
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
          color: const Color(0xFF152647),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFF2B4A85)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _NavLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _NavLink({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _PhoneShowcase extends StatelessWidget {
  final VoidCallback onOpenAdminPortal;

  const _PhoneShowcase({
    required this.onOpenAdminPortal,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: Container(
              width: 280,
              height: 560,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                ),
                borderRadius: BorderRadius.circular(42),
                border: Border.all(color: const Color(0xFF8EAFFF), width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x8008182F),
                    blurRadius: 30,
                    offset: Offset(0, 24),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 110,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const Spacer(),
                  const Center(
                    child: Text(
                      'CARTIQO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Center(
                    child: Text(
                      'Login',
                      style: TextStyle(
                        color: Color(0xFFDCE8FF),
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.55)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.email_outlined, color: Colors.white),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Enter Registered Email',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: onOpenAdminPortal,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF1D4ED8),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Get Started'),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Divider(color: Colors.white.withValues(alpha: 0.4)),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'or',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                      Expanded(
                        child: Divider(color: Colors.white.withValues(alpha: 0.4)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.g_mobiledata, color: Colors.white, size: 34),
                      SizedBox(width: 18),
                      Icon(Icons.facebook, color: Colors.white, size: 28),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Center(
                    child: Text(
                      "Don't have an account? Sign Up",
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FixedContactRail extends StatelessWidget {
  final Uri whatsAppUri;
  final Uri emailUri;
  final Uri linkedInUri;
  final Uri instagramUri;

  const _FixedContactRail({
    required this.whatsAppUri,
    required this.emailUri,
    required this.linkedInUri,
    required this.instagramUri,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _SocialBubble(
          icon: Icons.chat_bubble_outline,
          accent: const Color(0xFF22C55E),
          uri: whatsAppUri,
        ),
        const SizedBox(height: 18),
        _SocialBubble(
          icon: Icons.mail_outline,
          accent: const Color(0xFFFFFFFF),
          iconColor: const Color(0xFF111827),
          uri: emailUri,
        ),
        const SizedBox(height: 18),
        _SocialBubble(
          icon: Icons.work_outline,
          accent: const Color(0xFF2563EB),
          uri: linkedInUri,
        ),
        const SizedBox(height: 18),
        _SocialBubble(
          icon: Icons.camera_alt_outlined,
          accent: const Color(0xFFE11D48),
          uri: instagramUri,
        ),
      ],
    );
  }
}

class _SocialBubble extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final Color? iconColor;
  final Uri uri;

  const _SocialBubble({
    required this.icon,
    required this.accent,
    this.iconColor,
    required this.uri,
  });

  @override
  Widget build(BuildContext context) {
    return _HoverLift(
      scale: 1.08,
      lift: 6,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: InkWell(
          onTap: () => openExternalLink(uri.toString()),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.22),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: iconColor ?? accent,
              size: 34,
            ),
          ),
        ),
      ),
    );
  }
}

class _HoverLift extends StatefulWidget {
  final Widget child;
  final double scale;
  final double lift;

  const _HoverLift({
    required this.child,
    this.scale = 1.024,
    this.lift = 4,
  });

  @override
  State<_HoverLift> createState() => _HoverLiftState();
}

class _HoverLiftState extends State<_HoverLift> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()
          ..translate(0.0, _hovered ? -widget.lift : 0.0)
          ..scale(_hovered ? widget.scale : 1.0),
        transformAlignment: Alignment.center,
        child: widget.child,
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
        color: const Color(0xFF0E172B).withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF1A335F)),
      ),
      child: const Text(
        'Cartiqo helps malls run faster checkout, cleaner product operations, and better retail control from one connected platform.',
        style: TextStyle(
          fontSize: 13,
          height: 1.6,
          color: Color(0xFFA3B2CD),
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
