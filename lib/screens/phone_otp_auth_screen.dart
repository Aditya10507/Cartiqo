import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_auth_provider.dart';
import 'mall_select_screen.dart';
import '../widgets/swiftcart_logo.dart';

class PhoneOtpAuthScreen extends StatefulWidget {
  const PhoneOtpAuthScreen({super.key});

  @override
  State<PhoneOtpAuthScreen> createState() => _PhoneOtpAuthScreenState();
}

class _PhoneOtpAuthScreenState extends State<PhoneOtpAuthScreen>
    with SingleTickerProviderStateMixin {
  late TextEditingController _phoneController;
  late TextEditingController _otpController;
  late TextEditingController _nameController;
  
  int _step = 1; // 1: Phone, 2: OTP
  bool _isLoading = false;
  bool _isSignup = false;
  int _otpResendCountdown = 0;
  late AnimationController _timerController;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController();
    _otpController = TextEditingController();
    _nameController = TextEditingController();
    _timerController =
        AnimationController(duration: const Duration(seconds: 120), vsync: this);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _nameController.dispose();
    _timerController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      _showSnack('Please enter your phone number');
      return;
    }

    if (!RegExp(r'^\+\d{10,15}$').hasMatch(phone)) {
      _showSnack('Please enter valid phone with country code (e.g., +919876543210)');
      return;
    }

    setState(() => _isLoading = true);

    final provider = context.read<UserAuthProvider>();
    final success = await provider.sendCustomPhoneOtp(phone);

    if (!mounted) return;

    if (success) {
      setState(() {
        _step = 2;
        _isLoading = false;
        _otpResendCountdown = 300; // 5 minutes
      });
      _startResendCountdown();
      _showSnack('OTP sent successfully');
    } else {
      setState(() => _isLoading = false);
      _showSnack(provider.error ?? 'Failed to send OTP');
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.isEmpty || otp.length != 6) {
      _showSnack('Please enter 6-digit OTP');
      return;
    }

    if (_isSignup && _nameController.text.trim().isEmpty) {
      _showSnack('Please enter your name');
      return;
    }

    setState(() => _isLoading = true);

    final provider = context.read<UserAuthProvider>();
    final success = await provider.verifyCustomPhoneOtp(
      phoneNumber: _phoneController.text.trim(),
      otp: otp,
      name: _isSignup ? _nameController.text.trim() : null,
    );

    if (!mounted) return;

    if (success) {
      _showSnack('Phone verified successfully');
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MallSelectScreen()),
          );
        }
      });
    } else {
      setState(() => _isLoading = false);
      _showSnack(provider.error ?? 'OTP verification failed');
    }
  }

  Future<void> _resendOtp() async {
    if (_otpResendCountdown > 0) {
      _showSnack('Please wait before resending');
      return;
    }

    setState(() => _isLoading = true);

    final provider = context.read<UserAuthProvider>();
    final success = await provider.resendCustomPhoneOtp(_phoneController.text.trim());

    if (!mounted) return;

    if (success) {
      setState(() {
        _isLoading = false;
        _otpResendCountdown = 300;
        _otpController.clear();
      });
      _startResendCountdown();
      _showSnack('New OTP sent');
    } else {
      setState(() => _isLoading = false);
      _showSnack(provider.error ?? 'Failed to resend');
    }
  }

  void _startResendCountdown() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() {
        _otpResendCountdown--;
      });
      return _otpResendCountdown > 0;
    });
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 3)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserAuthProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0B5ED7), Color(0xFF0F9B8E)],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const SwiftCartLogo(
                      size: 84,
                      showWordmark: false,
                      primaryColor: Color(0xFFEAF3FF),
                      accentColor: Color(0xFFD8FFF0),
                      backgroundColor: Colors.white,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Phone Verification',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _step == 1
                          ? 'Enter your phone number to ${_isSignup ? 'create account' : 'login'}'
                          : 'Enter the OTP sent to ${_phoneController.text}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Progress indicator
                              Padding(
                                padding: const EdgeInsets.only(bottom: 24),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        height: 4,
                                        decoration: BoxDecoration(
                                          color: Colors.blue,
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Container(
                                        height: 4,
                                        decoration: BoxDecoration(
                                          color:
                                              _step >= 2 ? Colors.blue : Colors.grey[300],
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Step 1: Phone Number
                              if (_step == 1) ...[
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.amber[50],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.amber[200]!),
                                  ),
                                  child: const Text(
                                    'No-Blaze demo mode: the app generates a local OTP and shows it after you tap Send OTP.',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                if (_isSignup)
                                  Column(
                                    children: [
                                      TextField(
                                        controller: _nameController,
                                        enabled: !_isLoading,
                                        decoration: const InputDecoration(
                                          labelText: 'Full Name',
                                          border: OutlineInputBorder(),
                                          prefixIcon: Icon(Icons.person),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                    ],
                                  ),
                                TextField(
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  enabled: !_isLoading,
                                  decoration: const InputDecoration(
                                    labelText: 'Phone Number',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.phone),
                                    hintText: '+919876543210',
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Include country code (e.g., +91 for India)',
                                    style: TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _sendOtp,
                                    child: _isLoading
                                        ? const SizedBox(
                                            height: 18,
                                            width: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : Text(_isSignup ? 'Create Account' : 'Send OTP'),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                if (provider.lastDemoPhoneOtp != null) ...[
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.green[50],
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.green[200]!),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Demo OTP',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        SelectableText(
                                          provider.lastDemoPhoneOtp!,
                                          style: const TextStyle(
                                            fontSize: 22,
                                            letterSpacing: 6,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                                Center(
                                  child: TextButton(
                                    onPressed: () {
                                      setState(() => _isSignup = !_isSignup);
                                      _nameController.clear();
                                    },
                                    child: Text(
                                      _isSignup
                                          ? 'Already have account? Login'
                                          : 'Don\'t have account? Sign up',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ),
                              ],
                              // Step 2: OTP Verification
                              if (_step == 2) ...[
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[50],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.blue[200]!),
                                  ),
                                  child: Column(
                                    children: [
                                      const Icon(Icons.sms, color: Colors.blue, size: 32),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'Enter OTP',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'We sent a 6-digit code to\n${_phoneController.text}',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),
                                TextField(
                                  controller: _otpController,
                                  keyboardType: TextInputType.number,
                                  maxLength: 6,
                                  enabled: !_isLoading,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 8,
                                  ),
                                  decoration: InputDecoration(
                                    border: const OutlineInputBorder(),
                                    counterText: '',
                                    hintText: '000000',
                                    hintStyle: TextStyle(
                                      color: Colors.grey[300],
                                      fontSize: 24,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _verifyOtp,
                                    child: _isLoading
                                        ? const SizedBox(
                                            height: 18,
                                            width: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Text('Verify OTP'),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (_otpResendCountdown > 0) ...[
                                      const Text(
                                        'Resend OTP in ',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                      TweenAnimationBuilder<int>(
                                        tween: IntTween(
                                          begin: _otpResendCountdown,
                                          end: 0,
                                        ),
                                        duration:
                                            Duration(seconds: _otpResendCountdown),
                                        builder: (context, value, child) {
                                          return Text(
                                            _formatTime(value),
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blue,
                                            ),
                                          );
                                        },
                                      ),
                                    ] else
                                      TextButton.icon(
                                        onPressed: _isLoading ? null : _resendOtp,
                                        icon: const Icon(Icons.refresh, size: 16),
                                        label: const Text('Resend OTP'),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                TextButton(
                                  onPressed: _isLoading
                                      ? null
                                      : () => setState(() => _step = 1),
                                  child: const Text('Change Phone Number'),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
