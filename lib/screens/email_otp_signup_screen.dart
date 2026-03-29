import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_auth_provider.dart';
import '../widgets/swiftcart_logo.dart';

class EmailOtpSignupScreen extends StatefulWidget {
  const EmailOtpSignupScreen({super.key});

  @override
  State<EmailOtpSignupScreen> createState() => _EmailOtpSignupScreenState();
}

class _EmailOtpSignupScreenState extends State<EmailOtpSignupScreen>
    with SingleTickerProviderStateMixin {
  late TextEditingController _emailController;
  late TextEditingController _otpController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;
  late TextEditingController _nameController;

  int _step = 1; // 1: Email, 2: OTP, 3: Password
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  int _resendCountdown = 0;
  late AnimationController _timerController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _otpController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _nameController = TextEditingController();
    _timerController =
        AnimationController(duration: const Duration(seconds: 120), vsync: this);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _timerController.dispose();
    super.dispose();
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _sendOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showSnack('Please enter your email');
      return;
    }

    setState(() => _isLoading = true);
    final provider = Provider.of<UserAuthProvider>(context, listen: false);
    final success = await provider.sendEmailOtpSignup(email);
    setState(() => _isLoading = false);

    if (!success) {
      _showSnack(provider.error ?? 'Failed to send OTP');
      return;
    }

    setState(() => _step = 2);
    _startResendCountdown();
    _showSnack('OTP sent to $email');
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.isEmpty) {
      _showSnack('Please enter the OTP');
      return;
    }

    if (otp.length != 6) {
      _showSnack('OTP must be 6 digits');
      return;
    }

    setState(() => _isLoading = true);
    final provider = Provider.of<UserAuthProvider>(context, listen: false);
    final success = await provider.verifyEmailOtpSignup(
      email: _emailController.text.trim(),
      otp: otp,
    );
    setState(() => _isLoading = false);

    if (!success) {
      _showSnack(provider.error ?? 'OTP verification failed');
      return;
    }

    setState(() => _step = 3);
    _showSnack('Email verified! Now set your password');
  }

  Future<void> _completeSignup() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    final name = _nameController.text.trim();

    if (email.isEmpty || password.isEmpty || name.isEmpty) {
      _showSnack('Please fill all fields');
      return;
    }

    if (password.length < 6) {
      _showSnack('Password must be at least 6 characters');
      return;
    }

    if (password != confirmPassword) {
      _showSnack('Passwords do not match');
      return;
    }

    setState(() => _isLoading = true);
    final provider = Provider.of<UserAuthProvider>(context, listen: false);

    final success = await provider.createUserWithEmailPassword(
      email: email,
      password: password,
      name: name,
    );

    setState(() => _isLoading = false);

    if (!success) {
      _showSnack(provider.error ?? 'Signup failed');
      return;
    }

    _showSnack('Signup successful!');
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/mall-select');
    }
  }

  Future<void> _resendOtp() async {
    final email = _emailController.text.trim();
    setState(() => _isLoading = true);
    final provider = Provider.of<UserAuthProvider>(context, listen: false);
    final success = await provider.sendEmailOtpSignup(email);
    setState(() => _isLoading = false);

    if (!success) {
      _showSnack(provider.error ?? 'Failed to resend OTP');
      return;
    }

    _startResendCountdown();
    _showSnack('OTP resent to $email');
  }

  void _startResendCountdown() {
    setState(() => _resendCountdown = 120);
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          if (_resendCountdown > 0) _resendCountdown--;
        });
      }
      return _resendCountdown > 0;
    });
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _changeEmail() {
    setState(() => _step = 1);
    _otpController.clear();
    _timerController.reset();
  }

  @override
  Widget build(BuildContext context) {
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                const SwiftCartLogo(size: 60),
                const SizedBox(height: 24),
                Text(
                  _step == 1
                      ? 'Create Account'
                      : _step == 2
                          ? 'Verify Email'
                          : 'Set Password',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _step == 1
                      ? 'Sign up with your email'
                      : _step == 2
                          ? 'Enter the OTP sent to your email'
                          : 'Create a strong password',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Progress indicator (3 steps)
                Row(
                  children: List.generate(
                    3,
                    (index) => Expanded(
                      child: Container(
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: index < _step
                              ? Colors.white
                              : Colors.white30,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 36),

                // Step 1: Email Entry
                if (_step == 1) ...[
                  TextField(
                    controller: _emailController,
                    enabled: !_isLoading,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      prefixIcon: const Icon(Icons.email),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _nameController,
                    enabled: !_isLoading,
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _sendOtp,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFF0B5ED7),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Send OTP',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],

                // Step 2: OTP Verification
                if (_step == 2) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white30),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'OTP sent to',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _emailController.text,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _otpController,
                    enabled: !_isLoading,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: '000000',
                      hintStyle: const TextStyle(fontSize: 32),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      counterText: '',
                    ),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 8,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _verifyOtp,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFF0B5ED7),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Verify OTP',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 500),
                    builder: (context, value, child) {
                      return Opacity(opacity: value, child: child);
                    },
                    child: Column(
                      children: [
                        if (_resendCountdown > 0) ...[
                          Text(
                            'Resend OTP in ${_formatTime(_resendCountdown)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ] else ...[
                          TextButton(
                            onPressed: _isLoading ? null : _resendOtp,
                            child: const Text(
                              'Resend OTP',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _changeEmail,
                    child: const Text(
                      'Change Email',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],

                // Step 3: Password Setup
                if (_step == 3) ...[
                  TextField(
                    controller: _passwordController,
                    enabled: !_isLoading,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _confirmPasswordController,
                    enabled: !_isLoading,
                    obscureText: _obscureConfirm,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureConfirm
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Password must be at least 6 characters',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _completeSignup,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFF0B5ED7),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Create Account',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
