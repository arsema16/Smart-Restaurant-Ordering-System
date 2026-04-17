import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/session_provider.dart';
import '../qr/qr_scanner_screen.dart';
import '../menu/menu_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {

  @override
  void initState() {
    super.initState();

    Future.microtask(() => checkSession());
  }

  void checkSession() {
    final sessionState = ref.read(sessionProvider);

    sessionState.when(
      data: (session) {
        if (session != null) {
          // Session exists → go to Menu
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MenuScreen()),
          );
        } else {
          // No session → go to QR
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const QRScannerScreen()),
          );
        }
      },
      loading: () {
        // still loading → do nothing
      },
      error: (e, _) {
        // fallback → QR screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const QRScannerScreen()),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(sessionProvider);

    return Scaffold(
      body: Center(
        child: sessionState.when(
          data: (_) => const Text("Redirecting..."),
          loading: () => const CircularProgressIndicator(),
          error: (e, _) => Text("Error: $e"),
        ),
      ),
    );
  }
}