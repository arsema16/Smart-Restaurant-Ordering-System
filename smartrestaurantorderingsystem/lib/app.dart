import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/menu/menu_screen.dart';
import 'screens/staff/qr_generator_screen.dart';
import 'screens/welcome/welcome_screen.dart';
import 'screens/test/test_qr_screen.dart';

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Restaurant',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/welcome': (context) => const WelcomeScreen(),
        '/menu': (context) => const MenuScreen(),
        '/staff/qr-generator': (context) => const QRGeneratorScreen(),
        '/test-qr': (context) => const TestQRScreen(),
      },
    );
  }
}