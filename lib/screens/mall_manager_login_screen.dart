import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../app/app.dart';
import '../providers/mall_manager_provider.dart';
import '../widgets/swiftcart_logo.dart';
import 'products_management_screen.dart';
import 'web_mall_manager_dashboard_screen.dart';

class MallManagerLoginScreen extends StatefulWidget {
  const MallManagerLoginScreen({super.key});

  @override
  State<MallManagerLoginScreen> createState() => _MallManagerLoginScreenState();
}

class _MallManagerLoginScreenState extends State<MallManagerLoginScreen> {
  final _managerIdCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _managerIdCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final managerId = _managerIdCtrl.text.trim().toUpperCase();
    final password = _passwordCtrl.text;

    if (managerId.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter Manager ID')));
      return;
    }

    if (password.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter Password')));
      return;
    }

    setState(() => _isLoading = true);

    final provider = context.read<MallManagerProvider>();
    final success = await provider.loginAsMallManager(
      managerId: managerId,
      password: password,
    );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => kIsWeb
              ? const WebMallManagerDashboardScreen()
              : const ProductsManagementScreen(),
        ),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(provider.error ?? 'Login failed')));
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Navigate to home instead of going back
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AppModeSelector()),
        );
        return false; // Prevent default back behavior
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Mall Manager'), elevation: 0),
        body: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 520,
                    minHeight: constraints.maxHeight,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SwiftCartLogo(
                        size: 88,
                        showWordmark: false,
                        primaryColor: Color(0xFF0B5ED7),
                        accentColor: Color(0xFF12B886),
                        backgroundColor: Colors.white,
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Mall Manager Portal',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Login with your manager ID and password',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 28),
                      TextField(
                        controller: _managerIdCtrl,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          labelText: 'Manager ID',
                          hintText: 'e.g., MGR01',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.badge_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passwordCtrl,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            onPressed: () => setState(() {
                              _obscurePassword = !_obscurePassword;
                            }),
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FBFF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline, color: Color(0xFF0B5ED7)),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'If your password is missing or incorrect, ask the admin to reset it from the mall manager panel.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF5F6C7C),
                                  height: 1.45,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text(
                                  'Continue',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
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
}
