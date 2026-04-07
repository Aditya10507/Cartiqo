import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/app.dart';
import '../providers/mall_manager_provider.dart';
import '../widgets/swiftcart_logo.dart';
import 'products_management_screen.dart';
import 'web_mall_manager_dashboard_screen.dart';

enum _ManagerAuthMode {
  signIn,
  signUp,
  forgotPassword,
}

class MallManagerLoginScreen extends StatefulWidget {
  const MallManagerLoginScreen({super.key});

  @override
  State<MallManagerLoginScreen> createState() => _MallManagerLoginScreenState();
}

class _MallManagerLoginScreenState extends State<MallManagerLoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  bool _isLoading = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  _ManagerAuthMode _mode = _ManagerAuthMode.signIn;

  bool _isValidEmail(String email) {
    final value = email.trim().toLowerCase();
    final pattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return pattern.hasMatch(value);
  }

  String? _validateInputs() {
    final email = _emailCtrl.text.trim();
    if (!_isValidEmail(email)) {
      return 'Please enter a valid registered email address.';
    }

    if (_mode == _ManagerAuthMode.signIn) {
      if (_passwordCtrl.text.isEmpty) {
        return 'Please enter your password.';
      }
    }

    if (_mode == _ManagerAuthMode.signUp) {
      final provider = context.read<MallManagerProvider>();
      if (!provider.signupOtpSent) {
        if (_passwordCtrl.text.isEmpty || _confirmPasswordCtrl.text.isEmpty) {
          return 'Please create and confirm your password.';
        }
        if (_passwordCtrl.text != _confirmPasswordCtrl.text) {
          return 'Password and confirm password must match.';
        }
      } else if (_otpCtrl.text.trim().length != 6) {
        return 'Please enter a valid 6-digit OTP.';
      }
    }

    if (_mode == _ManagerAuthMode.forgotPassword) {
      final provider = context.read<MallManagerProvider>();
      if (provider.passwordResetOtpSent) {
        if (_otpCtrl.text.trim().length != 6) {
          return 'Please enter a valid 6-digit OTP.';
        }
        if (_passwordCtrl.text.isEmpty || _confirmPasswordCtrl.text.isEmpty) {
          return 'Please enter and confirm your new password.';
        }
        if (_passwordCtrl.text != _confirmPasswordCtrl.text) {
          return 'Password and confirm password must match.';
        }
      }
    }

    return null;
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final success = await context.read<MallManagerProvider>().loginWithEmailPassword(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
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
      return;
    }

    _showSnack(
      context.read<MallManagerProvider>().error ?? 'Unable to sign in.',
    );
  }

  Future<void> _requestSignupOtp() async {
    final provider = context.read<MallManagerProvider>();
    final success = await provider.requestManagerSignupOtp(
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
      confirmPassword: _confirmPasswordCtrl.text,
    );

    if (!mounted) return;
    _showSnack(provider.error ?? (success ? 'OTP sent to your email.' : 'Unable to send OTP.'));
  }

  Future<void> _verifySignupOtp() async {
    final provider = context.read<MallManagerProvider>();
    final success = await provider.verifyManagerSignupOtp(
      email: (provider.pendingManagerEmail ?? _emailCtrl.text).trim(),
      otp: _otpCtrl.text.trim(),
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
      return;
    }

    _showSnack(provider.error ?? 'OTP verification failed.');
  }

  Future<void> _requestResetOtp() async {
    final provider = context.read<MallManagerProvider>();
    final success = await provider.requestManagerPasswordResetOtp(
      email: _emailCtrl.text.trim(),
    );

    if (!mounted) return;
    _showSnack(
      provider.error ??
          (success ? 'Password reset OTP sent to your email.' : 'Unable to send OTP.'),
    );
  }

  Future<void> _resetPassword() async {
    final provider = context.read<MallManagerProvider>();
    final success = await provider.resetManagerPassword(
      email: (provider.pendingManagerEmail ?? _emailCtrl.text).trim(),
      otp: _otpCtrl.text.trim(),
      newPassword: _passwordCtrl.text,
      confirmPassword: _confirmPasswordCtrl.text,
    );

    if (!mounted) return;

    if (success) {
      _showSnack('Password reset successful. Please sign in.');
      _otpCtrl.clear();
      _passwordCtrl.clear();
      _confirmPasswordCtrl.clear();
      setState(() => _mode = _ManagerAuthMode.signIn);
      return;
    }

    _showSnack(provider.error ?? 'Unable to reset password.');
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MallManagerProvider>();
    final signupOtpSent = provider.signupOtpSent;
    final resetOtpSent = provider.passwordResetOtpSent;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
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
                    maxWidth: 560,
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
                      Text(
                        _subtitle(signupOtpSent, resetOtpSent),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 24),
                      if (!signupOtpSent && !resetOtpSent) _buildModeTabs(),
                      const SizedBox(height: 20),
                      _buildEmailField(readOnly: signupOtpSent || resetOtpSent),
                      const SizedBox(height: 16),
                      if (_mode == _ManagerAuthMode.signIn) ...[
                        _buildPasswordField(
                          _passwordCtrl,
                          'Password',
                          obscureText: !_showPassword,
                          onToggleVisibility: () {
                            setState(() => _showPassword = !_showPassword);
                          },
                        ),
                      ],
                      if (_mode == _ManagerAuthMode.signUp && !signupOtpSent) ...[
                        _buildPasswordField(
                          _passwordCtrl,
                          'Create Password',
                          obscureText: !_showPassword,
                          onToggleVisibility: () {
                            setState(() => _showPassword = !_showPassword);
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildPasswordField(
                          _confirmPasswordCtrl,
                          'Confirm Password',
                          obscureText: !_showConfirmPassword,
                          onToggleVisibility: () {
                            setState(() =>
                                _showConfirmPassword = !_showConfirmPassword);
                          },
                        ),
                      ],
                      if (_mode == _ManagerAuthMode.signUp && signupOtpSent) ...[
                        _buildInfoBox(
                          provider.pendingManagerEmail ?? _emailCtrl.text.trim(),
                          provider.otpExpiresAt,
                          provider.debugOtp,
                        ),
                        const SizedBox(height: 16),
                        _buildOtpField(),
                      ],
                      if (_mode == _ManagerAuthMode.forgotPassword &&
                          !resetOtpSent) ...[
                        const SizedBox(height: 8),
                      ],
                      if (_mode == _ManagerAuthMode.forgotPassword &&
                          resetOtpSent) ...[
                        _buildInfoBox(
                          provider.pendingManagerEmail ?? _emailCtrl.text.trim(),
                          provider.otpExpiresAt,
                          provider.debugOtp,
                        ),
                        const SizedBox(height: 16),
                        _buildOtpField(),
                        const SizedBox(height: 16),
                        _buildPasswordField(
                          _passwordCtrl,
                          'Create New Password',
                          obscureText: !_showPassword,
                          onToggleVisibility: () {
                            setState(() => _showPassword = !_showPassword);
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildPasswordField(
                          _confirmPasswordCtrl,
                          'Confirm New Password',
                          obscureText: !_showConfirmPassword,
                          onToggleVisibility: () {
                            setState(() =>
                                _showConfirmPassword = !_showConfirmPassword);
                          },
                        ),
                      ],
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _primaryAction,
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
                                    valueColor:
                                        AlwaysStoppedAnimation(Colors.white),
                                  ),
                                )
                              : Text(
                                  _primaryLabel(signupOtpSent, resetOtpSent),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_mode == _ManagerAuthMode.signIn &&
                          !signupOtpSent &&
                          !resetOtpSent)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              context.read<MallManagerProvider>().logout();
                              _otpCtrl.clear();
                              _passwordCtrl.clear();
                              _confirmPasswordCtrl.clear();
                              setState(() => _mode = _ManagerAuthMode.forgotPassword);
                            },
                            child: const Text('Forgot password?'),
                          ),
                        ),
                      if (signupOtpSent || resetOtpSent)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              provider.logout();
                              _otpCtrl.clear();
                              _passwordCtrl.clear();
                              _confirmPasswordCtrl.clear();
                              setState(() {});
                            },
                            child: const Text('Use another email'),
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

  Widget _buildModeTabs() {
    return SegmentedButton<_ManagerAuthMode>(
      segments: const [
        ButtonSegment(
          value: _ManagerAuthMode.signIn,
          label: Text('Sign In'),
        ),
        ButtonSegment(
          value: _ManagerAuthMode.signUp,
          label: Text('Sign Up'),
        ),
        ButtonSegment(
          value: _ManagerAuthMode.forgotPassword,
          label: Text('Forgot Password'),
        ),
      ],
      selected: {_mode},
      onSelectionChanged: (selection) {
        context.read<MallManagerProvider>().logout();
        _otpCtrl.clear();
        _passwordCtrl.clear();
        _confirmPasswordCtrl.clear();
        setState(() => _mode = selection.first);
      },
    );
  }

  Widget _buildEmailField({required bool readOnly}) {
    return TextField(
      controller: _emailCtrl,
      readOnly: readOnly,
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        labelText: 'Registered Email',
        hintText: 'manager@mall.com',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        prefixIcon: const Icon(Icons.mail_outline),
      ),
    );
  }

  Widget _buildPasswordField(
    TextEditingController controller,
    String label, {
    required bool obscureText,
    required VoidCallback onToggleVisibility,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          onPressed: onToggleVisibility,
          icon: Icon(
            obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          ),
        ),
      ),
    );
  }

  Widget _buildOtpField() {
    return TextField(
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
    );
  }

  Widget _buildInfoBox(String email, DateTime? expiresAt, String? debugOtp) {
    return Container(
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
            email,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (expiresAt != null) ...[
            const SizedBox(height: 8),
            Text(
              'Code valid until ${expiresAt.toLocal()}',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF5F6C7C),
              ),
            ),
          ],
          if (debugOtp != null) ...[
            const SizedBox(height: 10),
            Text(
              'Development OTP: $debugOtp',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF7C5A00),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _subtitle(bool signupOtpSent, bool resetOtpSent) {
    if (signupOtpSent) {
      return 'Enter the OTP sent to your linked manager email to finish account setup.';
    }
    if (resetOtpSent) {
      return 'Verify your email with OTP and create a new password for this manager account.';
    }
    return switch (_mode) {
      _ManagerAuthMode.signIn =>
        'Sign in with the email linked to your manager account.',
      _ManagerAuthMode.signUp =>
        'Use your linked manager email and create a password for first-time access.',
      _ManagerAuthMode.forgotPassword =>
        'Enter your linked manager email to reset your password with OTP.',
    };
  }

  String _primaryLabel(bool signupOtpSent, bool resetOtpSent) {
    if (_mode == _ManagerAuthMode.signIn) {
      return 'Sign In';
    }
    if (_mode == _ManagerAuthMode.signUp) {
      return signupOtpSent ? 'Verify OTP' : 'Create Account';
    }
    return resetOtpSent ? 'Reset Password' : 'Send OTP';
  }

  Future<void> _primaryAction() async {
    final validationError = _validateInputs();
    if (validationError != null) {
      _showSnack(validationError);
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (_mode == _ManagerAuthMode.signIn) {
        await _login();
      } else if (_mode == _ManagerAuthMode.signUp) {
        final provider = context.read<MallManagerProvider>();
        if (provider.signupOtpSent) {
          await _verifySignupOtp();
        } else {
          await _requestSignupOtp();
        }
      } else {
        final provider = context.read<MallManagerProvider>();
        if (provider.passwordResetOtpSent) {
          await _resetPassword();
        } else {
          await _requestResetOtp();
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
