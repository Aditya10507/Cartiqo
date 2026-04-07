import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'app/app.dart';
import 'models/app_user_session.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ErrorWidget.builder = (details) => Material(
        color: const Color(0xFFF8FAFC),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Card(
              margin: const EdgeInsets.all(24),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Runtime Error',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'The app hit an unexpected UI error while loading. Refresh once, and if it still fails this message will help us diagnose it.',
                    ),
                    const SizedBox(height: 16),
                    SelectableText(details.exceptionAsString()),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exceptionAsString()}');
    debugPrintStack(stackTrace: details.stack);
  };
  PlatformDispatcher.instance.onError = (error, stackTrace) {
    debugPrint('PlatformDispatcher error: $error');
    debugPrintStack(stackTrace: stackTrace);
    return false;
  };

  try {
    final initialSession = await _loadInitialSession();
    runApp(SwiftCartApp(initialUserSession: initialSession));
  } catch (error, stackTrace) {
    debugPrintStack(stackTrace: stackTrace);
    runApp(_StartupErrorApp(error: error));
  }
}

Future<AppUserSession?> _loadInitialSession() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('swiftcart_user_session');
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }

    final map = jsonDecode(raw) as Map<String, dynamic>;
    final token = prefs.getString('swiftcart_user_token');
    return AppUserSession.fromJson(map).copyWith(token: token);
  } catch (_) {
    return null;
  }
}

class _StartupErrorApp extends StatelessWidget {
  final Object error;

  const _StartupErrorApp({required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Card(
              margin: const EdgeInsets.all(24),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Startup Error',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'The web app could not start correctly. Please refresh once, and if it still fails this message will help us diagnose it.',
                    ),
                    const SizedBox(height: 16),
                    SelectableText('$error'),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
