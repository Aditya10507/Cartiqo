import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
  final _emailCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _requestOtp() async {
    final email = _emailCtrl.text.trim().toLowerCase();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter registered manager email')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final provider = context.read<MallManagerProvider>();
    final success = await provider.requestManagerEmailOtp(email: email);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? (provider.error ?? 'OTP sent to manager email.')
              : (provider.error ?? 'Unable to send OTP'),
        ),
      ),
    );

    setState(() => _isLoading = false);
  }

  Future<void> _verifyOtp() async {
    final provider = context.read<MallManagerProvider>();
    final email = (provider.pendingManagerEmail ?? _emailCtrl.text)
        .trim()
        .toLowerCase();
    final otp = _otpCtrl.text.trim();

    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 6-digit OTP')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final success = await provider.verifyManagerEmailOtp(email: email, otp: otp);

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'OTP verification failed')),
      );
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MallManagerProvider>();
    final otpSent = provider.otpSent;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AppModeSelector()),
        );
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
                        'Verify your assigned email to access the manager dashboard',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 28),
                      if (!otpSent) ...[
                        TextField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Registered Email',
                            hintText: 'manager@mall.com',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: const Icon(Icons.mail_outline),
                          ),
                        ),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FBFF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Registered email',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF5F6C7C),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                provider.pendingManagerEmail ?? _emailCtrl.text.trim(),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (provider.otpExpiresAt != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Code valid until ${provider.otpExpiresAt!.toLocal()}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF5F6C7C),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _otpCtrl,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          decoration: InputDecoration(
                            labelText: 'OTP',
                            hintText: 'Enter 6-digit code',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: const Icon(Icons.verified_user_outlined),
                            counterText: '',
                          ),
                        ),
                        if (provider.debugOtp != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF8E1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Development OTP: ${provider.debugOtp}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF7C5A00),
                              ),
                            ),
                          ),
                        ],
                      ],
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FBFF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: Color(0xFF0B5ED7)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                otpSent
                                    ? 'Enter the OTP sent to your assigned email. If it does not arrive, ask the admin to confirm your linked email address.'
                                    : 'Use the email assigned to your mall manager account. We will send a verification code before opening the dashboard.',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF5F6C7C),
                                  height: 1.45,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading
                              ? null
                              : (otpSent ? _verifyOtp : _requestOtp),
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
                              : Text(
                                  otpSent ? 'Verify OTP' : 'Send OTP',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                      if (otpSent) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _isLoading
                                ? null
                                : () {
                                    _otpCtrl.clear();
                                    provider.logout();
                                  },
                            child: const Text('Use another email'),
                          ),
                        ),
                      ],
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
