import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
import '../providers/user_auth_provider.dart';
import '../services/storefront_api_service.dart';
import '../app/app.dart';
import '../widgets/swiftcart_logo.dart';
import 'scan_product_screen.dart' deferred as scan_product;
import 'mall_qr_scanner_screen.dart' deferred as mall_qr_scanner;
import 'user_profile_screen.dart' deferred as user_profile;

class MallSelectScreen extends StatefulWidget {
  const MallSelectScreen({super.key});

  @override
  State<MallSelectScreen> createState() => _MallSelectScreenState();
}

class _MallSelectScreenState extends State<MallSelectScreen> {
  final _storefrontApiService = StorefrontApiService();
  final _controller = TextEditingController();
  String? _error;
  bool _checking = false;

  bool _isValidMallId(String input) {
    final s = input.trim().toUpperCase();
    // 6 digits area + 2 digits mall + 2 letters + 2 digits year
    return RegExp(r'^\d{8}[A-Z]{2}\d{2}$').hasMatch(s);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _continueWithMallId(String mallIdRaw) async {
    final mallId = mallIdRaw.trim().toUpperCase();

    if (!_isValidMallId(mallId)) {
      setState(() => _error = "Invalid Mall ID (Example: 11000103CP19)");
      return;
    }

    setState(() {
      _checking = true;
      _error = null;
    });

    try {
      await _storefrontApiService.fetchBillingSettings(mallId);

      if (!mounted) return;
      await scan_product.loadLibrary();
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => scan_product.ScanProductScreen(mallId: mallId),
        ),
      );
    } catch (e) {
      setState(
        () => _error = e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _scanMallQr() async {
    await mall_qr_scanner.loadLibrary();
    if (!mounted) return;
    final scannedMallId = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => mall_qr_scanner.MallQrScannerScreen(),
      ),
    );

    if (scannedMallId == null) return;

    _controller.text = scannedMallId;
    await _continueWithMallId(scannedMallId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF4FBFF), Color(0xFFEAF1FF), Color(0xFFF8F0FF)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const SwiftCartLogo(
                      size: 46,
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
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Select your mall and start scanning',
                            style: TextStyle(color: Color(0xFF607089)),
                          ),
                        ],
                      ),
                    ),
                    IconButton.filledTonal(
                      onPressed: () async {
                        await user_profile.loadLibrary();
                        if (!mounted) return;
                        Navigator.push(
                          this.context,
                          MaterialPageRoute(
                            builder: (_) => user_profile.UserProfileScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.person_outline),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      onPressed: _showLogoutDialog,
                      icon: const Icon(Icons.logout),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.white),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x12000000),
                        blurRadius: 24,
                        offset: Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F2FF),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'Fast checkout entry',
                          style: TextStyle(
                            color: Color(0xFF0B5ED7),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Scan a mall QR or enter your Mall ID',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Pick a mall and continue to the product scanner. You can also jump straight in using a valid Mall ID.',
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          color: Color(0xFF607089),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: const [
                          _QuickChip(label: 'QR scan'),
                          _QuickChip(label: 'Manual ID'),
                          _QuickChip(label: 'Profile'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Scan Mall QR',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Use the QR label at the mall entrance for instant access.',
                          style: TextStyle(color: Color(0xFF607089)),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _checking ? null : _scanMallQr,
                            icon: const Icon(Icons.qr_code_scanner),
                            label: const Text("Scan Mall QR"),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Enter Mall ID',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _controller,
                          textCapitalization: TextCapitalization.characters,
                          decoration: InputDecoration(
                            labelText: "Mall ID",
                            hintText: "Example: 11000103CP19",
                            border: const OutlineInputBorder(),
                            errorText: _error,
                          ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _checking
                                ? null
                                : () => _continueWithMallId(_controller.text),
                            child: _checking
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text("Continue"),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Do you want to logout from the user panel?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final cartProvider = context.read<CartProvider>();
              final authProvider = context.read<UserAuthProvider>();
              navigator.pop();
              cartProvider.clear();
              await authProvider.logout();
              if (!mounted) return;
              navigator.pushReplacement(
                MaterialPageRoute(builder: (_) => const AppModeSelector()),
              );
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  final String label;

  const _QuickChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}
