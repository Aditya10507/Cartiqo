import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/app.dart';
import '../providers/user_auth_provider.dart';
import '../widgets/swiftcart_logo.dart';
import 'email_otp_forgot_password_screen.dart';
import 'mall_select_screen.dart';

enum _AuthMode { signIn, signUp, verifyOtp }

class UserAuthGateScreen extends StatelessWidget {
  const UserAuthGateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserAuthProvider>(
      builder: (context, authProvider, _) {
        if (!authProvider.isReady) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (authProvider.canEnterApp) {
          return const MallSelectScreen();
        }
        return const UserAuthScreen();
      },
    );
  }
}

class UserAuthScreen extends StatefulWidget {
  const UserAuthScreen({super.key});

  @override
  State<UserAuthScreen> createState() => _UserAuthScreenState();
}

class _UserAuthScreenState extends State<UserAuthScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _otpController = TextEditingController();

  _AuthMode _mode = _AuthMode.signUp;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _submitSignUp() async {
    final provider = context.read<UserAuthProvider>();
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    final validationError = _validateSignupForm(
      firstName: firstName,
      lastName: lastName,
      username: username,
      email: email,
      password: password,
      confirmPassword: confirmPassword,
    );

    if (validationError != null) {
      _showMessage(validationError);
      return;
    }

    final success = await provider.requestEmailOtp(
      firstName: firstName,
      lastName: lastName,
      username: username,
      email: email,
      password: password,
    );

    if (!mounted) return;

    if (success) {
      setState(() => _mode = _AuthMode.verifyOtp);
      _showMessage(provider.error ?? 'OTP sent to your email.');
    } else {
      _showMessage(provider.error ?? 'Unable to send OTP.');
    }
  }

  Future<void> _submitSignIn() async {
    final provider = context.read<UserAuthProvider>();
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      _showMessage('Enter your username and password.');
      return;
    }

    final success = await provider.loginWithUsername(
      username: username,
      password: password,
    );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MallSelectScreen()),
      );
    } else {
      _showMessage(provider.error ?? 'Sign in failed.');
    }
  }

  Future<void> _submitOtp() async {
    final provider = context.read<UserAuthProvider>();
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      _showMessage('Please enter the 6-digit OTP.');
      return;
    }

    final success = await provider.verifyEmailOtp(
      email: _emailController.text.trim(),
      otp: otp,
    );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MallSelectScreen()),
      );
    } else {
      _showMessage(provider.error ?? 'OTP verification failed.');
    }
  }

  String? _validateSignupForm({
    required String firstName,
    required String lastName,
    required String username,
    required String email,
    required String password,
    required String confirmPassword,
  }) {
    if (firstName.isEmpty ||
        lastName.isEmpty ||
        username.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      return 'Please complete all signup fields.';
    }

    if (username.length < 4) {
      return 'Username should be at least 4 characters.';
    }

    if (!RegExp(r'^[a-zA-Z0-9._]+$').hasMatch(username)) {
      return 'Username can use letters, numbers, dots, and underscores.';
    }

    if (!_isStrongPassword(password)) {
      return 'Password must be 8-15 characters with uppercase, lowercase, number, and special character.';
    }

    if (password != confirmPassword) {
      return 'Passwords do not match.';
    }

    return null;
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

  void _switchMode(_AuthMode mode) {
    setState(() {
      _mode = mode;
      _otpController.clear();
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserAuthProvider>(
      builder: (context, provider, _) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const AppModeSelector()),
            );
          },
          child: Scaffold(
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
                          onPressed: () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (_) => const AppModeSelector(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const SwiftCartLogo(
                        size: 84,
                        showWordmark: false,
                        primaryColor: Color(0xFFEAF3FF),
                        accentColor: Color(0xFFD8FFF0),
                        backgroundColor: Colors.white,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        _mode == _AuthMode.signIn
                            ? 'Welcome Back'
                            : _mode == _AuthMode.signUp
                                ? 'Create Account'
                                : 'Verify Email',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _mode == _AuthMode.signIn
                            ? 'Sign in with your username and password.'
                            : _mode == _AuthMode.signUp
                                ? 'Set up your SwiftCart account with secure credentials.'
                                : 'Enter the OTP sent to ${_emailController.text.trim()}.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                      const SizedBox(height: 24),
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x22082D59),
                                blurRadius: 26,
                                offset: Offset(0, 18),
                              ),
                            ],
                          ),
                          child: ListView(
                            children: [
                              if (_mode != _AuthMode.verifyOtp)
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F4F8),
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: _ModeChip(
                                          label: 'Sign Up',
                                          selected: _mode == _AuthMode.signUp,
                                          onTap: () => _switchMode(_AuthMode.signUp),
                                        ),
                                      ),
                                      Expanded(
                                        child: _ModeChip(
                                          label: 'Sign In',
                                          selected: _mode == _AuthMode.signIn,
                                          onTap: () => _switchMode(_AuthMode.signIn),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (_mode != _AuthMode.verifyOtp) const SizedBox(height: 22),
                              if (_mode == _AuthMode.signUp) ...[
                                Row(
                                  children: [
                                    Expanded(
                                      child: _ModernField(
                                        controller: _firstNameController,
                                        enabled: !provider.isLoading,
                                        label: 'First name',
                                        icon: Icons.person_outline,
                                        textCapitalization:
                                            TextCapitalization.words,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _ModernField(
                                        controller: _lastNameController,
                                        enabled: !provider.isLoading,
                                        label: 'Last name',
                                        icon: Icons.badge_outlined,
                                        textCapitalization:
                                            TextCapitalization.words,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                _ModernField(
                                  controller: _usernameController,
                                  enabled: !provider.isLoading,
                                  label: 'Username',
                                  icon: Icons.alternate_email,
                                ),
                                const SizedBox(height: 14),
                                _ModernField(
                                  controller: _emailController,
                                  enabled: !provider.isLoading,
                                  label: 'Email address',
                                  icon: Icons.mail_outline,
                                  keyboardType: TextInputType.emailAddress,
                                ),
                                const SizedBox(height: 14),
                                _ModernField(
                                  controller: _passwordController,
                                  enabled: !provider.isLoading,
                                  label: 'Create password',
                                  icon: Icons.lock_outline,
                                  obscureText: _obscurePassword,
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
                                _ModernField(
                                  controller: _confirmPasswordController,
                                  enabled: !provider.isLoading,
                                  label: 'Confirm password',
                                  icon: Icons.verified_user_outlined,
                                  obscureText: _obscureConfirmPassword,
                                  suffixIcon: IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _obscureConfirmPassword =
                                            !_obscureConfirmPassword;
                                      });
                                    },
                                    icon: Icon(
                                      _obscureConfirmPassword
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
                                const SizedBox(height: 20),
                                _PrimaryAction(
                                  loading: provider.isLoading,
                                  label: 'Create account',
                                  onPressed: _submitSignUp,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'We will send a one-time OTP to verify your email before finishing signup.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 12,
                                  ),
                                ),
                              ] else if (_mode == _AuthMode.signIn) ...[
                                _ModernField(
                                  controller: _usernameController,
                                  enabled: !provider.isLoading,
                                  label: 'Username',
                                  icon: Icons.person_2_outlined,
                                ),
                                const SizedBox(height: 14),
                                _ModernField(
                                  controller: _passwordController,
                                  enabled: !provider.isLoading,
                                  label: 'Password',
                                  icon: Icons.lock_outline,
                                  obscureText: _obscurePassword,
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
                                const SizedBox(height: 22),
                                _PrimaryAction(
                                  loading: provider.isLoading,
                                  label: 'Sign in',
                                  onPressed: _submitSignIn,
                                ),
                                const SizedBox(height: 10),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: provider.isLoading
                                        ? null
                                        : () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    const EmailOtpForgotPasswordScreen(),
                                              ),
                                            );
                                          },
                                    child: const Text('Forgot password?'),
                                  ),
                                ),
                              ] else ...[
                                _OtpHeader(
                                  fullName:
                                      '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
                                  username: _usernameController.text.trim(),
                                  email: _emailController.text.trim(),
                                  otpExpiresAt: provider.otpExpiresAt,
                                ),
                                const SizedBox(height: 16),
                                _ModernField(
                                  controller: _otpController,
                                  enabled: !provider.isLoading,
                                  label: 'Email OTP',
                                  icon: Icons.password_outlined,
                                  keyboardType: TextInputType.number,
                                  maxLength: 6,
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
                                _PrimaryAction(
                                  loading: provider.isLoading,
                                  label: 'Verify and continue',
                                  onPressed: _submitOtp,
                                ),
                                const SizedBox(height: 8),
                                TextButton(
                                  onPressed: provider.isLoading
                                      ? null
                                      : () async {
                                          final success =
                                              await provider.requestEmailOtp(
                                            firstName:
                                                _firstNameController.text.trim(),
                                            lastName:
                                                _lastNameController.text.trim(),
                                            username:
                                                _usernameController.text.trim(),
                                            email: _emailController.text.trim(),
                                            password: _passwordController.text,
                                          );
                                          if (!mounted) return;
                                          _showMessage(
                                            success
                                                ? (provider.error ?? 'OTP resent.')
                                                : (provider.error ??
                                                    'Failed to resend OTP.'),
                                          );
                                        },
                                  child: const Text('Resend OTP'),
                                ),
                                TextButton(
                                  onPressed: provider.isLoading
                                      ? null
                                      : () => _switchMode(_AuthMode.signUp),
                                  child: const Text('Back to signup'),
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
          ),
        );
      },
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 12,
                    offset: Offset(0, 5),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: selected ? const Color(0xFF0C5CCF) : const Color(0xFF607085),
          ),
        ),
      ),
    );
  }
}

class _ModernField extends StatelessWidget {
  const _ModernField({
    required this.controller,
    required this.enabled,
    required this.label,
    required this.icon,
    this.textCapitalization = TextCapitalization.none,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
    this.maxLength,
  });

  final TextEditingController controller;
  final bool enabled;
  final String label;
  final IconData icon;
  final TextCapitalization textCapitalization;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final int? maxLength;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      textCapitalization: textCapitalization,
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

class _PrimaryAction extends StatelessWidget {
  const _PrimaryAction({
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

class _OtpHeader extends StatelessWidget {
  const _OtpHeader({
    required this.fullName,
    required this.username,
    required this.email,
    required this.otpExpiresAt,
  });

  final String fullName;
  final String username;
  final String email;
  final DateTime? otpExpiresAt;

  @override
  Widget build(BuildContext context) {
    return Container(
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
            fullName,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          Text('@$username'),
          const SizedBox(height: 4),
          Text(email),
          if (otpExpiresAt != null) ...[
            const SizedBox(height: 10),
            Text(
              'Code valid until ${otpExpiresAt!.toLocal()}',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
