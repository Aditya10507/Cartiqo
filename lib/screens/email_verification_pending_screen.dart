import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/user_auth_provider.dart';
import 'mall_select_screen.dart';
import '../widgets/swiftcart_logo.dart';

class EmailVerificationPendingScreen extends StatelessWidget {
  final String email;

  const EmailVerificationPendingScreen({
    super.key,
    required this.email,
  });

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
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SwiftCartLogo(
                              size: 92,
                              showWordmark: false,
                              primaryColor: Color(0xFFEAF3FF),
                              accentColor: Color(0xFFD8FFF0),
                              backgroundColor: Colors.white,
                            ),
                            const SizedBox(height: 18),
                            const Text(
                              'Verify your email',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'We sent a verification link to your inbox.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              email.isEmpty ? 'Check the email used for signup.' : email,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 22),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF4F7FB),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: const Text(
                                'If you do not see the email, check Spam or Promotions first. After verifying, tap "I verified" below.',
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 18),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: provider.isLoading
                                    ? null
                                    : () async {
                                        final ok =
                                            await provider.resendEmailVerification();
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                provider.error ??
                                                    (ok
                                                        ? 'Verification email sent again.'
                                                        : 'Unable to resend verification email.'),
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                child: provider.isLoading
                                    ? const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text('Resend email'),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: provider.isLoading
                                    ? null
                                    : () async {
                                        final verified =
                                            await provider.refreshCurrentUser();
                                        if (!context.mounted) return;
                                        if (verified) {
                                          Navigator.of(context).pushReplacement(
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  const MallSelectScreen(),
                                            ),
                                          );
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Still not verified. Please check your email and tap the link first.',
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                child: const Text('I verified'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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
