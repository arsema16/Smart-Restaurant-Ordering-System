import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/menu/menu_screen.dart';
import 'screens/cart/cart_screen.dart';
import 'screens/order/order_history_screen.dart';
import 'screens/order/order_tracking_screen.dart';
import 'screens/staff/qr_generator_screen.dart';
import 'screens/staff/staff_login_screen.dart';
import 'screens/staff/staff_dashboard.dart';
import 'screens/welcome/welcome_screen.dart';
import 'screens/test/test_qr_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/session_provider.dart';

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // On web, read the table parameter directly from the browser URL at startup.
    // Flutter's onGenerateRoute does NOT receive the initial query string, so
    // we grab it from Uri.base before the router is even involved.
    String? initialTableId;
    if (kIsWeb) {
      initialTableId = Uri.base.queryParameters['table'];
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Restaurant',
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      // Always start at '/' but pass the table ID we already extracted.
      home: SplashScreen(tableIdentifier: initialTableId),
      onGenerateRoute: (settings) {
        // Extract query parameters from the URL for in-app navigation
        final uri = Uri.parse(settings.name ?? '/');
        final path = uri.path.isEmpty ? '/' : uri.path;
        final queryParams = uri.queryParameters;

        switch (path) {
          case '/':
            final tableId = queryParams['table'] ??
                (settings.arguments as Map<String, dynamic>?)?['table'];
            return MaterialPageRoute(
              builder: (_) => SplashScreen(tableIdentifier: tableId),
            );

          case '/welcome':
            return MaterialPageRoute(
              builder: (_) => const WelcomeScreen(),
            );

          case '/test-qr':
            return MaterialPageRoute(
              builder: (_) => const TestQRScreen(),
            );

          case '/menu':
            return MaterialPageRoute(
              builder: (_) => _SessionGuard(
                child: const MenuScreen(),
                ref: ref,
              ),
            );

          case '/cart':
            return MaterialPageRoute(
              builder: (_) => _SessionGuard(
                child: const CartScreen(),
                ref: ref,
              ),
            );

          case '/orders':
            return MaterialPageRoute(
              builder: (_) => _SessionGuard(
                child: const OrderHistoryScreen(),
                ref: ref,
              ),
            );

          case '/orders/tracking':
            final orderId = settings.arguments as String? ?? '';
            return MaterialPageRoute(
              builder: (_) => _SessionGuard(
                child: OrderTrackingScreen(orderId: orderId),
                ref: ref,
              ),
            );

          case '/staff/login':
            return MaterialPageRoute(
              builder: (_) => const StaffLoginScreen(),
            );

          case '/staff/dashboard':
            return MaterialPageRoute(
              builder: (_) => _AuthGuard(
                child: const StaffDashboard(),
                ref: ref,
              ),
            );

          case '/staff/qr-generator':
            return MaterialPageRoute(
              builder: (_) => const QRGeneratorScreen(),
            );

          default:
            return MaterialPageRoute(
              builder: (_) => const WelcomeScreen(),
            );
        }
      },
    );
  }
}

/// Guard widget that checks for valid session before rendering child
/// Redirects to welcome screen if no session exists
class _SessionGuard extends ConsumerWidget {
  final Widget child;
  final WidgetRef ref;

  const _SessionGuard({
    required this.child,
    required this.ref,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    
    // Check if session exists
    if (session == null) {
      // No session, redirect to welcome
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/welcome');
      });
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    return child;
  }
}

/// Guard widget that checks for valid JWT before rendering child
/// Redirects to staff login if not authenticated
class _AuthGuard extends ConsumerWidget {
  final Widget child;
  final WidgetRef ref;

  const _AuthGuard({
    required this.child,
    required this.ref,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    
    // Check if authenticated
    if (!authState.isAuthenticated) {
      // Not authenticated, redirect to login
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/staff/login');
      });
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    return child;
  }
}