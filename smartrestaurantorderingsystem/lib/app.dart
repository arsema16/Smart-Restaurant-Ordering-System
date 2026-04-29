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
      // If URL path is /staff-login, go directly to staff login
      if (Uri.base.path.contains('staff-login')) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Habesha Bites',
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFE65100),
              primary: const Color(0xFFE65100),
            ),
          ),
          home: const StaffLoginScreen(),
        );
      }
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Habesha Bites',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE65100),
          primary: const Color(0xFFE65100),
          secondary: const Color(0xFF2E7D32),
          surface: const Color(0xFFFFF8F5),
          background: const Color(0xFFFFF8F5),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFE65100),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE65100),
            foregroundColor: Colors.white,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
        chipTheme: ChipThemeData(
          selectedColor: const Color(0xFFE65100),
          backgroundColor: Colors.white,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          side: const BorderSide(color: Color(0xFFE65100)),
        ),
        scaffoldBackgroundColor: const Color(0xFFFFF8F5),
        fontFamily: 'Roboto',
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

          case '/staff-login':
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