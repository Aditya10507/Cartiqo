import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/app.dart';
import '../providers/user_auth_provider.dart';
import 'mall_select_screen.dart';
import 'email_verification_pending_screen.dart';
import 'phone_otp_auth_screen.dart';
import '../widgets/swiftcart_logo.dart';

class UserAuthGateScreen extends StatelessWidget {
  const UserAuthGateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserAuthProvider>(
      builder: (context, authProvider, _) {
        if (authProvider.canEnterApp) {
          return const MallSelectScreen();
        }
        if (authProvider.needsEmailVerification) {
          return EmailVerificationPendingScreen(
            email: authProvider.currentUser?.email ?? '',
          );
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

class _UserAuthScreenState extends State<UserAuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _emailNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isEmailLogin = true;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleEmailAuth() async {
    final provider = context.read<UserAuthProvider>();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _emailNameController.text.trim();

    if (!_isEmailLogin && name.isEmpty) {
      _showMessage('Please enter your name.');
      return;
    }
    if (email.isEmpty || password.isEmpty) {
      _showMessage('Please fill all required fields.');
      return;
    }

    final success = _isEmailLogin
        ? await provider.loginWithEmail(email: email, password: password)
        : await provider.signUpWithEmail(
            name: name,
            email: email,
            password: password,
          );

    if (!mounted) return;
    if (success && _isEmailLogin) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MallSelectScreen()),
      );
    } else if (success && !_isEmailLogin) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => EmailVerificationPendingScreen(email: email),
        ),
      );
    } else {
      if (provider.needsEmailVerification) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => EmailVerificationPendingScreen(email: email),
          ),
        );
        return;
      }
      _showMessage(provider.error ?? 'Authentication failed.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showForgotPasswordDialog(BuildContext context, UserAuthProvider provider) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return _ForgotPasswordDialog(provider: provider);
      },
    ).then((_) {
      // Ensure state is properly cleared after dialog closes
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserAuthProvider>(
      builder: (context, provider, _) {
        return WillPopScope(
          onWillPop: () async {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const AppModeSelector()),
            );
            return false;
          },
          child: Scaffold(
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
                        'User Login',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Sign in before selecting a mall and scanning products',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 24),
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            children: [
                              TabBar(
                                controller: _tabController,
                                tabs: const [
                                  Tab(text: 'Email'),
                                  Tab(text: 'Phone'),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Expanded(
                                child: TabBarView(
                                  controller: _tabController,
                                  children: [
                                    _buildEmailTab(provider),
                                    _buildPhoneTab(),
                                  ],
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
          ),
        );
      },
    );
  }

  Widget _buildEmailTab(UserAuthProvider provider) {
    return ListView(
      children: [
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment<bool>(value: true, label: Text('Login')),
            ButtonSegment<bool>(value: false, label: Text('Signup')),
          ],
          selected: {_isEmailLogin},
          onSelectionChanged: (selection) {
            setState(() => _isEmailLogin = selection.first);
          },
        ),
        const SizedBox(height: 16),
        if (!_isEmailLogin) ...[
          TextField(
            controller: _emailNameController,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
        ],
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: 'Password',
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              onPressed: () {
                setState(() => _obscurePassword = !_obscurePassword);
              },
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: provider.isLoading ? null : _handleEmailAuth,
            child: provider.isLoading
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(_isEmailLogin ? 'Login with Email' : 'Create Account'),
          ),
        ),
        if (_isEmailLogin) ...[
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.center,
            child: TextButton(
              onPressed: () => _showForgotPasswordDialog(context, provider),
              child: const Text('Forgot Password?'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPhoneTab() {
    return ListView(
      padding: const EdgeInsets.only(top: 4),
      children: [
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: const Color(0xFFE8F2FF),
                  child: Icon(
                    Icons.sms_outlined,
                    color: Colors.blue[700],
                    size: 30,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Custom OTP Login',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Use the app’s own OTP screen. Your backend sends and verifies the code.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[700]),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PhoneOtpAuthScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.login_outlined),
                    label: const Text('Open OTP Login'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ForgotPasswordDialog extends StatefulWidget {
  final UserAuthProvider provider;

  const _ForgotPasswordDialog({required this.provider});

  @override
  State<_ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<_ForgotPasswordDialog> {
  late TextEditingController _emailController;
  late TextEditingController _otpController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;
  
  int _step = 1; // 1: Email, 2: OTP, 3: Password
  bool _isLoading = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  int _otpResendCountdown = 0;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _otpController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (_emailController.text.trim().isEmpty) {
      _showSnack('Please enter your email address');
      return;
    }

    setState(() => _isLoading = true);

    final success = await widget.provider.sendPasswordResetOtp(
      _emailController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      setState(() {
        _step = 2;
        _isLoading = false;
        _otpResendCountdown = 120; // 2 minutes
      });
      _startResendCountdown();
      _showSnack('OTP sent to your email');
    } else {
      setState(() => _isLoading = false);
      _showSnack(widget.provider.error ?? 'Failed to send OTP');
    }
  }

  Future<void> _resendOtp() async {
    if (_otpResendCountdown > 0) {
      _showSnack('Please wait before resending');
      return;
    }

    setState(() => _isLoading = true);

    final success = await widget.provider.sendPasswordResetOtp(
      _emailController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      setState(() {
        _isLoading = false;
        _otpResendCountdown = 120;
        _otpController.clear();
      });
      _startResendCountdown();
      _showSnack('OTP resent to your email');
    } else {
      setState(() => _isLoading = false);
      _showSnack(widget.provider.error ?? 'Failed to resend OTP');
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

  Future<void> _verifyAndReset() async {
    if (_otpController.text.trim().isEmpty) {
      _showSnack('Please enter the OTP');
      return;
    }

    if (_passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      _showSnack('Please enter your new password');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showSnack('Passwords do not match');
      return;
    }

    setState(() => _isLoading = true);

    final success = await widget.provider.verifyPasswordResetOtp(
      email: _emailController.text.trim(),
      otp: _otpController.text.trim(),
      newPassword: _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      _showSnack('Password reset successfully');
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) Navigator.pop(context);
      });
    } else {
      setState(() => _isLoading = false);
      _showSnack(widget.provider.error ?? 'Failed to reset password');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 3)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_getStepTitle()),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Progress indicator
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: List.generate(3, (index) {
                  final stepNum = index + 1;
                  final isActive = stepNum <= _step;
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: EdgeInsets.only(
                        right: index < 2 ? 8 : 0,
                      ),
                      decoration: BoxDecoration(
                        color: isActive ? Colors.blue : Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),
            // Step 1: Email
            if (_step >= 1)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Enter your email address to receive a password reset code.',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    enabled: _step == 1 && !_isLoading,
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      border: const OutlineInputBorder(),
                      hintText: 'your.email@example.com',
                      suffixIcon: _step > 1
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : null,
                    ),
                  ),
                ],
              ),
            // Step 2: OTP
            if (_step >= 2) ...[
              const SizedBox(height: 16),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Enter the 6-digit code sent to your email.',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    enabled: _step == 2 && !_isLoading,
                    decoration: InputDecoration(
                      labelText: 'OTP Code',
                      border: const OutlineInputBorder(),
                      counterText: '',
                      hintText: '000000',
                      suffixIcon: _step > 2
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : null,
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      letterSpacing: 4,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_otpResendCountdown > 0)
                        Text(
                          'Resend in ${_otpResendCountdown}s',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        )
                      else
                        TextButton(
                          onPressed: _isLoading ? null : _resendOtp,
                          child: const Text('Resend OTP'),
                        ),
                    ],
                  ),
                ],
              ),
            ],
            // Step 3: New Password
            if (_step >= 3) ...[
              const SizedBox(height: 16),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Create a new password for your account.',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    obscureText: !_showPassword,
                    enabled: !_isLoading,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _showPassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(
                              () => _showPassword = !_showPassword);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: !_showConfirmPassword,
                    enabled: !_isLoading,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _showConfirmPassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() =>
                              _showConfirmPassword = !_showConfirmPassword);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading
              ? null
              : () {
                  if (_step > 1) {
                    setState(() => _step--);
                  } else {
                    Navigator.pop(context);
                  }
                },
          child: Text(_step > 1 ? 'Back' : 'Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _getActionCallback(),
          child: _isLoading
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_getActionButtonLabel()),
        ),
      ],
    );
  }

  String _getStepTitle() {
    switch (_step) {
      case 1:
        return 'Reset Password';
      case 2:
        return 'Enter OTP';
      case 3:
        return 'New Password';
      default:
        return 'Reset Password';
    }
  }

  String _getActionButtonLabel() {
    switch (_step) {
      case 1:
        return 'Send OTP';
      case 2:
        return 'Verify OTP';
      case 3:
        return 'Reset Password';
      default:
        return 'Next';
    }
  }

  VoidCallback? _getActionCallback() {
    if (_step == 1) {
      return _sendOtp;
    } else if (_step == 2) {
      return () {
        if (_otpController.text.trim().isNotEmpty) {
          setState(() => _step = 3);
        } else {
          _showSnack('Please enter the OTP');
        }
      };
    } else if (_step == 3) {
      return _verifyAndReset;
    }
    return null;
  }
}
