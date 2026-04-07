import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_user_session.dart';
import '../providers/admin_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/mall_manager_provider.dart';
import '../providers/user_auth_provider.dart';
import '../screens/web_portal_home_screen_stub.dart'
    if (dart.library.html) '../screens/web_portal_home_screen.dart';

class SwiftCartApp extends StatelessWidget {
  final AppUserSession? initialUserSession;

  const SwiftCartApp({super.key, this.initialUserSession});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(create: (_) => MallManagerProvider()),
        ChangeNotifierProvider(
          create: (_) => UserAuthProvider(
            initialSession: initialUserSession,
            isReady: true,
          ),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Cartiqo',
        theme: ThemeData(useMaterial3: true),
        home: const AppModeSelector(),
      ),
    );
  }
}

class AppModeSelector extends StatelessWidget {
  const AppModeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return const WebPortalHomeScreen();
  }
}
