import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/user_auth_provider.dart';
import '../widgets/swiftcart_logo.dart';

class EmailOtpForgotPasswordScreen extends StatefulWidget {
  const EmailOtpForgotPasswordScreen({super.key});

  @override
  State<EmailOtpForgotPasswordScreen> createState() =>
      _EmailOtpForgotPasswordScreenState();
}

class _EmailOtpForgotPasswordScreenState
    extends State<EmailOtpForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  int _step = 1;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final provider = context.read<UserAuthProvider>();
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showSnack('Please enter your registered email.');
      return;
    }

    final success = await provider.sendPasswordResetOtp(email);
    if (!mounted) return;

    if (success) {
      setState(() => _step = 2);
      _showSnack(provider.error ?? 'Reset OTP sent to your email.');
    } else {
      _showSnack(provider.error ?? 'Failed to send reset OTP.');
    }
  }

  Future<void> _resetPassword() async {
    final provider = context.read<UserAuthProvider>();
    final otp = _otpController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (otp.length != 6) {
      _showSnack('Please enter the 6-digit OTP.');
      return;
    }

    if (!_isStrongPassword(password)) {
      _showSnack(
        'Password must be 8-15 characters with uppercase, lowercase, number, and special character.',
      );
      return;
    }

    if (password != confirmPassword) {
      _showSnack('Passwords do not match.');
      return;
    }

    final success = await provider.verifyPasswordResetOtp(
      email: _emailController.text.trim(),
      otp: otp,
      newPassword: password,
    );

    if (!mounted) return;

    if (success) {
      _showSnack(provider.error ?? 'Password reset successful.');
      Navigator.of(context).pop();
    } else {
      _showSnack(provider.error ?? 'Password reset failed.');
    }
  }

  bool _isStrongPassword(String password) {
    if (password.length < 8 || password.length > 15) {
      return false;
    }

    final hasUpper = RegExp(r'[A-Z]').hasMatch(password);
    final hasLower = RegExp(r'[a-z]').hasMatch(password);
    final hasDigit = RegExp(r'\d').hasMatch(password);
    final hasSpecial = RegExp(r'[^A-Za-z0-9]').hasMatch(password);

    return hasUpper && hasLower && hasDigit && hasSpecial;
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
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
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0C5CCF), Color(0xFF139B9B), Color(0xFFF6FBFF)],
                stops: [0, 0.45, 0.45],
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
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const SwiftCartLogo(
                      size: 76,
                      showWordmark: false,
                      primaryColor: Color(0xFFEAF3FF),
                      accentColor: Color(0xFFD8FFF0),
                      backgroundColor: Colors.white,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _step == 1 ? 'Forgot Password' : 'Reset Your Password',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _step == 1
                          ? 'Enter your registered email and we will send a verification OTP.'
                          : 'Verify the OTP and choose a new secure password.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: ListView(
                          children: [
                            _Progress(step: _step),
                            const SizedBox(height: 22),
                            if (_step == 1) ...[
                              _Field(
                                controller: _emailController,
                                label: 'Registered email',
                                icon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                enabled: !provider.isLoading,
                              ),
                              const SizedBox(height: 20),
                              _Action(
                                loading: provider.isLoading,
                                label: 'Send OTP',
                                onPressed: _sendOtp,
                              ),
                            ] else ...[
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5F8FF),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: const Color(0xFFD7E4F7)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _emailController.text.trim(),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    if (provider.otpExpiresAt != null) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        'Code valid until ${provider.otpExpiresAt!.toLocal()}',
                                        style: TextStyle(
                                          color: Colors.grey[700],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              _Field(
                                controller: _otpController,
                                label: 'OTP',
                                icon: Icons.password_outlined,
                                keyboardType: TextInputType.number,
                                maxLength: 6,
                                enabled: !provider.isLoading,
                              ),
                              const SizedBox(height: 14),
                              _Field(
                                controller: _passwordController,
                                label: 'New password',
                                icon: Icons.lock_outline,
                                obscureText: _obscurePassword,
                                enabled: !provider.isLoading,
                                suffixIcon: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              _Field(
                                controller: _confirmPasswordController,
                                label: 'Confirm new password',
                                icon: Icons.verified_user_outlined,
                                obscureText: _obscureConfirm,
                                enabled: !provider.isLoading,
                                suffixIcon: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _obscureConfirm = !_obscureConfirm;
                                    });
                                  },
                                  icon: Icon(
                                    _obscureConfirm
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FBFF),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: const Color(0xFFD8E6F5)),
                                ),
                                child: const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Password rules',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF16324F),
                                      ),
                                    ),
                                    SizedBox(height: 6),
                                    Text('8-15 characters'),
                                    Text('At least 1 uppercase and 1 lowercase letter'),
                                    Text('At least 1 number and 1 special character'),
                                  ],
                                ),
                              ),
                              if ((provider.lastDemoPhoneOtp ?? '').isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.amber[50],
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.amber[300]!),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Development OTP',
                                        style: TextStyle(fontWeight: FontWeight.w700),
                                      ),
                                      const SizedBox(height: 8),
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
                              ],
                              const SizedBox(height: 20),
                              _Action(
                                loading: provider.isLoading,
                                label: 'Reset password',
                                onPressed: _resetPassword,
                              ),
                              const SizedBox(height: 10),
                              TextButton(
                                onPressed: provider.isLoading
                                    ? null
                                    : () async {
                                        final success =
                                            await provider.sendPasswordResetOtp(
                                          _emailController.text.trim(),
                                        );
                                        if (!mounted) return;
                                        _showSnack(
                                          success
                                              ? (provider.error ?? 'OTP resent.')
                                              : (provider.error ??
                                                  'Failed to resend OTP.'),
                                        );
                                      },
                                child: const Text('Resend OTP'),
                              ),
                            ],
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
      },
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFF0C5CCF),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 4,
            decoration: BoxDecoration(
              color: step >= 2 ? const Color(0xFF0C5CCF) : Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    required this.enabled,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
    this.maxLength,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool enabled;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final int? maxLength;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLength: maxLength,
      decoration: InputDecoration(
        labelText: label,
        counterText: '',
        filled: true,
        fillColor: const Color(0xFFF9FBFD),
        prefixIcon: Icon(icon),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFD6E2EC)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFD6E2EC)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFF0C5CCF), width: 1.4),
        ),
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.loading,
    required this.label,
    required this.onPressed,
  });

  final bool loading;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF0C5CCF),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        onPressed: loading ? null : onPressed,
        child: loading
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
      ),
    );
  }
}
